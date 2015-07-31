
module.exports = (robot) ->
  robot.foush.methods.registerIntegration 'List', "Lists all available foush integrations.", 'list', (itg, message, data, req, res) ->
    integrations = robot.foush.methods.getIntegrations()
    integrationList = []
    for slug, integration of integrations
      integrationList.push "*/foush #{integration.slug}* #{integration.description}"
    res.status(200).send(integrationList.join "\n")

  robot.foush.methods.registerIntegration 'Karma', 'Displays the room karma', 'karma', robot.foush.methods.defaultIntegrationCallback (itg, message, data, req, res, callback) ->
    robot.foush.methods.getKarmaForRoom data.channel_name, (rankings) ->
      console.log "got rankings", rankings
      callback "oh man"
  , username: "FoushJudgement", icon_url: "http://i.imgur.com/gJ3xpj5.png"