
module.exports = (robot) ->
  robot.foush.methods.registerIntegration 'List', "Lists all available foush integrations.", 'list', (itg, message, data, req, res) ->
    integrations = robot.foush.methods.getIntegrations()
    integrationList = []
    for slug, integration of integrations
      integrationList.push "*/foush #{integration.slug}* #{integration.description}"
    res.status(200).send(integrationList.join "\n")

  robot.foush.methods.registerIntegration 'Karma', '(top|bottom) - Displays the room karma', 'karma', robot.foush.methods.defaultIntegrationCallback (itg, message, data, req, res, callback) ->
    karmify = (ranks) ->
      console.log ranks, 'ranks'
      result = []
      for i, rank in ranks
        result.push "*#{rank.thing}*: #{rank.karma}"
      return result.join('\n');
    robot.foush.methods.getKarmaForRoom data.channel_name, (rankings) ->
      bottomMatch = /bottom/
      if bottomMatch.test message
        callback "*BOTTOM KARMA*\n"+(karmify rankings.lowest.reverse())
      callback "*TOP KARMA*\n"+(karmify rankings.highest)
  , username: "FoushJudgement", icon_url: "http://i.imgur.com/gJ3xpj5.png"