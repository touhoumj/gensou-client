local gensou = require("gensou")
local websocket = require("gensou.websocket")
local gensou_config = require("gensou_config")

WSCLIENT = nil

local function noop(event)
    return
end

local function dispatch_player_changed(event)
    local state = event.data.state
    if state == "disconnected" then
        handle_player_disconnected(event)
    elseif state == "loading" or state == "loaded" then
        handle_loading_state(event)
    else
        handle_player_changed(event)
    end
end

local action_handlers = {
    auth = noop,
    join_lobby = handle_join_lobby,
    leave_lobby = noop,
    create_room = handle_create_room,
    join_room = handle_join_room,
    leave_room = handle_leave_room,
    add_cpu = handle_add_cpu,
    add_game_event = noop,
    update_readiness = noop,
    update_loading_state = handle_update_loading_state
}

local broadcast_handlers = {
    motd = handle_motd,
    lobby_changed = handle_lobby_changed,
    player_joined = handle_player_joined,
    player_changed = dispatch_player_changed,
    game_event = handle_game_event
}

local function dispatch(event)
    local handler

    if event.action then
        handler = action_handlers[event.action]
    elseif event.channel then
        handler = broadcast_handlers[event.channel]
    end

    if handler then
        handler(event)
    else
        _dm("[warning] no registered handler for event " .. (event.action or event.channel or "unknown"))
    end
end

function gensou_OnStart()
    WSCLIENT = gensou.init(gensou_config.address, SERIAL:get("pin"))
end

function gensou_OnStep()
    if isLoaderRunning() then
        return
    end

    local message, opcode, encoded, error_code, error = gensou.receive(WSCLIENT)

    if not opcode and not error_code then
        wait(1)
        return
    end

    if opcode == websocket.frame.BINARY then
        neticonHideTransferring()
        _dm("ws message: " .. gensou.util.dump(message))
        dispatch(message)
    end

    if error_code then
        neticonShowOffline()
        _dm("ws error: " .. error .. " (" .. tostring(error_code) .. ")")
    else
        neticonShowOnline()
    end

    wait(1)
end

function gensou_OnClose()
    _dm("closing gensou")
    gensou.close(WSCLIENT)
    cls()
end

function gensou_OnVanish()
    _dm("closing gensou")
    gensou.close(WSCLIENT)
    cls()
end
