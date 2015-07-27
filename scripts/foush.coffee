
module.exports = (robot) ->
  robot.foush.methods.registerIntegration 'List', "Lists all available foush integrations.", 'list', (message, data, req, res) ->
    integrations = robot.foush.methods.getIntegrations()
    integrationList = []
    for slug, integration of integrations
      integrationList.push "*/foush #{integration.slug}* #{integration.description}"
    res.status(200).send(integrationList.join "\n")
