-- Script: script:add_card_to_collection
-- Adds or updates a card with its details in a user's specific collection.
--
-- Script: script:add_card_to_collection
-- Adds or updates a card with its details in a user's specific collection (RedisJSON document).
--
-- KEYS[1]: The key for the user's collection (RedisJSON document), e.g., user:USER_ID:collection_cards:COLLECTION_SLUG
-- ARGV[1]: card_uuid (used as the key within the root JSON object)
-- ARGV[2]: details_json_object (a JSON string representing the object of card details)
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collection_cards:pikachu-master"],
--   argv: ["001-025-N-S", "{\"condition\":\"NM\",\"purchase_price\":10.0}"]
-- )

local collection_json_key = KEYS[1]
local card_uuid_path = ARGV[1] -- This will form part of the JSON path, e.g., ".001-025-N-S"
local details_object_json_string = ARGV[2]

if collection_json_key == nil or card_uuid_path == nil or details_object_json_string == nil then
  return redis.error_reply("Missing KEYS or ARGV for script_add_card_to_collection")
end

-- Construct the JSON path. Example: if card_uuid_path is "001-025-N-S", path becomes ".[\"001-025-N-S\"]"
-- JSONPath keys with special characters like '-' need to be quoted.
local path = "$." .. quote_json_path_key(card_uuid_path)

-- Ensure the root object exists if the key is new, then set the card details.
-- JSON.SET will create the document if collection_json_key doesn't exist.
-- It will also create the path if it doesn't exist within an existing document.
local result = redis.call("JSON.SET", collection_json_key, path, details_object_json_string)

-- Initialize the document as an empty object if it was just created by JSON.SET on a non-existent key
-- This is often implicitly handled by JSON.SET if the path is to the root or a direct child of the root
-- of a new document, which effectively creates the root object.
-- However, to be explicit or if setting deeper paths initially, one might do:
-- if not redis.call("EXISTS", collection_json_key) then
--   redis.call("JSON.SET", collection_json_key, "$", "{}")
-- end
-- For path '$.card_uuid', JSON.SET on a new key will create root {} and then add card_uuid:details.

return result

-- Helper function to quote key names for JSONPath if they contain special characters
-- or are not valid unquoted keys.
function quote_json_path_key(str)
  -- Check if the string is a simple alphanumeric key (like a Lua identifier)
  if string.match(str, "^[a-zA-Z_][a-zA-Z0-9_]*$") and not string.match(str, "^%d") then
    return str -- Can be used with dot notation if the calling code adds the dot.
               -- Path is constructed as "$." .. result, so this becomes "$.key"
  else
    -- Needs to be quoted and use bracket notation
    return string.format("[\"%s\"]", string.gsub(str, "\"", "\\\""))
  end
end
