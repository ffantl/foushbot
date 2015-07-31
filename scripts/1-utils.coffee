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
    robot.foush.methods.registerIntegration = (name, description, slug, callback, options = {}) ->
      slug = slug.toLowerCase()
      if !name
        return console.error "Integration name is required"
      if foushIntegrations[slug]
        return console.error "#{name} is already registered"
      foushIntegrations[slug] = name: name, description: description, slug: slug, callback: callback, options: options
      console.log "registered integration #{slug}", foushIntegrations[slug]

    # Method that abstracts boilerplate integration behavior
    #   accepts a handler which gets the integration, message, data, req, res parameters
    #   from typical execution, but this can simply return a string or an object with
    #     channel and message properties
    #
    robot.foush.methods.defaultIntegrationCallback = (handler) ->
      return (itg, message, data, req, res) ->
        handler itg, message, data, req, res, (result) ->
          res.status(200).send ''
          channelName = null
          if typeof result is 'string'
            message = result
          else
            channelName = result.channel
            message = result.message
          if !channelName
            channelName = robot.foush.methods.iwhChannel data
          robot.foush.methods.incomingWebHook channelName, message, itg.options
    robot.foush.methods.incomingWebHook = (channelName, message, data = {}) ->
      data.channel = channelName
      data.text = message
      robot.http(process.env.IWH_SOCIAL_URL)
      .post(JSON.stringify(data)) (err, response, body) ->
          return true

    # generic router to handle /foush X requests
    robot.router.post '/integrations/foush', (req, res) ->
      data = req.body
      if data.token != process.env['INTEGRATION_FOUSH_TOKEN']
        return res.status(500).send 'Invalid access token'
      # using data, look at the first part of the message
      regex = /^\s*(\w+)/
      action = "list"
      data.text = data.text or ''
      if regex.test data.text
        matches = data.text.match regex
        action = matches[1]
      integration = robot.foush.methods.getIntegrations action.toLowerCase()
      unless integration
        return res.status(200).send "Invalid feature #{action}. Use 'list' to list all options."
      integration.callback integration, (data.text.replace regex, '').trim(), data, req, res
