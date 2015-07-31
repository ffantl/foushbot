# Description:
#   Tracks karma per room
#

module.exports = (robot) ->

  robot.foush.methods.getKarmaForRoom = (room, callback) ->
    mapKey = "karma-rank#{room}"
    rankings = robot.brain.get(mapKey)
    if rankings
      return callback rankings
    totals = []
    console.log "getting karma for #{room}"
    karmaMap = robot.brain.get("karma#{room}") or {}
    for key, map of karmaMap
      for thing, karma of karmaMap
        totals.push thing: thing, karma: karma * 1
    totals.sort (a,b) ->
      return b.karma - a.karma
    rankings = lowest: (totals.slice 0,10), highest: totals.slice(if totals.length < 10 then 0 else totals.length - 10)
    robot.brain.set mapKey, rankings
    return callback rankings

  computeKarma = (thing, modifier, msg) ->
    thing = thing.trim()
    if !thing
      return
    mapKey = "karma#{msg.message.room}"
    console.log "Karma being updated for #{mapKey}"
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

  robot.hear /^@?(\w+):?\s*([\+|\-]{2,})/, (msg) ->
    computeKarma(msg.match[1], msg.match[2], msg)

  robot.hear /^((['|"])(.+)\2)([\+|\-]{2,})/, (msg) ->
    computeKarma(msg.match[3], msg.match[4], msg)
  robot.hear /^(([“])(.+)[”])([\+|\-]+)/, (msg) ->
    computeKarma(msg.match[3], msg.match[4], msg)
  robot.hear /^(([‘])(.+)[’])([\+|\-]+)/, (msg) ->
    computeKarma(msg.match[3], msg.match[4], msg)
