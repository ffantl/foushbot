# Description:
#   Hubot trigger to suggest a nearby movie
# Commands:
#   hubot movie me <zip> - displays movies playing near <zip>
queryString = require 'query-string'
moment = require 'moment'

module.exports = (robot) ->
    client = robot.foush.methods.getRedis()
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
                messageParts.push "> " + (showTimes.join ", ")

        message = (messageParts.join "\n")
        robot.foush.methods.incomingWebHook channelName, message, (username: "Movies", icon_url: "http://i.imgur.com/Wvr1LAGs.gif")

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
    getZipFromMessage = (message) ->
        zip = null
        if message.length
            regex = /(^|\W)(\d{5})(\W|$)/
            if regex.test message
                matches = message.match regex
                zip = matches[2]
        return zip
    robot.respond /movie( me)?(.*)/, (msg) ->
        zip = getZipFromMessage msg.match[2]
        getMovieSuggestion zip, (movie) ->
            if (movie)
                suggestMovie movie, msg.message.room, msg.message.user.name
    robot.foush.methods.registerIntegration 'movies', "[zipcode] (optional) Get a random movie playing in the area.", 'movies', (itg, message, data, req, res) ->
      getMovieSuggestion (getZipFromMessage message), (movie) ->
          if (movie)
              suggestMovie movie, (robot.foush.methods.iwhChannel data), data.user_name
