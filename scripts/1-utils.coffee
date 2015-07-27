# Description:
#   Quick
#
redis = require "redis"
URL = require "url"

module.exports = (robot) ->
    robot.foush ?= methods: {}
    # determines the channel for the incoming webhook
    robot.foush.methods.iwhChannel = (data) ->
        channel = "##{data.channel_name}"
        if (data.channel_name == "directmessage")
            channel = "@#{data.user_name}"
        else if (data.channel_name == "privategroup")
            lookup = robot.adapter.client.getChannelGroupOrDMByID data.channel_id
            channel = "##{lookup.name}"
        return channel
    redisClient = null
    robot.foush.methods.getRedis = () ->
        unless (redisClient)
            if process.env.REDISTOGO_URL
              rtg   = URL.parse(process.env.REDISTOGO_URL);
              redisClient = redis.createClient(rtg.port, rtg.hostname);
              redisClient.auth(rtg.auth.split(":")[1]);
            else
              redisClient = redis.createClient()
        return redisClient
    foushIntegrations = {}
    robot.foush.methods.getIntegrations = () ->
      key = arguments[0] || null
      return if key then foushIntegrations[key] else foushIntegrations
    robot.foush.methods.registerIntegration = (name, description, slug, callback) ->
      if !name
        return console.error "Integration name is required"
      if foushIntegrations[name]
        return console.error "#{name} is already registered"
      foushIntegrations[name] = name: name, description: description, slug: slug, callback: callback
      robot.router.post '/integrations/'+slug.toLowerCase(), (req, res) ->
        data = req.body
        if data.token != process.env['INTEGRATION_'+slug.toUpperCase()+'_TOKEN']
          return res.status(500).send 'Invalid access token'
        callback(data, req, res)
    robot.foush.methods.incomingWebHook = (channelName, message) ->
      data = channel: channelName, text: message
      robot.http(process.env.IWH_SOCIAL_URL)
      .post(JSON.stringify(data)) (err, response, body) ->
          return true
