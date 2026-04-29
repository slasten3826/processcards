local core = require("src.core.api")
local sim = require("src.sim.runner")

local function usage()
    io.write([[
Usage:
  lua cli.lua snapshot
  lua cli.lua events
  lua cli.lua draw
  lua cli.lua latent_trump_closure
  lua cli.lua scenario <name> [seed]
  lua cli.lua smoke [seed] [turns]
  lua cli.lua bench <name|smoke> [count] [seed]
]])
end

local function print_failure(result)
    io.write("FAIL\n")
    if result.stage then
        io.write("stage=" .. result.stage .. "\n")
    end
    if result.error then
        io.write("error=" .. tostring(result.error.name) .. "\n")
        io.write("details=" .. tostring(result.error.details) .. "\n")
    end
    if result.snapshot then
        io.write(result.snapshot .. "\n")
    end
end

local function print_success(result)
    io.write("OK\n")
    if result.transition then
        io.write("transition=" .. tostring(result.transition.kind) .. "\n")
    end
    if result.snapshot then
        io.write(result.snapshot .. "\n")
    end
end

local command = arg[1]
if not command then
    usage()
    os.exit(1)
end

if command == "scenario" then
    local name = arg[2]
    local seed = tonumber(arg[3]) or 1
    if not name then
        usage()
        os.exit(1)
    end
    local result = sim.run_scenario(name, seed)
    if result.ok then
        print_success(result)
        os.exit(0)
    end
    print_failure(result)
    os.exit(2)
end

if command == "smoke" then
    local seed = tonumber(arg[2]) or 1
    local turns = tonumber(arg[3]) or 8
    local result = sim.run_smoke(seed, turns)
    if result.ok then
        io.write("OK\n")
        io.write("turns=" .. #result.turns .. "\n")
        io.write(result.snapshot .. "\n")
        os.exit(0)
    end
    print_failure(result)
    os.exit(2)
end

if command == "bench" then
    local mode = arg[2]
    local count = tonumber(arg[3]) or 100
    local seed = tonumber(arg[4]) or 1
    if not mode then
        usage()
        os.exit(1)
    end
    local result = sim.bench(mode, count, seed)
    io.write(string.format(
        "mode=%s total=%d passed=%d skipped=%d failed=%d\n",
        result.mode,
        result.total,
        result.passed,
        result.skipped or 0,
        result.failed
    ))
    if result.first_failure then
        io.write("first_failure_seed=" .. result.first_failure.seed .. "\n")
        print_failure(result.first_failure.result)
        os.exit(2)
    end
    os.exit(0)
end

local game = core.new()
core.start_game(game)

if command == "setup" or command == "snapshot" then
    io.write(core.snapshot(game) .. "\n")
    os.exit(0)
end

if command == "events" then
    local events = core.drain_events(game)
    for _, event in ipairs(events) do
        io.write(string.format("%s\n", event.type))
    end
    os.exit(0)
end

if command == "draw" then
    core.draw_to_hand(game)
    io.write(core.snapshot(game) .. "\n")
    os.exit(0)
end

if command == "latent_trump_closure" then
    local result = sim.run_scenario("latent_trump_closure", 1)
    if result.ok then
        local info = result.scenario or {}
        io.write(string.format(
            "slot=%d manifest_before=%s latent_before=%s hand=%s\n",
            info.slot or -1,
            info.manifest_before or "-",
            info.latent_before or "-",
            info.hand_card_id or "-"
        ))
        if info.result and info.result.events then
            for _, event in ipairs(info.result.events) do
                io.write(string.format("event=%s\n", event.type))
            end
        end
        io.write(result.snapshot .. "\n")
        os.exit(0)
    end
    print_failure(result)
    os.exit(2)
end

usage()
os.exit(1)
