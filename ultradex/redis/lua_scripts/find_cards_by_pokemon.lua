-- Returns a list of card UUIDs for a given Pokémon's National Pokédex number.
-- KEYS[1]: The Pokémon's National Pokédex number (e.g., "025")
--          The script will construct the index key as "pokemon_cards:[national_pokedex_number]"
-- Returns: Array of card UUIDs. (Redis SMEMBERS returns them directly)

local pokedex_number = KEYS[1]
if pokedex_number == nil then
  return redis.error_reply("Missing national_pokedex_number in KEYS[1]")
end
local index_key = "pokemon_cards:" .. pokedex_number

return redis.call("SMEMBERS", index_key)
