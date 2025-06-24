-- Script: script:add_card_to_collection
-- Adds or updates a card with its details in a user's specific collection.
--
-- KEYS[1]: The key for the user's collection hash, e.g., user:USER_ID:collection_cards:COLLECTION_SLUG
-- ARGV[1]: card_uuid (field in the hash)
-- ARGV[2]: details_json (value for the field - a JSON string of card properties in this collection)
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collection_cards:pikachu-master"],
--   argv: ["001-025-N-S", "{\"condition\":\"NM\",\"price\":10.0}"]
-- )

local collection_key = KEYS[1]
local card_uuid = ARGV[1]
local details_json = ARGV[2]

if collection_key == nil or card_uuid == nil or details_json == nil then
  return redis.error_reply("Missing KEYS or ARGV for script_add_card_to_collection")
end

return redis.call("HSET", collection_key, card_uuid, details_json)
