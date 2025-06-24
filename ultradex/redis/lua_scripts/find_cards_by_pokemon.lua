-- Returns a list of card UUIDs for a given Pokémon's National Pokédex number.
-- KEYS[1]: national_pokedex_number
-- Returns: Array of card UUIDs. (Redis SMEMBERS returns them directly)

local pokedex_number = KEYS[1]
local index_key = "idx:pokemon_cards:" .. pokedex_number

return redis.call("SMEMBERS", index_key)
