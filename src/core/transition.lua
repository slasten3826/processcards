local M = {}

local DEFAULT_MAX_EVENTS_PER_TRANSITION = 5000

function M.begin(state, kind, payload)
    state.transition_seq = (state.transition_seq or 0) + 1
    state.current_transition = {
        seq = state.transition_seq,
        kind = kind,
        payload = payload or {},
        events = {},
    }
    state.transition_event_overflow = nil
    state.trump_chain_steps = 0
    state.trump_repair_attempts = 0
    return state.current_transition
end

function M.emit(state, event_type, payload)
    local max_events = state.max_transition_events_per_action or DEFAULT_MAX_EVENTS_PER_TRANSITION
    if state.current_transition and #state.current_transition.events >= max_events then
        state.transition_event_overflow = state.transition_event_overflow or {
            max_events = max_events,
            omitted = 0,
            first_omitted_type = event_type,
        }
        state.transition_event_overflow.omitted = state.transition_event_overflow.omitted + 1
        return {
            type = event_type,
            payload = payload or {},
            omitted = true,
        }
    end

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
    summary = summary or {}
    if state.trump_runaway and not summary.error then
        summary.error = "trump_flow_runaway"
    end
    if state.trump_runaway then
        summary.trump_runaway = state.trump_runaway
    end
    if state.transition_event_overflow then
        summary.transition_event_overflow = state.transition_event_overflow
        if not summary.error then
            summary.error = "transition_event_limit"
        end
    end
    state.current_transition.summary = summary
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
