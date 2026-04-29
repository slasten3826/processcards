local M = {}

function M.from_seed(seed)
    local state = seed or 1
    return function(max_n)
        state = (1103515245 * state + 12345) % 2147483648
        return (state % max_n) + 1
    end
end

return M
