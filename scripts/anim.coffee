# Description:
#   Shortcut implementation for /anim
#


module.exports = (robot) ->
    robot.router.post '/integrations/anim' (req, res) ->
        console.log "============== REQ BODY =============", req.body