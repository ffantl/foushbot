# Description:
#   Shortcut implementation for /anim
#
module.exports = (robot) ->
    robot.router.post '/integrations/urban', (req, res) ->
        data = req.body
        if data.token != process.env.INTEGRATION_URBAN_TOKEN
            return res.status(500).send 'Invalid access token'
        # imageSearch data.channel_id, data.user_name, data.text, false
        q = term: data.text
        robot.http('https://mashape-community-urban-dictionary.p.mashape.com/define')
        .header('X-Mashape-Key', process.env.MASHAPE_URBAN_KEY)
        .query(q)
        .get() (err, response, body) ->
            results = JSON.parse(body)
            # once we have the data
            console.log "UD API Results!", body, results
            if results and results.list and results.list.length
                sendDefinition results.list[0], data.channel_name
        res.status(200).send ''
    sendDefinition = (result, channelName) ->
        formatted = "*#{result.word}*\n*Definition:* #{result.definition}\n_Example: #{result.example}_\n<#{result.permalink}|View on site>"
        data = channel: "##{channelName}", text: formatted
        console.log "sending result", data
        robot.http('https://hooks.slack.com/services/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')
        .post(data) (err, response, body) ->
            console.log 'done'
