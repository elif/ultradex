-- Script: script:remove_card_from_collection
-- Removes a card from a user's specific collection.
--
-- Script: script:remove_card_from_collection
-- Removes a card's entry from a user's specific collection (RedisJSON document).
--
-- KEYS[1]: The key for the user's collection (RedisJSON document), e.g., user:USER_ID:collection_cards:COLLECTION_SLUG
-- ARGV[1]: card_uuid (key within the root JSON object to delete)
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collection_cards:pikachu-master"],
--   argv: ["001-025-N-S"]
-- )

local collection_json_key = KEYS[1]
local card_uuid_to_delete = ARGV[1]

if collection_json_key == nil or card_uuid_to_delete == nil then
  return redis.error_reply("Missing KEYS or ARGV for script_remove_card_from_collection")
end

-- Construct the JSON path
local path = "$." .. quote_json_path_key(card_uuid_to_delete)

local result = redis.call("JSON.DEL", collection_json_key, path)
return result

-- Helper function to quote key names for JSONPath (copied from script_add_card_to_collection)
function quote_json_path_key(str)
  if string.match(str, "^[a-zA-Z_][a-zA-Z0-9_]*$") and not string.match(str, "^%d") then
    return str
  else
    return string.format("[\"%s\"]", string.gsub(str, "\"", "\\\""))
  end
end
