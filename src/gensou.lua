local util = require("gensou.util")
local websocket = require("gensou.websocket")
local effil = require("effil")
local cbor = require("cbor")
cbor.type_encoders.string = cbor.type_encoders.utf8string

local function worker(address, game_version, serial_key, send_chan, send_result_chan, recv_chan, close_chan)
    local generate_request_id = require("gensou.util").generate_request_id
    local effil = require("effil")
    local websocket = require("gensou.websocket")
    local cbor = require("cbor")
    cbor.type_encoders.string = cbor.type_encoders.utf8string

    math.randomseed(os.time())

    local ssl = {
        mode = "client",
        protocol = "any",
        verify = "peer",
        castore = "org.openssl.winstore://",
        options = {"all", "no_sslv2", "no_sslv3", "no_tlsv1", "no_tlsv1_1"}
    }

    local client = websocket.client({timeout = 10})

    while (true) do
        if close_chan:pop(0) then
            client:close()
            effil.sleep(15, "ms")
            break
        end

        if client.state == "CLOSED" then
            client:connect(address, "thmj4n-cbor", ssl)
            if client.state == "OPEN" then
                local payload = {
                    id = generate_request_id(),
                    action = "auth",
                    data = {
                        game_version = game_version,
                        serial_key = serial_key
                    }
                }
                client:send(cbor.encode(payload), websocket.frame.BINARY)
            else
                effil.sleep(3, "s")
            end
        end

        local raw_message, opcode, encoded, error_code, error = client:poll()
        if opcode == websocket.frame.PING then
            client:send("PONG", websocket.frame.PONG)
        end

        if opcode == websocket.frame.BINARY or error_code then
            recv_chan:push(raw_message, opcode, encoded, error_code, error)
        end

        local to_send = send_chan:pop(0)
        if to_send then
            local send_result = client:send(to_send, websocket.frame.BINARY)
            send_result_chan:push(send_result)
        end

        effil.sleep(5, "ms")
    end
end

local function init(address, game_version, serial_key)
    local send_chan = effil.channel()
    local send_result_chan = effil.channel()
    local recv_chan = effil.channel()
    local close_chan = effil.channel()
    local thread = effil.thread(worker)(address, game_version, serial_key, send_chan, send_result_chan, recv_chan, close_chan)
    return {
        thread = thread,
        send_chan = send_chan,
        send_result_chan = send_result_chan,
        recv_chan = recv_chan,
        close_chan = close_chan
    }
end

local function send(client, data, action)
    -- TODO avoid calling game functions in this module
    neticonShowTransferring()
    local payload = {
        id = util.generate_request_id(),
        action = action,
        data = data
    }
    local encoded = cbor.encode(payload)
    local success = client.send_chan:push(encoded)
    if success then
        success = client.send_result_chan:pop(15, "ms")
    end

    if success then
        _dm("ws sent: " .. util.dump(payload))
    else
        _dm("ws send failed: " .. util.dump(payload))
    end

    return success, payload.id
end

local function receive(client)
    local message, opcode, encoded, error_code, error = client.recv_chan:pop(0)

    if opcode == websocket.frame.BINARY then
        message = cbor.decode(message)
    end

    return message, opcode, encoded, error_code, error
end

local function close(client)
    return client.close_chan:push(true)
end

local function join_lobby(client)
    return send(client, nil, "join_lobby")
end

local function leave_lobby(client)
    return send(client, nil, "leave_lobby")
end

local function join_room(client, data)
    return send(client, data, "join_room")
end

local function quick_join(client)
    return send(client, nil, "quick_join")
end

local function create_room(client, data)
    return send(client, data, "create_room")
end

local function leave_room(client)
    return send(client, nil, "leave_room")
end

local function add_cpu(client, data)
    return send(client, data, "add_cpu")
end

local function update_readiness(client, data)
    return send(client, data, "update_readiness")
end

local function update_loading_state(client, data)
    return send(client, data, "update_loading_state")
end

local function add_game_event(client, data)
    return send(client, data, "add_game_event")
end

local function finish_game(client, data)
    return send(client, data, "finish_game")
end

return {
    util = util,
    init = init,
    send = send,
    receive = receive,
    close = close,
    join_lobby = join_lobby,
    leave_lobby = leave_lobby,
    create_room = create_room,
    join_room = join_room,
    quick_join = quick_join,
    leave_room = leave_room,
    add_cpu = add_cpu,
    update_readiness = update_readiness,
    update_loading_state = update_loading_state,
    add_game_event = add_game_event,
    finish_game = finish_game
}
