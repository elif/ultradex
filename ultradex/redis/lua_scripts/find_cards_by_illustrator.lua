-- Returns a list of card UUIDs for a given normalized illustrator name.
-- KEYS[1]: The normalized illustrator name (e.g., "ken_sugimori")
--          The script will construct the index key as "illustrator_cards:[normalized_illustrator_name]"
-- Returns: Array of card UUIDs.

local normalized_illustrator_name = KEYS[1]
if normalized_illustrator_name == nil then
  return redis.error_reply("Missing normalized_illustrator_name in KEYS[1]")
end
local index_key = "illustrator_cards:" .. normalized_illustrator_name

return redis.call("SMEMBERS", index_key)
