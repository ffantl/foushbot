# Description:
#   Shortcut implementation for /anim
#
module.exports = (robot) ->
    robot.router.post '/integrations/anim', (req, res) ->
        data = req.body
        if data.token != process.env.INTEGRATION_ANIM_TOKEN
            return res.status(500).send 'Invalid access token'
        room = data.channel_id
        console.log "sending message to #{room}"
        q = v: '1.0', rsz: '8', q: data.text, safe: 'active', animated: true
        robot.http('http://ajax.googleapis.com/ajax/services/search/images')
        .query(q)
        .get() (err, response, body) ->
            images = JSON.parse(body)
            images = images.responseData?.results
            reply = '/me got nothin'
            if images?.length > 0
                image = images[Math.floor(Math.random()*images.length)]
                reply = ensureImageExtension image.unescapedUrl
            robot.messageRoom room, reply
        res.status(200).send ''
    ensureImageExtension = (url) ->
        ext = url.split('.').pop()
        if /(png|jpe?g|gif)/i.test(ext)
            url
        else
            "#{url}#.png"