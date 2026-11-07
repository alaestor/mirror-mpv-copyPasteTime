-- A 400,000-second, 8 kHz mono WAV. Only the header and final byte are written.
local function le(n, bytes)
    local result = {}
    for i = 1, bytes do
        result[i] = string.char(n % 256)
        n = math.floor(n / 256)
    end
    return table.concat(result)
end

local bytes = 400000 * 8000
local file = assert(io.open(assert(arg[1]), "wb"))
assert(file:write("RIFF", le(bytes + 36, 4), "WAVEfmt ", le(16, 4),
    le(1, 2), le(1, 2), le(8000, 4), le(8000, 4), le(1, 2), le(8, 2),
    "data", le(bytes, 4)))
assert(file:seek("set", bytes + 43))
assert(file:write("\0"))
assert(file:close())
