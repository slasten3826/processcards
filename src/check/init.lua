-- Check registry.
--
-- DEV_CLI_LAW §2 makes a crystall carried to manifest the unit of work, and
-- DEV_CLI_SLICE §1 fixes what that means:
--
--     a check is a module that CITES a CRYSTALL section and answers for it
--
-- The citation points at the crystall rather than the law because code
-- manifests from the crystall. The chain already exists:
--
--     check -> crystall section -> law declared as the crystall's source
--
-- Skipping the middle term collapses a layer boundary, and it shows up
-- immediately: LOGIC_JOKER_SLICE numbers its checks by the crystall, which is
-- correct, and a contract demanding law sections would force a made-up
-- mapping.
--
-- Consequence, and it is the point rather than a limitation: a law with no
-- crystall cannot have a check. Its uncoverability becomes visible instead of
-- being papered over by a direct citation.

local M = {}

M.LAW_DIRS = {
    "docs/table",
    "docs/table/operators",
    "docs/table/trumps",
}

M.CRYSTALL_DIR = "docs/crystall"
M.MODULE_DIR = "src/check"

local VALID_STATUS = {OK = true, FAIL = true, SKIP = true}
local VALID_REACHED = {played = true, planted = true}

--------------------------------------------------------------------------
-- result (DEV_CLI_SLICE §3)
--------------------------------------------------------------------------

-- A result is not a bool. A bool cannot express SKIP, and SKIP is what
-- separates a deferred law from an uncovered one.
function M.result(entry)
    return {
        cites = entry.cites,
        status = entry.status,
        reached = entry.reached or "played",
        effects = entry.effects or "all",
        detail = entry.detail,
    }
end

function M.ok(cites, detail, opts)
    opts = opts or {}
    return M.result({
        cites = cites, status = "OK", detail = detail,
        reached = opts.reached, effects = opts.effects,
    })
end

function M.fail(cites, detail, opts)
    opts = opts or {}
    return M.result({
        cites = cites, status = "FAIL", detail = detail,
        reached = opts.reached, effects = opts.effects,
    })
end

function M.skip(cites, detail, opts)
    opts = opts or {}
    return M.result({
        cites = cites, status = "SKIP", detail = detail,
        reached = opts.reached, effects = opts.effects,
    })
end

--------------------------------------------------------------------------
-- law index
--------------------------------------------------------------------------

