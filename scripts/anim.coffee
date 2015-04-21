# Description:
#   Shortcut implementation for /anim
#
module.exports = (robot) ->
    robot.router.post '/integrations/anim', (req, res) ->
        data = req.body
        console.log 'request to integrations!', process.env.INTEGRATION_ANIM_TOKEN, data
        if data.token != process.env.INTEGRATION_ANIM_TOKEN
            return res.status(500).send 'Invalid access token'
        room = data.channel_name
        q = v: '1.0', rsz: '8', q: data.text, safe: 'active', animated: true
        robot.http('http://ajax.googleapis.com/ajax/services/search/images')
        .query(q)
        .get() (err, response, body) ->
            images = JSON.parse(body)
            images = images.responseData?.results
            if images?.length > 0
                image = images[Math.floor(Math.random()*images.length)]
                robot.send {room: room}, ensureImageExtension image.unescapedUrl
            else
                robot.send {room: room}, "/me got nothin"
        res.status(200).send ''
    ensureImageExtension = (url) ->
        ext = url.split('.').pop()
        if /(png|jpe?g|gif)/i.test(ext)
            url
        else
            "#{url}#.png"