-- Returns a list of card UUIDs for a given original set ID.
-- KEYS[1]: The original_set_id (e.g., "swsh9")
--          The script will construct the index key as "set_cards:[original_set_id]"
-- Returns: Array of card UUIDs.

local original_set_id = KEYS[1]
if original_set_id == nil then
  return redis.error_reply("Missing original_set_id in KEYS[1]")
end
local index_key = "set_cards:" .. original_set_id

return redis.call("SMEMBERS", index_key)
