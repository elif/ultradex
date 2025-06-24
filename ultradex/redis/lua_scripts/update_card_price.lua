-- Updates pricing information for a card.
-- KEYS[1]: card_uuid
-- ARGV[1]: new_price_usd
-- ARGV[2]: timestamp
-- Returns: "OK" if card exists and was updated, "Not Found" if card does not exist, or error string.

local card_uuid = KEYS[1]
local new_price_usd = ARGV[1]
local timestamp = ARGV[2]

local card_key = "card:" .. card_uuid

if redis.call("EXISTS", card_key) == 0 then
  return "Not Found"
end

local result_price = redis.call("HSET", card_key, "approximate_price_usd", new_price_usd)
local result_ts = redis.call("HSET", card_key, "last_price_update_timestamp", timestamp)

-- HSET returns 1 if a new field was created, 0 if an existing field was updated.
-- We consider both success.
if result_price ~= nil and result_ts ~= nil then
    return "OK"
else
    -- This case should ideally not be reached if EXISTS check passes and HSET commands are valid.
    return redis.error_reply("Failed to update price fields")
end
