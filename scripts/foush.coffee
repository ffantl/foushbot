
module.exports = (robot) ->
  robot.foush.methods.registerIntegration 'List', "Lists all available foush integrations.", 'list', (itg, message, data, req, res) ->
    integrations = robot.foush.methods.getIntegrations()
    integrationList = []
    for slug, integration of integrations
      integrationList.push "*/foush #{integration.slug}* #{integration.description}"
    res.status(200).send(integrationList.join "\n")

  robot.foush.methods.registerIntegration 'Karma', '(top|bottom) - Displays the room karma', 'karma', (robot.foush.methods.defaultIntegrationCallback (itg, message, data, req, res, callback) ->
    karmify = (ranks) ->
      if ranks.length < 1
        return "_No rankings to display_"
      result = []
      for rank in ranks
        result.push "*#{rank.thing}*: #{rank.karma}"
      return result.join('\n');
    robot.foush.methods.getKarmaForRoom (robot.foush.methods.iwhChannel data).slice(1), (rankings) ->
      bottomMatch = /(bottom|evil|low|worst)/
      if bottomMatch.test message
        return callback "*MOST EVIL*\n"+(karmify rankings.lowest)
      callback "*MOST GOOD*\n"+(karmify rankings.highest)
  ), username: "FoushJudgement", icon_url: "http://i.imgur.com/gJ3xpj5.png"