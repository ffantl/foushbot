# Description: yelp suggestions for lunch

request = require 'request'
OAuth   = require 'oauth-1.0a'
queryString = require 'query-string'

module.exports = (robot) ->
  client = robot.getRedis()
  yelpResultLimt = 20
  oauth = OAuth(
    consumer:
      public: process.env.YELP_OA_CONSUMER_PUBLIC,
      secret: process.env.YELP_OA_CONSUMER_PRIVATE
    ,
    signature_method: process.env.YELP_OA_HASH
  );
  token = public: process.env.YELP_TOKEN_PUBLIC, secret: process.env.YELP_TOKEN_PRIVATE
  requests = {}
  prefixKey = (key) ->
    return "lunch"+(if key then key.trim().toLowerCase() else '')
  requestSuggestions = (term, offset, callbackFn) ->
#    console.log "requesting for #{term} with offset #{offset}"
    if isNaN offset
      offset = 0
    request_data = url: 'http://api.yelp.com/v2/search',
    method: 'GET',
    data:
      location: 'Morrisville, NC',
      category_filter: 'restaurants',
      limit: yelpResultLimt,
      offset: offset,
      sort: 2
    if term
      request_data.data.term = term;
    console.log "making request", request_data
    request(url: request_data.url+"?"+queryString.stringify(request_data.data), method: request_data.method, form: request_data.data, headers: oauth.toHeader(oauth.authorize(request_data, token)), (error, response, body) ->
      callbackFn body, offset, term
    )
  requestThenStore = (term, offset, callbackFn) ->
    if requests[term] && requests[term].inProgress
      requests[term].queue.push(callbackFn)
      return
    requests[term] = inProgress: true, queue: []
    requestSuggestions term, offset, (body, o, t) ->
      requests[term].inProgress = false;
      console.log body
      response = JSON.parse body
#      console.log "response! Total matches:", response.total, "Results returned: ", response.businesses.length
      value = JSON.stringify offset: o, results: response.businesses, term: t
      client.set (prefixKey t), value
      callbackFn value, response
      # purge queue
      for cb in requests[term].queue
        do (cb) ->
          cb value, response
      delete requests[term].queue
      requests[term].queue = []


  handleSuggestions = (msg, term, data) ->
    entry = JSON.parse data
    unless entry.results.length
      msg.send "Got nothing for #{term}"
      return
    console.log "have results for #{term}"
    index = Math.floor(Math.random()*entry.results.length)
    business = entry.results[index]
    entry.results.splice(index, 1)
    msg.send "*#{business.name}*\n"+business.location.display_address.join("\n")+"\n#{business.url}"
    if entry.results.length < 1
      requestThenStore term, entry.offset - -yelpResultLimt, (value, response) ->
        if response.businesses.length < 1
          client.del (prefixKey term)
        return
      return
    client.set (prefixKey term), JSON.stringify entry


  respondToLunch = (msg, term) ->
    client.get (prefixKey term), (err, reply) ->
      if reply
        value = JSON.parse reply
        unless value.results && value.results.length
          client.del (prefixKey term)
          respondToLunch msg, term
          return
        handleSuggestions msg, term, reply
        return
      else
        requestThenStore term, 0, (value, response) ->
          if response.businesses.length < 1
            client.del (prefixKey term)
            msg.send "Unable to find results for #{term}"
            return
          handleSuggestions msg, term, value
          return

  robot.hear /(^|\W)(lounc|lunch)(\s+\w+|$)/i, (msg) ->
    unless msg.match[3].trim().toLowerCase() == 'me'
      console.log msg.match
      respondToLunch msg, ''
  robot.respond /(lounc|lunch)\s+me(\s+.+|$)/i, (msg) ->
    console.log msg.match
    respondToLunch msg, msg.match[2].trim().toLowerCase()