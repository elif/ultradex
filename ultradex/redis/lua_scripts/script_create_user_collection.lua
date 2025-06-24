-- Script: script:create_user_collection
-- Creates metadata for a new user collection and adds the collection slug to the user's list of collections.
--
-- KEYS[1]: The key for the user's collection metadata hash, e.g., user:USER_ID:collection_meta:COLLECTION_SLUG
-- KEYS[2]: The key for the user's set of collection slugs, e.g., user:USER_ID:collections
--
-- ARGV[1]: collection_slug
-- ARGV[2]: display_name
-- ARGV[3]: target_pokemon_pokedex_numbers_json (JSON string)
-- ARGV[4]: description
-- ARGV[5]: creation_date (string, e.g., ISO8601 or Unix timestamp)
-- ARGV[6]: last_updated (string, e.g., ISO8601 or Unix timestamp)
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["user:123:collection_meta:new-set", "user:123:collections"],
--   argv: [
--     "new-set",
--     "My New Set",
--     "[\"025\", \"006\"]",
--     "A collection of Pikachu and Charizard cards",
--     "2023-10-27T10:00:00Z",
--     "2023-10-27T10:00:00Z"
--   ]
-- )

local meta_key = KEYS[1]
local user_collections_set_key = KEYS[2]

local collection_slug = ARGV[1]
local display_name = ARGV[2]
local targets_json = ARGV[3]
local description = ARGV[4]
local creation_date = ARGV[5]
local last_updated = ARGV[6]

if meta_key == nil or user_collections_set_key == nil or collection_slug == nil or
   display_name == nil or targets_json == nil or description == nil or
   creation_date == nil or last_updated == nil then
  return redis.error_reply("Missing KEYS or ARGV for script_create_user_collection")
end

-- Add the slug to the user's set of collections
local sadd_result = redis.call("SADD", user_collections_set_key, collection_slug)

-- Create the hash for collection metadata
-- Using HMSET to set multiple fields.
-- If the collection_slug was already in the set, this will overwrite existing metadata.
-- Application layer should handle logic if overwrite is not desired (e.g., by checking sadd_result).
redis.call("HMSET", meta_key,
  "display_name", display_name,
  "target_pokemon_pokedex_numbers_json", targets_json,
  "description", description,
  "creation_date", creation_date,
  "last_updated", last_updated,
  "collection_slug", collection_slug -- Storing slug in meta too for completeness
)

-- Return SADD result (1 if new, 0 if already existed in set) and an OK status for HMSET
return {sadd_result, "OK"}
