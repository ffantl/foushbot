# Description:
#   Hubot trigger to suggest a nearby movie
# Commands:
#   hubot movie me <zip> - displays movies playing near <zip>
queryString = require 'query-string'
moment = require 'moment'

module.exports = (robot) ->
    client = robot.getRedis()
#    robot.router.post '/integrations/movie', (req, res) ->
#        data = req.body
#        if data.token != process.env.INTEGRATION_MOVIE_TOKEN
#            return res.status(500).send 'Invalid access token'
#        # imageSearch data.channel_id, data.user_name, data.text, false
#        channel = robot.iwhChannel data
#        q = term: data.text
#        robot.http('https://mashape-community-urban-dictionary.p.mashape.com/define')
#        .header('X-Mashape-Key', process.env.MASHAPE_URBAN_KEY)
#        .query(q)
#        .get() (err, response, body) ->
#            results = JSON.parse(body)
#            # once we have the data
#            if results and results.list and results.list.length
#                res.status(200).send ''
#                sendDefinition results.list[0], results.tags or [], channel, data.user_name
#            else
#              res.status(200).send "Unable to find results"
#
#
#    sendDefinition = (result, tags, channelName, username) ->
#        joinedTags = (tags.join ', ').replace /\+/g, ' '
#        tagText = if tags.length then "\nTags: _ #{joinedTags} _" else '';
#        data = channel: channelName, text: "*#{result.word}*: #{result.definition}\n```#{result.example}```#{tagText}\nHT #{username} <#{result.permalink}|View on site>"
#        robot.http(process.env.IWH_URBAN_URL)
#        .post(JSON.stringify(data)) (err, response, body) ->
#            return true
    suggestMovie = (movie, channelName, username) ->
        showtimes = []

        showings = {}

        for showtime in movie.showtimes
            showings[showtime.theatre.id] ?= {name: showtime.theatre.name, dates: {}}
            m = moment(showtime.dateTime)
            d = m.format("MM/DD/YYYY")
            showings[showtime.theatre.id]['dates'][d] ?= []
            showings[showtime.theatre.id]['dates'][d].push m.format("h:mm a")
        messageParts = ["*#{movie.title}*"]
        if movie.longDescription
            messageParts.push "```#{movie.longDescription}```"
        for theaterId, theater of showings
            messageParts.push "*#{theater.name}*"
            for showDate, showTimes of theater['dates']
                messageParts.push "_#{showDate}_"
                for time in showTimes
                    messageParts.push "> #{time}"

        message = (messageParts.join "\n")
        data = channel: channelName, text: message
        robot.http(process.env.IWH_SOCIAL_URL)
        .post(JSON.stringify(data)) (err, response, body) ->
            return true

    prefixKey = (key) ->
        return "movies-#{key}"
    getFormattedDate = () ->
        return ((new Date).toISOString()).replace(/T.+/, '')
    getMovieSuggestion = (zip, callback) ->
        zip ?= process.env.DEFAULT_ZIP
        # calculate the date
        date = getFormattedDate()
        key = prefixKey "#{date}-#{zip}"
        client.get key, (err, reply) ->
            if reply
                try
                    value = JSON.parse reply
                    if value && value.movies && value.movies.length
                        # get a random movie entry from the array
                        return selectMovie key, value, callback
                catch err
                    console.log "no!", err
            # query the api
            requestMovieSuggestions date, zip, key, callback
    apiQueryLimiter = {}
    requestMovieSuggestions = (date, zip, key, callback) ->
        apiQueryLimiter[key] ?= inProgress: false, queue: []
        if apiQueryLimiter[key].inProgress
            return apiQueryQueue[key].queue.push callback
        apiQueryLimiter[key].inProgress = true
        params = startDate: date, zip: zip, api_key: process.env.MOVIE_API_KEY
        robot.http("http://data.tmsapi.com/v1.1/movies/showings?"+queryString.stringify(params)).get() (err, response, body) ->
            if err
                apiQueryLimiter[key].inProgress = false
                return callback null
            try
                data = JSON.parse body
                # format data and save to redis
                selectMovie key, movies: data, (movie) ->
                    callback movie
                    apiQueryLimiter[key].inProgress = false
                    for cb in apiQueryQueue[key].queue
                        do (cb) ->
                            cb movie
                    apiQueryLimiter[key].queue = []
            catch e
                apiQueryLimiter[key].inProgress = false
                return callback null
    selectMovie = (key, data, callback) ->
        index = Math.floor(Math.random()*data.movies.length)
        movie = data.movies[index]
        data.movies.splice(index, 1)
        # save the updated data set
        client.set key, JSON.stringify data
        callback movie

    robot.respond /movie( me)?(.*)/, (msg) ->
        zip = null
        if msg.match[2].length
            regex = /(^|\W)(\d{5})(\W|$)/
            if regex.test msg.match[2]
                matches = msg.match[2].match regex
                zip = matches[2]
        getMovieSuggestion zip, (movie) ->
            if (movie)
                suggestMovie movie, msg.message.room, msg.message.user.name
