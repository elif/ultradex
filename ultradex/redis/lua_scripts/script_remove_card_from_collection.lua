-- Script: script:remove_card_from_collection
-- Removes a card from a user's specific collection.
--
-- KEYS[1]: The key for the user's collection hash, e.g., user:USER_ID:collection_cards:COLLECTION_SLUG
-- ARGV[1]: card_uuid (field to remove from the hash)
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collection_cards:pikachu-master"],
--   argv: ["001-025-N-S"]
-- )

local collection_key = KEYS[1]
local card_uuid = ARGV[1]

if collection_key == nil or card_uuid == nil then
  return redis.error_reply("Missing KEYS or ARGV for script_remove_card_from_collection")
end

return redis.call("HDEL", collection_key, card_uuid)
