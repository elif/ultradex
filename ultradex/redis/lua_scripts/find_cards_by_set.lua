-- Returns a list of card UUIDs for a given original set ID.
-- KEYS[1]: original_set_id
-- Returns: Array of card UUIDs.

local original_set_id = KEYS[1]
local index_key = "idx:set_cards:" .. original_set_id

return redis.call("SMEMBERS", index_key)
