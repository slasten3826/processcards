-- Check registry.
--
-- DEV_CLI_LAW §2 makes a crystall carried to manifest the unit of work, and
-- DEV_CLI_SLICE §1 fixes what that means:
--
--     a check is a module that CITES a law section and answers for it
--
-- Without the citation, coverage cannot be computed and "carried to manifest"
-- stays a phrase. So the citation is not documentation here; it is the thing
-- that makes the registry able to count.

local M = {}

M.LAW_DIRS = {
    "docs/table",
    "docs/table/operators",
    "docs/table/trumps",
}

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

-- "TURN_STEP_LAW §8" -> "TURN_STEP_LAW", 8
function M.parse_citation(citation)
    local name, section = citation:match("^(%S+)%s*§(%d+)$")
    if name then
        return name, tonumber(section)
    end
    return citation:match("^(%S+)$"), nil
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
local function validate(result, laws)
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
    local law = laws[name]
    if not law then
        return "citation to unknown law " .. tostring(name)
    end
    if section and not law.sections[section] then
        return string.format("citation to missing section %s §%d", name, section)
    end
    return nil
end

function M.run(opts)
    opts = opts or {}
    local laws = M.law_index()
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
                local problem = validate(result, laws)
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

function M.coverage()
    local laws, order = M.law_index()
    local cited = {}

    for _, name in ipairs(M.modules()) do
        local module = M.load(name)
        for _, citation in ipairs(module and module.cites or {}) do
            local law_name, section = M.parse_citation(citation)
            cited[law_name] = cited[law_name] or {}
            if section then
                cited[law_name][section] = true
            else
                cited[law_name].whole = true
            end
        end
    end

    local report = {laws = {}, order = order, sections = 0, covered = 0}
    for _, name in ipairs(order) do
        local law = laws[name]
        local hits = 0
        for section in pairs(law.sections) do
            if cited[name] and cited[name][section] then
                hits = hits + 1
            end
        end
        report.laws[name] = {total = law.count, cited = hits}
        report.sections = report.sections + law.count
        report.covered = report.covered + hits
    end
    return report
end

function M.format_coverage(report, opts)
    opts = opts or {}
    local lines = {}
    lines[#lines + 1] = string.format(
        "законов %d   разделов %d   цитируется %d   непокрыто %d",
        #report.order, report.sections, report.covered,
        report.sections - report.covered)
    lines[#lines + 1] = ""
    for _, name in ipairs(report.order) do
        local law = report.laws[name]
        if law.cited > 0 or not opts.covered_only then
            lines[#lines + 1] = string.format("%-40s %d/%d", name, law.cited, law.total)
        end
    end
    return table.concat(lines, "\n")
end

return M
