-- Script: script:get_all_sets_by_release_number
-- Retrieves all original_set_ids from the idx:sets_by_release_number sorted set,
-- ordered chronologically by release_number.
-- Optionally returns scores (release_numbers).
--
-- KEYS[1]: The key for the sorted set idx:sets_by_release_number
-- ARGV[1]: (Optional) "WITHSCORES" string. If provided, scores are returned.
--
-- Returns: A list of original_set_ids, or original_set_ids and scores if WITHSCORES is specified.
--
-- Example usage from Rails:
-- Get only set IDs:
-- redis.evalsha(SCRIPT_SHA, keys: ["idx:sets_by_release_number"])
-- Get set IDs and their release numbers:
-- redis.evalsha(SCRIPT_SHA, keys: ["idx:sets_by_release_number"], argv: ["WITHSCORES"])

local sets_by_release_key = KEYS[1]
local with_scores_arg = ARGV[1]

if sets_by_release_key == nil then
  return redis.error_reply("Missing KEYS for script_get_all_sets_by_release_number")
end

if with_scores_arg ~= nil and type(with_scores_arg) == "string" and string.upper(with_scores_arg) == "WITHSCORES" then
  return redis.call("ZRANGE", sets_by_release_key, 0, -1, "WITHSCORES")
else
  return redis.call("ZRANGE", sets_by_release_key, 0, -1)
end
