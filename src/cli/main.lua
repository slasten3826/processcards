local script_dir = (arg and arg[0] and arg[0]:match("^(.*)/[^/]+$")) or "."

local project_root = script_dir
if project_root:match("/src/cli$") then
    project_root = project_root:gsub("/src/cli$", "")
elseif project_root:match("/cli$") then
    project_root = project_root:gsub("/cli$", "")
elseif project_root == "." then
    project_root = "."
end

package.path = table.concat({
    project_root .. "/src/?.lua",
    project_root .. "/src/?/init.lua",
    project_root .. "/src/?/?.lua",
    package.path,
}, ";")

local core = require("src.core.api")
local render = require("src.cli.render")
local input = require("src.cli.input")

local function clear_screen()
    io.write(string.char(0x1b) .. "[2J")
    io.write(string.char(0x1b) .. "[H")
end

local function describe_event(event)
    if not event then
        return nil
    end
    local payload = event.payload or {}
    if event.type == "commit_manifest" then
        return string.format("commit manifest[%s] -> %s", tostring(payload.slot or "-"), tostring(payload.card_id or "-"))
    end
    if event.type == "arm_hand" then
        return string.format("arm hand -> %s", tostring(payload.card_id or "-"))
    end
    if event.type == "arm_operator" then
        return string.format("arm operator -> %s", tostring(payload.operator or "none"))
    end
    if event.type == "operator_resolve" then
        return string.format("resolve %s", tostring(payload.operator or "-"))
    end
    if event.type == "repair_manifest" then
        return string.format("repair manifest[%s]", tostring(payload.slot or "-"))
    end
    if event.type == "draw_to_hand" then
        return string.format("draw -> %s", tostring(payload.card_id or "-"))
    end
    if event.type == "start_game" or event.type == "setup_complete" then
        return event.type
    end
    return event.type
end

local function summarize_result(result)
    if not result then
        return ""
    end
    if result.summary and result.summary.error then
        return "ERROR: " .. result.summary.error
    end
    if result.kind then
        return "OK: " .. result.kind
    end
    return "OK"
end

local function main()
    local state = core.new()
    local status_message = ""
    local recent_events = {}
    local function start_new_game()
        state = core.new()
        local result = core.start_game(state, { rng = function(n) return math.random(n) end })
        status_message = summarize_result(result)
        recent_events = {}
        for _, event in ipairs(core.drain_events(state)) do
            local text = describe_event(event)
            if text then
                recent_events[#recent_events + 1] = text
            end
        end
    end

    start_new_game()

    while true do
        clear_screen()
        local ix = core.interaction(state)
        local output = render.render(state, ix, {
            message = status_message,
            events = recent_events,
        })
        io.write(output)
        io.write("> ")
        io.flush()

        local raw = io.read()
        if not raw then
            break
        end

        local action = input.parse(state, ix, raw)
        if not action then
            status_message = "No action."
            goto continue
        end

        if action.kind == "start" then
            start_new_game()
            goto continue
        end

        local result = core.apply_action(state, action)
        status_message = summarize_result(result)
        recent_events = {}
        for _, event in ipairs(core.drain_events(state)) do
            local text = describe_event(event)
            if text then
                recent_events[#recent_events + 1] = text
            end
        end
        if #recent_events > 6 then
            local trimmed = {}
            for i = #recent_events - 5, #recent_events do
                trimmed[#trimmed + 1] = recent_events[i]
            end
            recent_events = trimmed
        end

        ::continue::
    end
end

main()
