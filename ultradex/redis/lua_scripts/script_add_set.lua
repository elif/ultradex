-- Script: script:add_set
-- Creates or updates a set's information and adds it to the release number index.
--
-- KEYS[1]: The key for the set's hash, e.g., set:swsh9
-- KEYS[2]: The key for the sorted set sets_by_release_number
--
-- ARGV[1]: original_set_id (e.g., "swsh9")
-- ARGV[2]: release_number (integer, e.g., 123)
-- ARGV[3]: set_data_json (JSON string of set fields: {"set_name":"Brilliant Stars", "series_name":"Sword & Shield", ...})
--
-- Example usage from Rails:
-- redis.evalsha(
--   SCRIPT_SHA,
--   keys: ["set:swsh9", "idx:sets_by_release_number"],
--   argv: ["swsh9", 123, "{\"set_name\":\"Brilliant Stars\", \"series_name\":\"Sword & Shield Series\", \"release_date\":\"2022-02-25\"}"]
-- )

local set_hash_key = KEYS[1]
local sets_by_release_key = KEYS[2]

local original_set_id = ARGV[1]
local release_number_str = ARGV[2] -- Keep as string for HMSET, convert to number for ZADD
local set_data_json = ARGV[3]

if set_hash_key == nil or sets_by_release_key == nil or original_set_id == nil or release_number_str == nil or set_data_json == nil then
  return redis.error_reply("Missing KEYS or ARGV for script_add_set")
end

local release_number
local success, val = pcall(tonumber, release_number_str)
if not success or val == nil then
  return redis.error_reply("Invalid release_number: must be a number. Got: " .. release_number_str)
else
  release_number = val
end

local set_data = cjson.decode(set_data_json)
if set_data == nil then
  return redis.error_reply("Invalid set_data_json: could not decode JSON. Got: " .. set_data_json)
end

-- Prepare data for HMSET - include release_number and original_set_id in the hash for completeness
local hash_args = {}
for k, v in pairs(set_data) do
  table.insert(hash_args, k)
  table.insert(hash_args, v)
end
table.insert(hash_args, "release_number")
table.insert(hash_args, release_number_str) -- Store as string in hash, consistent with other string fields
table.insert(hash_args, "original_set_id")  -- Store original_set_id in the hash too
table.insert(hash_args, original_set_id)

-- Create/update the set's hash
redis.call("HMSET", set_hash_key, unpack(hash_args))

-- Add to the sorted set for chronological ordering
local zadd_result = redis.call("ZADD", sets_by_release_key, release_number, original_set_id)

return {"OK", zadd_result}
