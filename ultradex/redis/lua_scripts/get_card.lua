-- Retrieves all details for a specific card UUID.
-- KEYS[1]: card_uuid (e.g., "123-025-R-S")
-- Returns: JSON string representing the card object, or nil if not found.

local card_uuid = KEYS[1]
local card_key = "card:" .. card_uuid

-- Check if the card exists
if redis.call("EXISTS", card_key) == 0 then
  return nil
end

local card_data = redis.call("HGETALL", card_key)

-- HGETALL returns an empty array if the key doesn't exist,
-- but we've already checked existence. If it's still empty,
-- it's an edge case (e.g. key exists but is not a hash, or hash is empty).
-- For simplicity, we assume if it exists, it's a hash with data.
if #card_data == 0 then
  return nil
end

local card_obj = {}
for i = 1, #card_data, 2 do
  card_obj[card_data[i]] = card_data[i+1]
end

return cjson.encode(card_obj)
