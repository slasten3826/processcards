local core = require("src.core.api")
local render = require("src.cli.render")
local input = require("src.cli.input")

local function clear_screen()
    io.write(string.char(0x1b) .. "[2J")
    io.write(string.char(0x1b) .. "[H")
end

local function log_transition(result)
    if not result then
        return
    end
    if result.summary and result.summary.error then
        io.write("ERROR: " .. result.summary.error .. "\n")
        return
    end
end

local function main()
    local state = core.new()
    core.start_game(state, { rng = function(n) return math.random(n) end })

    while true do
        clear_screen()
        local ix = core.interaction(state)
        local output = render.render(state, ix)
        io.write(output)
        io.write("> ")
        io.flush()

        local raw = io.read()
        if not raw then
            break
        end

        local action = input.parse(state, ix, raw)
        if not action then
            goto continue
        end

        if action.kind == "start" then
            state = core.new()
            core.start_game(state, { rng = function(n) return math.random(n) end })
            goto continue
        end

        local result = core.apply_action(state, action)
        log_transition(result)

        ::continue::
    end
end

main()
