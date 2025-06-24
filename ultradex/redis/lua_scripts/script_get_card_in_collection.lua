-- Script: script:get_card_in_collection
-- Retrieves the details_json for a specific card from a user's collection.
--
-- Script: script:get_card_in_collection
-- Retrieves the JSON object for a specific card from a user's collection (RedisJSON document).
--
-- KEYS[1]: The key for the user's collection (RedisJSON document), e.g., user:USER_ID:collection_cards:COLLECTION_SLUG
-- ARGV[1]: card_uuid (key within the root JSON object to retrieve)
--
-- Returns: The JSON object (as a string) for the specified card_uuid, or nil if not found.
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collection_cards:pikachu-master"],
--   argv: ["001-025-N-S"]
-- )

local collection_json_key = KEYS[1]
local card_uuid_to_get = ARGV[1]

if collection_json_key == nil or card_uuid_to_get == nil then
  return redis.error_reply("Missing KEYS or ARGV for script_get_card_in_collection")
end

-- Construct the JSON path
local path = "$." .. quote_json_path_key(card_uuid_to_get)

return redis.call("JSON.GET", collection_json_key, path)

-- Helper function to quote key names for JSONPath (copied from script_add_card_to_collection)
function quote_json_path_key(str)
  if string.match(str, "^[a-zA-Z_][a-zA-Z0-9_]*$") and not string.match(str, "^%d") then
    return str
  else
    return string.format("[\"%s\"]", string.gsub(str, "\"", "\\\""))
  end
end
