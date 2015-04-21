# Description:
#   Shortcut implementation for /anim
#
module.exports = (robot) ->
    robot.router.post '/integrations/img', (req, res) ->
        data = req.body
        if data.token != process.env.INTEGRATION_IMG_TOKEN
            return res.status(500).send 'Invalid access token'
        imageSearch data.channel_id, data.text, false
        res.status(200).send ''
    robot.router.post '/integrations/anim', (req, res) ->
        data = req.body
        if data.token != process.env.INTEGRATION_ANIM_TOKEN
            return res.status(500).send 'Invalid access token'
        imageSearch data.channel_id, data.text, true
        res.status(200).send ''

    imageSearch = (channelId, query, animated) ->
        lookup = robot.adapter.client.getChannelGroupOrDMByID channelId
        q = v: '1.0', rsz: '8', q: query, safe: 'active', animated: animated
        robot.http('http://ajax.googleapis.com/ajax/services/search/images')
        .query(q)
        .get() (err, response, body) ->
            images = JSON.parse(body)
            images = images.responseData?.results
            reply = '/me got nothin'
            if images?.length > 0
                image = images[Math.floor(Math.random()*images.length)]
                reply = ensureImageExtension image.unescapedUrl
            robot.messageRoom lookup.name, reply


    ensureImageExtension = (url) ->
        ext = url.split('.').pop()
        if /(png|jpe?g|gif)/i.test(ext)
            url
        else
            "#{url}#.png"