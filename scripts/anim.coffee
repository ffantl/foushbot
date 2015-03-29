# Description:
#   Reacts to /anim
#

querystring = require("querystring");

module.exports = (robot) ->

  queryGoogle = (q, type, resultCallback) ->
    query = querystring.stringify(
      v: "1.0"
      q: q
      as_filetype: type
    )
    robot.http("https://ajax.googleapis.com/ajax/services/search/images?#{query}").get() (err, res, body) ->
      result = null
      if !err && body
        try
          data = JSON.parse(body)
          if data && data.responseData && data.responseData.results
            result = (msg.random data.responseData.results).unescapedUrl
        catch
          err = "Failed to parse body"
      resultCallback result, err

  parseSlackRequest = (req, validToken) ->
    data = if req.body then req.body.split(/\s+/) else null
    if data && data.length && data[0] == "token=#{validToken}"
      params = {}
      ((value) ->
        pieces = value.split('=')
        if pieces.length > 0
          params[pieces[0]] = params[pieces[1]]
      ) pair for pair in data
      return params
    return null


  robot.router.post '/hubot/slash/anim', (req, res) ->
    res.send JSON.stringify(req.body)
    return
#    params = parseSlackRequest(req, 'Nbe56XeexradTV1cIKB2a4Q2')
#    if params
#      # params now hydrated
#      callback = (result, err) ->
#        url = result
#        robot.http("https://hooks.slack.com/services/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").post(JSON.stringify(
#          text: "<#{url}> from data #{req.body} (decoded into: "+JSON.stringify(params)+")"
#          channel: params.channel_name
#        )) (err, res, body) ->
#            console.log "done"
#            return
#      queryGoogle(params.text, 'gif', callback)
#    res.send ''

  robot.router.post '/hubot/slash/img', (req, res) ->
    params = parseSlackRequest(req, 'Nbe56XeexradTV1cIKB2a4Q2')
    if params
      # params now hydrated
      callback = (result, err) ->
        url = result
        robot.http("https://hooks.slack.com/services/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").post(JSON.stringify(
          text: "<#{url}> from data #{req.body} (decoded into: "+JSON.stringify(params)+")"
          channel: params.channel_name
        )) (err, res, body) ->
          console.log "done"
          return
      queryGoogle(params.text, '', callback)
    res.send ''


