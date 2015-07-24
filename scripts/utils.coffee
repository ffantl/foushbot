# Description:
#   Quick
#
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