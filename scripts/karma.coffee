# Description:
#   Tracks karma per room
#

module.exports = (robot) ->

  computeKarma = (thing, modifier, msg) ->
    thing = thing.trim()
    if !thing
      return
    mapKey = "karma#{msg.message.room}"
    karmaMap = robot.brain.get(mapKey) or {}
    # is this a thing or a user?
    karmaType = robot.brain.userForName(thing) && 'user' || 'thing';
    karmaTypeMap = karmaMap[karmaType] or {}

    entry = karmaTypeMap[thing] * 1 or 0
    difference = Math.min(modifier.length - 1, 5)
    if modifier[0] == '+'
      entry += difference
    else
      entry -= difference
    if entry == 0
      delete karmaTypeMap[thing];
    else
      karmaTypeMap[thing] = entry;
    karmaMap[karmaType] = karmaTypeMap
    robot.brain.set mapKey, karmaMap
    msg.send (karmaType == 'user' && 'User ' || '') + "#{thing}'s karma has " + (modifier[0] == '+' && 'increased' || 'decreased') + " to #{entry}" + (modifier.length - 1 > 5 && ' (limited by BuzzKill™ mode)' || '')
    true

  robot.hear /^@?(\w+)([\+|\-]+)$/, (msg) ->
    computeKarma(msg.match[1], msg.match[2], msg)

  robot.hear /^((['|"])(.+)\2)([\+|\-]+)$/, (msg) ->
    computeKarma(msg.match[3], msg.match[4], msg)
