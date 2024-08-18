local gensou = require("gensou")
local websocket = require("gensou.websocket")
local gensou_config = require("gensou_config")
local Mediator = require("mediator")

local subscriptions = {}
local channels = gensou.channels

mediator = Mediator()
WSCLIENT = nil

function gensou_OnStart()
    subscriptions.join_lobby = mediator:subscribe(channels.join_lobby, handle_join_lobby)
    subscriptions.join_room = mediator:subscribe(channels.join_room, handle_join_room)
    subscriptions.create_room = mediator:subscribe(channels.create_room, handle_create_room)
    subscriptions.players_changed = mediator:subscribe(channels.players_changed, handle_players_changed)
    subscriptions.motd = mediator:subscribe(channels.motd, handle_motd)
    subscriptions.player_loading_state = mediator:subscribe(channels.player_loading_state, handle_loading_state)
    subscriptions.game_event = mediator:subscribe(channels.game_event, handle_game_event)
    subscriptions.player_disconnected = mediator:subscribe(channels.player_disconnected, handle_player_disconnected)
    subscriptions.lobby_changed = mediator:subscribe(channels.lobby_changed, handle_lobby_changed)

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

        if message.action then
            mediator:publish({"action", message.action}, message)
        end
        if message.channel then
            mediator:publish({"broadcast", message.channel}, message)
        end
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
