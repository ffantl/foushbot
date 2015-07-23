# Description:
#   Shortcut implementation for /anim
#
module.exports = (robot) ->
  robot.router.post '/integrations/jammy', (req, res) ->
    data = req.body
    if data.token != process.env.INTEGRATION_JAMMY_TOKEN
      return res.status(500).send 'Invalid access token'
    lookup = robot.adapter.client.getChannelGroupOrDMByID data.channel_id
    data = channel: "##{lookup.name}", text: "http://i.imgur.com/6mw3MOL.gif"
    robot.http(process.env.IWH_JAMMY_URL)
    .post(JSON.stringify(data)) (err, response, body) ->
      return true
