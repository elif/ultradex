-- Script: script:get_collection_cards
-- Retrieves all cards (card_uuids and their details_json) from a user's specific collection.
--
-- Script: script:get_collection_cards
-- Retrieves the entire JSON document representing a user's specific collection.
-- The document is an object where keys are card_uuids and values are their details.
--
-- KEYS[1]: The key for the user's collection (RedisJSON document), e.g., user:USER_ID:collection_cards:COLLECTION_SLUG
-- ARGV: None needed for this script.
--
-- Returns: The entire JSON document as a string, or nil if the key does not exist.
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collection_cards:pikachu-master"],
--   argv: []
-- )

local collection_json_key = KEYS[1]

if collection_json_key == nil then
  return redis.error_reply("Missing KEYS for script_get_collection_cards")
end

-- Get the entire JSON document at the root path '$'
return redis.call("JSON.GET", collection_json_key, "$")
