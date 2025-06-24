-- Script: script:get_user_collections_metadata
-- Retrieves all collection slugs for a given user.
--
-- KEYS[1]: The key for the user's set of collection slugs, e.g., user:USER_ID:collections
-- ARGV: None needed for this script.
--
-- Returns: A list of collection slugs.
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collections"],
--   argv: []
-- )

local user_collections_set_key = KEYS[1]

if user_collections_set_key == nil then
  return redis.error_reply("Missing KEYS for script_get_user_collections_metadata")
end

return redis.call("SMEMBERS", user_collections_set_key)
