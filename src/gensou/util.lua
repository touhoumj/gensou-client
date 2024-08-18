local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local charset = {}
do -- [0-9a-zA-Z]
    for c = 48, 57 do
        table.insert(charset, string.char(c))
    end
    for c = 65, 90 do
        table.insert(charset, string.char(c))
    end
    for c = 97, 122 do
        table.insert(charset, string.char(c))
    end
end

local function random_string(length)
    if not length or length <= 0 then
        return ''
    end
    math.randomseed(os.clock() ^ 5)
    return random_string(length - 1) .. charset[math.random(1, #charset)]
end

local function generate_request_id()
    local length = 8
    return random_string(length)
end

return {
    dump = dump,
    random_string = random_string,
    generate_request_id = generate_request_id
}