-- Script: script:get_collection_cards
-- Retrieves all cards (card_uuids and their details_json) from a user's specific collection.
--
-- KEYS[1]: The key for the user's collection hash, e.g., user:USER_ID:collection_cards:COLLECTION_SLUG
-- ARGV: None needed for this script.
--
-- Returns: A list of alternating card_uuid (field) and details_json (value),
--          or an empty list if the collection is empty or does not exist.
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collection_cards:pikachu-master"],
--   argv: []
-- )

local collection_key = KEYS[1]

if collection_key == nil then
  return redis.error_reply("Missing KEYS for script_get_collection_cards")
end

return redis.call("HGETALL", collection_key)
