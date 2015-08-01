# Description:
#   Shortcut implementation for /anim
#
module.exports = (robot) ->
    robot.router.post '/integrations/img', (req, res) ->
        data = req.body
        if data.token != process.env.INTEGRATION_IMG_TOKEN
            return res.status(500).send 'Invalid access token'
        imageSearch data.channel_id, data.user_name, data.text, false
        res.status(200).send ''
    robot.router.post '/integrations/anim', (req, res) ->
        data = req.body
        if data.token != process.env.INTEGRATION_ANIM_TOKEN
            return res.status(500).send 'Invalid access token'
        imageSearch data.channel_id, data.user_name, data.text, true
        res.status(200).send ''

    imageSearch = (channelId, userName, query, animated) ->
        lookup = robot.adapter.client.getChannelGroupOrDMByID channelId
        q = v: '1.0', rsz: '8', q: query, safe: 'active'
        q.imgtype = 'animated' if animated is true
        robot.http('http://ajax.googleapis.com/ajax/services/search/images')
        .query(q)
        .get() (err, response, body) ->
            if err
              console.log "Google API Error!", err, response, body
            images = JSON.parse(body)
            images = images.responseData?.results
            reply = "_got nothin for \"#{query}\", sorry #{userName}_"
            if images?.length > 0
                image = images[Math.floor(Math.random()*images.length)]
                reply = "#{userName} result for *\"#{query}\"*\n" + ensureImageExtension image.unescapedUrl
#            robot.messageRoom lookup.name, reply
            robot.foush.methods.incomingWebHook lookup.name, reply, (username: "GIFoush", icon_url: "http://i.imgur.com/X4V4qiX.gif")


    ensureImageExtension = (url) ->
        ext = url.split('.').pop()
        if /(png|jpe?g|gif)/i.test(ext)
            url
        else
            "#{url}#.png"