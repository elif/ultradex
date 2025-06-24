-- Script: script:update_card_in_collection
-- Updates (or adds if not present) a card with its details in a user's specific collection.
-- This is functionally identical to add_card_to_collection, using HSET.
--
-- KEYS[1]: The key for the user's collection hash, e.g., user:USER_ID:collection_cards:COLLECTION_SLUG
-- ARGV[1]: card_uuid (field in the hash)
-- ARGV[2]: details_json (value for the field - a JSON string of card properties)
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collection_cards:pikachu-master"],
--   argv: ["001-025-N-S", "{\"condition\":\"M\",\"price\":12.0}"]
-- )

local collection_key = KEYS[1]
local card_uuid = ARGV[1]
local details_json = ARGV[2]

if collection_key == nil or card_uuid == nil or details_json == nil then
  return redis.error_reply("Missing KEYS or ARGV for script_update_card_in_collection")
end

-- HSET will add the field and value if the field does not exist,
-- or update the value if the field already exists.
return redis.call("HSET", collection_key, card_uuid, details_json)
