local M = {}

function M.handle_result(app, result, default_message)
    local summary = result and result.summary or nil
    if summary and summary.error then
        app:set_message("Rejected: " .. tostring(summary.error) .. ".")
        return
    end

    local events = app.core.drain_events(app.game)
    for _, event in ipairs(events) do
        local payload = event.payload or {}
        local line = event.type
        if payload.card_id then
            line = line .. " " .. tostring(payload.card_id)
        elseif payload.operator then
            line = line .. " " .. tostring(payload.operator)
        end
        app:push_log(line)
        app:trace("event", line)
    end

    if summary and summary.operator then
        app:set_message("Operator " .. tostring(summary.operator) .. " resolved.")
    elseif summary and summary.transition then
        app:set_message(tostring(summary.transition))
    else
        app:set_message(default_message or app.interaction.prompt)
    end
end

return M