local function list_files(dir)
    local out = {}
    local pipe = io.popen("ls " .. dir .. "/*.md 2>/dev/null")
    if not pipe then
        return out
    end
    for line in pipe:lines() do
        out[#out + 1] = line
    end
    pipe:close()
    return out
end

local function law_name_from_path(path)
    return (path:match("([^/]+)%.md$"))
end

-- Every "## <n>." heading is one addressable section. That heading style is
-- what citations point at, so the index is built from it and not from prose.
function M.law_index()
    local laws = {}
    local order = {}
    for _, dir in ipairs(M.LAW_DIRS) do
        for _, path in ipairs(list_files(dir)) do
            local name = law_name_from_path(path)
            local sections = {}
            local count = 0
            local file = io.open(path, "r")
            if file then
                for line in file:lines() do
                    local number = line:match("^##%s+(%d+)%.")
                    if number then
                        sections[tonumber(number)] = true
                        count = count + 1
                    end
                end
                file:close()
            end
            if not laws[name] then
                order[#order + 1] = name
            end
            laws[name] = {path = path, sections = sections, count = count}
        end
    end
    return laws, order
end

-- "TURN_STEP_SLICE_2026-07-28 §7" -> "TURN_STEP_SLICE_2026-07-28", 7
function M.parse_citation(citation)
    local name, section = citation:match("^(%S+)%s*§(%d+)$")
    if name then
        return name, tonumber(section)
    end
    return citation:match("^(%S+)$"), nil
end

-- Crystalls carry their law in the status block as
--     источник: ../table/<NAME>.md
-- A crystall without that line takes no part in the first transition.
function M.crystall_index()
    local crystalls = {}
    local order = {}
    for _, path in ipairs(list_files(M.CRYSTALL_DIR)) do
        local name = law_name_from_path(path)
        local entry = {path = path, sections = {}, count = 0, laws = {}}
        local file = io.open(path, "r")
        if file then
            for line in file:lines() do
                local number = line:match("^##%s+(%d+)%.")
                if number then
                    entry.sections[tonumber(number)] = true
                    entry.count = entry.count + 1
                end
                if line:match("^%s*источник:") then
                    for law in line:gmatch("%.%./table/([A-Za-z_0-9%-]+)%.md") do
                        entry.laws[law] = true
                    end
                end
            end
            file:close()
        end
        crystalls[name] = entry
        order[#order + 1] = name
    end
    return crystalls, order
end

--------------------------------------------------------------------------
-- modules
--------------------------------------------------------------------------

function M.modules()
    local names = {}
    local pipe = io.popen("ls " .. M.MODULE_DIR .. "/*.lua 2>/dev/null")
    if pipe then
        for line in pipe:lines() do
            local name = line:match("([^/]+)%.lua$")
            if name and name ~= "init" then
                names[#names + 1] = name
            end
        end
        pipe:close()
    end
    table.sort(names)
    return names
end

function M.load(name)
    local ok, module = pcall(require, "src.check." .. name)
    if not ok then
        return nil, tostring(module)
    end
    if type(module) ~= "table" or type(module.run) ~= "function" then
        return nil, "module exports no run"
    end
    if type(module.cites) ~= "table" or #module.cites == 0 then
        return nil, "module declares no cites"
    end
    return module
end

--------------------------------------------------------------------------
-- run
--------------------------------------------------------------------------

-- DEV_CLI_SLICE §10: a malformed result is a registry error, not silence.
-- Every one of these was reachable by writing a check carelessly, which is
-- exactly when nobody is looking.
local function validate(result, crystalls)
    if type(result) ~= "table" then
        return "result is not a table"
    end
    if not VALID_STATUS[result.status] then
        return "invalid status " .. tostring(result.status)
    end
    if not VALID_REACHED[result.reached] then
        return "invalid reached " .. tostring(result.reached)
    end
    if type(result.cites) ~= "string" then
        return "result carries no citation"
    end
    if result.status ~= "OK" and (result.detail == nil or result.detail == "") then
        return result.status .. " without detail"
    end
    local name, section = M.parse_citation(result.cites)
    local crystall = crystalls[name]
    if not crystall then
        return "citation to unknown crystall " .. tostring(name)
    end
    if section and not crystall.sections[section] then
        return string.format("citation to missing section %s §%d", name, section)
    end
    return nil
end

function M.run(opts)
    opts = opts or {}
    local crystalls = M.crystall_index()
    local report = {
        modules = {},
        results = {},
        registry_errors = {},
        counts = {OK = 0, FAIL = 0, SKIP = 0},
        planted = 0,
    }

    local names = opts.only and {opts.only} or M.modules()

    for _, name in ipairs(names) do
        local module, err = M.load(name)
        if not module then
            report.registry_errors[#report.registry_errors + 1] =
                string.format("%s: %s", name, err)
        else
            local entry = {name = name, cites = module.cites, results = {}}
            local produced = module.run(opts) or {}
            for _, result in ipairs(produced.results or {}) do
                local problem = validate(result, crystalls)
                if problem then
                    report.registry_errors[#report.registry_errors + 1] =
                        string.format("%s: %s", name, problem)
                else
                    result.module = name
                    entry.results[#entry.results + 1] = result
                    report.results[#report.results + 1] = result
                    report.counts[result.status] = report.counts[result.status] + 1
                    if result.reached == "planted" then
                        report.planted = report.planted + 1
                    end
                end
            end
            report.modules[#report.modules + 1] = entry
        end
    end

    report.ok = report.counts.FAIL == 0 and #report.registry_errors == 0
    return report
end

function M.format(report)
    local lines = {}
    for _, entry in ipairs(report.modules) do
        lines[#lines + 1] = string.format("=== %s ===", entry.name)
        for _, result in ipairs(entry.results) do
            lines[#lines + 1] = string.format(
                "%-4s %-28s %-8s %-5s %s",
                result.status, result.cites, result.effects,
                result.reached == "planted" and "PLANT" or "",
                result.detail or "")
        end
    end
    if #report.registry_errors > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "REGISTRY ERRORS"
        for _, err in ipairs(report.registry_errors) do
            lines[#lines + 1] = "  " .. err
        end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format(
        "OK %d   FAIL %d   SKIP %d   registry errors %d   via plant %d",
        report.counts.OK, report.counts.FAIL, report.counts.SKIP,
        #report.registry_errors, report.planted)
    lines[#lines + 1] = report.ok and "CHECKS PASS" or "CHECKS FAIL"
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------
-- coverage (DEV_CLI_SLICE §5)
--------------------------------------------------------------------------

-- Two transitions, reported separately, because they break differently.
-- Collapsing them into one number is how "55 crystalls exist" became
-- "the first transition works", which was wrong by a factor of three.
function M.coverage()
    local laws, law_order = M.law_index()
    local crystalls = M.crystall_index()

    local cited = {}
    for _, name in ipairs(M.modules()) do
        local module = M.load(name)
        for _, citation in ipairs(module and module.cites or {}) do
            local crystall_name, section = M.parse_citation(citation)
            cited[crystall_name] = cited[crystall_name] or {}
            if section then
                cited[crystall_name][section] = true
            end
        end
    end

    -- law -> crystalls declaring it
    local by_law = {}
    local crystall_sections, crystall_cited = 0, 0
    for name, crystall in pairs(crystalls) do
        crystall_sections = crystall_sections + crystall.count
        for section in pairs(crystall.sections) do
            if cited[name] and cited[name][section] then
                crystall_cited = crystall_cited + 1
            end
        end
        for law in pairs(crystall.laws) do
            by_law[law] = by_law[law] or {}
            by_law[law][#by_law[law] + 1] = name
        end
    end

    local report = {
        laws = {},
        order = law_order,
        law_count = #law_order,
        declared = 0,
        covered = 0,
        crystall_sections = crystall_sections,
        crystall_cited = crystall_cited,
    }

    for _, name in ipairs(law_order) do
        local sources = by_law[name] or {}
        local hits, total = 0, 0
        for _, crystall_name in ipairs(sources) do
            local crystall = crystalls[crystall_name]
            total = total + crystall.count
            for section in pairs(crystall.sections) do
                if cited[crystall_name] and cited[crystall_name][section] then
                    hits = hits + 1
                end
            end
        end
        report.laws[name] = {
            sources = sources,
            sections = total,
            cited = hits,
            sections_of_law = laws[name].count,
        }
        if #sources > 0 then
            report.declared = report.declared + 1
            if hits > 0 then
                report.covered = report.covered + 1
            end
        end
    end
    return report
end

function M.format_coverage(report, opts)
    opts = opts or {}
    local lines = {}
    lines[#lines + 1] = string.format(
        "⊞ -> ◈   законов %d, объявлено кристаллами %d",
        report.law_count, report.declared)
    lines[#lines + 1] = string.format(
        "◈ -> ▲   разделов кристаллов %d, процитировано %d",
        report.crystall_sections, report.crystall_cited)
    lines[#lines + 1] = string.format(
        "покрыто законов %d из %d", report.covered, report.law_count)
    lines[#lines + 1] = ""
    for _, name in ipairs(report.order) do
        local law = report.laws[name]
        local show = #law.sources > 0
        if show or not opts.covered_only then
            if #law.sources == 0 then
                lines[#lines + 1] = string.format("%-34s %-32s —", name, "нет кристалла")
            else
                lines[#lines + 1] = string.format("%-34s %-32s %d/%d",
                    name, table.concat(law.sources, ","), law.cited, law.sections)
            end
        end
    end
    return table.concat(lines, "\n")
end

return M
