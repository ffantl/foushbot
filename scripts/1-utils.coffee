# Description:
#   Quick
#
redis = require "redis"
URL = require "url"

module.exports = (robot) ->
# determines the channel for the incoming webhook
    robot.iwhChannel = (data) ->
        channel = "##{data.channel_name}"
        if (data.channel_name == "directmessage")
            channel = "@#{data.user_name}"
        else if (data.channel_name == "privategroup")
            lookup = robot.adapter.client.getChannelGroupOrDMByID data.channel_id
            channel = "##{lookup.name}"
        return channel
    redisClient = null
    robot.getRedis = () ->
        unless (redisClient)
            if process.env.REDISTOGO_URL
              rtg   = URL.parse(process.env.REDISTOGO_URL);
              redisClient = redis.createClient(rtg.port, rtg.hostname);
              redisClient.auth(rtg.auth.split(":")[1]);
            else
              redisClient = redis.createClient()
        return redisClient
