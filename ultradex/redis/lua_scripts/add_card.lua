-- Adds a new card or updates an existing one (upsert).
-- KEYS[1]: card_uuid (e.g., "123-025-R-S")
-- ARGV[1]: JSON string of card data fields.
--
-- Card data JSON should include:
--   national_pokedex_number
--   original_set_id
--   illustrator_name
--   card_name
--   (and all other fields for the card hash)
--
-- Returns: "OK" on success, or an error string.
--
-- Implicitly interacts with index keys:
-- - pokemon_cards:[national_pokedex_number]
-- - set_cards:[original_set_id]
-- - illustrator_cards:[normalized_illustrator_name]

local card_uuid = KEYS[1]
local card_data_json = ARGV[1]

local card_data
local success, err = pcall(function() card_data = cjson.decode(card_data_json) end)

if not success or not card_data then
  return redis.error_reply("Invalid JSON data: " .. (err or "decoding failed"))
end

-- Prepare card hash data for HMSET
local card_key = "card:" .. card_uuid
local hmset_args = {card_key}
local field_count = 0
for key, value in pairs(card_data) do
  table.insert(hmset_args, key)
  table.insert(hmset_args, tostring(value)) -- Ensure all values are strings for Redis
  field_count = field_count + 1
end

if field_count == 0 then
  return redis.error_reply("No data provided for card")
end

redis.call("HMSET", unpack(hmset_args))

-- Add to indexes
local pokedex_number = card_data["national_pokedex_number"]
if pokedex_number then
  redis.call("SADD", "pokemon_cards:" .. tostring(pokedex_number), card_uuid)
end

local original_set_id = card_data["original_set_id"]
if original_set_id then
  redis.call("SADD", "set_cards:" .. tostring(original_set_id), card_uuid)
end

local illustrator_name = card_data["illustrator_name"]
if illustrator_name then
  local normalized_illustrator = string.lower(tostring(illustrator_name))
  normalized_illustrator = string.gsub(normalized_illustrator, "%s+", "_")
  normalized_illustrator = string.gsub(normalized_illustrator, "[^%w_]+", "")
  if normalized_illustrator ~= "" then
    redis.call("SADD", "illustrator_cards:" .. normalized_illustrator, card_uuid)
  end
end

-- Logic for card_name_words index removed as per decision to use Redis Search.

return "OK"
