-- Script: script:get_sets_by_release_number_range
-- Retrieves original_set_ids from the idx:sets_by_release_number sorted set
-- for sets within a given range of release_numbers (inclusive).
-- Optionally returns scores (release_numbers).
--
-- KEYS[1]: The key for the sorted set idx:sets_by_release_number
-- ARGV[1]: min_release_number (inclusive)
-- ARGV[2]: max_release_number (inclusive)
-- ARGV[3]: (Optional) "WITHSCORES" string. If provided, scores are returned.
--
-- Returns: A list of original_set_ids, or original_set_ids and scores if WITHSCORES is specified.
--
-- Example usage from Rails:
-- Get set IDs in range 100-110:
-- redis.evalsha(SCRIPT_SHA, keys: ["idx:sets_by_release_number"], argv: [100, 110])
-- Get set IDs and release numbers in range 100-110:
-- redis.evalsha(SCRIPT_SHA, keys: ["idx:sets_by_release_number"], argv: [100, 110, "WITHSCORES"])

local sets_by_release_key = KEYS[1]
local min_release_number = ARGV[1]
local max_release_number = ARGV[2]
local with_scores_arg = ARGV[3]

if sets_by_release_key == nil or min_release_number == nil or max_release_number == nil then
  return redis.error_reply("Missing KEYS or ARGV (min_release_number, max_release_number) for script_get_sets_by_release_number_range")
end

-- Ensure min and max are numbers, can be strings from ARGV
local min_r, err_min = tonumber(min_release_number)
if not min_r then
    return redis.error_reply("min_release_number must be a number. Got: " .. tostring(min_release_number))
end

local max_r, err_max = tonumber(max_release_number)
if not max_r then
    return redis.error_reply("max_release_number must be a number. Got: " .. tostring(max_release_number))
end

if with_scores_arg ~= nil and type(with_scores_arg) == "string" and string.upper(with_scores_arg) == "WITHSCORES" then
  return redis.call("ZRANGEBYSCORE", sets_by_release_key, min_r, max_r, "WITHSCORES")
else
  return redis.call("ZRANGEBYSCORE", sets_by_release_key, min_r, max_r)
end
