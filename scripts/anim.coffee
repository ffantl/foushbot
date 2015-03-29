# Description:
#   Reacts to /anim
#

querystring = require("querystring");

module.exports = (robot) ->

  imageSearch = (msg, q, type) ->
    query = querystring.stringify(
      v: "1.0"
      q: q
      as_filetype: type
    )
    robot.http("https://ajax.googleapis.com/ajax/services/search/images?#{query}").get() (err, res, body) ->
      if !err && body
        try
          data = JSON.parse(body)
          if data && data.responseData && data.responseData.results
            result = msg.random data.responseData.results
            msg.send "#{result.unescapedUrl}"
          else
            msg.send "Unable to find results for #{q}"
          return
        catch
          err = "Failed to parse JSON"
        msg.send "Encountered an error :( #{err}"
        return

  robot.router.post '/hubot/slash/anim', (req, res) ->
    # check Nbe56XeexradTV1cIKB2a4Q2
    data = if req.body.payload then JSON.parse req.body.payload else req.body
    query = ''

    url = "http://google.com"

    robot.http("https://hooks.slack.com/services/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").post(JSON.stringify({
        text: "<#{url}> FROM "+JSON.stringify(data)
        #channel: ""
      }) (err, res, body) ->
      # done
      console.log "Done", err, res
    console.log data
    res.send ''

  robot.hear /^\/anim (.+)$/, (msg) ->
    imageSearch(msg, msg.match[1], 'gif')
  robot.hear /^\/img (.+)$/, (msg) ->
    imageSearch(msg, msg.match[1], '')
