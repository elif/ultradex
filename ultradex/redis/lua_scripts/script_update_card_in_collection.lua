-- Script: script:update_card_in_collection
-- Updates (or adds if not present) a card with its details in a user's specific collection.
-- This is functionally identical to add_card_to_collection, using JSON.SET.
--
-- KEYS[1]: The key for the user's collection (RedisJSON document), e.g., user:USER_ID:collection_cards:COLLECTION_SLUG
-- ARGV[1]: card_uuid (key within the root JSON object)
-- ARGV[2]: details_json_object (a JSON string representing the new object of card details)
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collection_cards:pikachu-master"],
--   argv: ["001-025-N-S", "{\"condition\":\"Mint\",\"purchase_price\":12.50}"]
-- )

local collection_json_key = KEYS[1]
local card_uuid_path = ARGV[1]
local details_object_json_string = ARGV[2]

if collection_json_key == nil or card_uuid_path == nil or details_object_json_string == nil then
  return redis.error_reply("Missing KEYS or ARGV for script_update_card_in_collection")
end

-- Construct the JSON path
local path = "$." .. quote_json_path_key(card_uuid_path)

-- JSON.SET will add or update the path with the new JSON object.
local result = redis.call("JSON.SET", collection_json_key, path, details_object_json_string)
return result

-- Helper function to quote key names for JSONPath (copied from script_add_card_to_collection)
function quote_json_path_key(str)
  if string.match(str, "^[a-zA-Z_][a-zA-Z0-9_]*$") and not string.match(str, "^%d") then
    return str
  else
    return string.format("[\"%s\"]", string.gsub(str, "\"", "\\\""))
  end
end
