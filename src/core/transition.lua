local M = {}

function M.begin(state, kind, payload)
    state.transition_seq = (state.transition_seq or 0) + 1
    state.current_transition = {
        seq = state.transition_seq,
        kind = kind,
        payload = payload or {},
        events = {},
    }
    return state.current_transition
end

function M.emit(state, event_type, payload)
    local event = {
        type = event_type,
        payload = payload or {},
    }
    state.event_stream[#state.event_stream + 1] = event
    if state.current_transition then
        state.current_transition.events[#state.current_transition.events + 1] = event
    end
    return event
end

function M.finish(state, summary)
    if not state.current_transition then
        return nil
    end
    state.current_transition.summary = summary or {}
    state.last_transition = state.current_transition
    state.current_transition = nil
    return state.last_transition
end

function M.drain_events(state)
    local events = state.event_stream
    state.event_stream = {}
    return events
end

return M
