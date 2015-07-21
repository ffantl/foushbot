# Description:
#   Shortcut implementation for /anim
#
module.exports = (robot) ->
    robot.router.post '/integrations/urban', (req, res) ->
        data = req.body
        if data.token != process.env.INTEGRATION_URBAN_TOKEN
            return res.status(500).send 'Invalid access token'
        # imageSearch data.channel_id, data.user_name, data.text, false
        lookup = robot.adapter.client.getChannelGroupOrDMByID data.channel_id
        q = term: data.text
        robot.http('https://mashape-community-urban-dictionary.p.mashape.com/define')
        .header('X-Mashape-Key', process.env.MASHAPE_URBAN_KEY)
        .query(q)
        .get() (err, response, body) ->
            results = JSON.parse(body)
            # once we have the data
#            console.log "UD API Results!", body, results
            if results and results.list and results.list.length
                res.status(200).send ''
                sendDefinition results.list[0], results.tags or [], lookup.name, data.user_name
            else
              res.status(200).send "Unable to find results"


    sendDefinition = (result, tags, channelName, username) ->
        joinedTags = (tags.join ', ').replace /\+/g, ' '
        tagText = if tags.length then "\nTags: _ #{joinedTags} _" else '';
        data = channel: "##{channelName}", text: "*#{result.word}*: #{result.definition}\n```#{result.example}```#{tagText}\nHT #{username} <#{result.permalink}|View on site>"
        robot.http(process.env.URBAN_INT_URL)
        .post(JSON.stringify(data)) (err, response, body) ->
            return true