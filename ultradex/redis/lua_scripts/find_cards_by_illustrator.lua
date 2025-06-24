-- Returns a list of card UUIDs for a given normalized illustrator name.
-- KEYS[1]: normalized_illustrator_name
-- Returns: Array of card UUIDs.

local normalized_illustrator_name = KEYS[1]
local index_key = "idx:illustrator_cards:" .. normalized_illustrator_name

return redis.call("SMEMBERS", index_key)
