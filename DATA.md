## Data Handling and Storage

The UltrAdex project will exclusively use **Redis Stack** for all data storage, leveraging its capabilities like RedisJSON for structured data and Redis Search for advanced querying. All data, including card information, user collections, and any other persistent information, will reside in Redis.

### Card UUID (Identifier)

A custom UUID format will be used for uniquely identifying each card printing. This identifier is crucial for data retrieval and organization. The format is: `[set_release_number]-[pokedex_number]-[variant_code]-[frame_code]`

*   **`set_release_number`**: A chronological number assigned to each set upon its release. For example, the first set released would be `1`, the second `2`, and so on. This requires maintaining a central registry or logic for assigning these numbers.
*   **`pokedex_number`**: The National Pokédex number of the Pokémon featured on the card (e.g., `025` for Pikachu, `006` for Charizard). Use leading zeros to ensure consistent length if desired (e.g., 3 digits).
*   **`variant_code`**: A single letter representing the card's print style:
    *   `N`: Normal (non-holo)
    *   `H`: Holofoil (standard holo pattern in the image box)
    *   `R`: Reverse Holofoil (holo pattern on the card body, not the image)
    *   `O`: Other (e.g., special textured cards, full gold cards, unique promotional finishes not covered by N, H, R)
*   **`frame_code`**: A single letter representing the card's artwork frame type:
    *   `S`: Standard Frame (artwork contained within a typical window)
    *   `F`: Full Art Frame (artwork extends to the borders of the card)
    *   `A`: Alternate/Special Art Frame (distinctive artwork style, often also full art, but specifically designated as "Alternate Art" or "Special Art" by community/vendors)
    *   `J`: Jumbo Card

*Example UUID*: `123-025-R-S` could represent a Reverse Holo Pikachu from the 123rd released set with a standard art frame.

### Redis Data Structures and Keying Scheme

The following structures and keying patterns will be used. For a complete and authoritative list of all data structures, indexes (such as those for Pokémon, sets, illustrators, and chronological set ordering via `sets_by_release_number`), and their detailed definitions, please refer to `REQUIREMENTS.md` (Section 2.3). The `card_name_words` index has been removed in favor of Redis Search.

*   **Card Details**: Stored in Redis Hashes.
    *   **Key**: `card:[uuid]` (e.g., `card:123-025-R-S`)
    *   **Fields**: `pokemon_species_name`, `card_name`, `national_pokedex_number` (redundant with UUID but useful for direct hash access), `set_id` (original set identifier like `swsh9`), `set_name`, `series_name`, `release_date`, `card_number_in_set`, `rarity`, `card_type`, `pokemon_types`, `hp`, `illustrator_name`, `image_url_small`, `image_url_large`, `approximate_price_usd`, `last_price_update_timestamp`, `notes`, `variant_code` (from UUID), `frame_code` (from UUID).
*   **Set Information**: Stored in Redis Hashes.
    *   **Key**: `set:[original_set_id]` (e.g., `set:swsh9`, `set:base1`)
    *   **Fields**: `set_name`, `series_name`, `release_date`, `release_number` (the chronological `set_release_number` used in the card UUID), `original_set_id`, `total_cards` (optional, official number of cards in the set).
    *   *Note*: To enable chronological browsing and querying of sets by their release order, the system uses a sorted set `sets_by_release_number` as defined in `REQUIREMENTS.md`. This index maps `release_number` (as score) to `original_set_id` (as member).
*   **Pokémon to Cards Index**: Redis Sets. Allows finding all card UUIDs for a given Pokémon.
    *   **Key**: `pokemon_cards:[national_pokedex_number]` (e.g., `pokemon_cards:025`)
    *   **Members**: Set of `[card_uuid]`
*   **Set to Cards Index**: Redis Sets. Allows finding all card UUIDs for a given set.
    *   **Key**: `set_cards:[original_set_id]` (e.g., `set_cards:swsh9`)
    *   **Members**: Set of `[card_uuid]`
*   **Illustrator to Cards Index**: Redis Sets.
    *   **Key**: `illustrator_cards:[normalized_illustrator_name]` (e.g., `illustrator_cards:ken_sugimori`)
    *   **Members**: Set of `[card_uuid]`
*   **User Details**: Redis Hashes (if user accounts are implemented).
    *   **Key**: `user:[user_id]`
    *   **Fields**: `username`, `email`, `preferences (JSON string)`, etc.
*   **User Collections**: Redis Hashes for collection metadata.
    *   **Key**: `user:[user_id]:collection_meta:[collection_name_slug]` (e.g., `user:123:collection_meta:pikachu-master-set`)
    *   **Fields**: `display_name`, `target_pokemon_species (JSON array of names or pokedex_numbers)`, `creation_date`, `description`.
*   **User Owned Cards in Collection**: Redis Sets. Stores the UUIDs of cards a user owns for a specific collection.
    *   **Key**: `user:[user_id]:collection_cards:[collection_name_slug]`
    *   **Structure**: This is defined in detail in `REQUIREMENTS.md`.
    *   *Note*: The model for user-owned cards and collection tracking has been finalized in `REQUIREMENTS.md` (Section 2.3.3 and 2.4.1). It uses a **RedisJSON Document** for the key `user:[user_id]:collection_cards:[collection_slug]`. Within this document, top-level keys are `card_uuid`s, and their values are JSON objects containing collection-specific card details (condition, price, etc.). Please refer to `REQUIREMENTS.md` for the authoritative data structures and Lua script definitions. The details below regarding a simple Set or Redis Hash for this key are superseded.

### Redis Abstraction Layer (Lua Scripts)

To ensure controlled and consistent access to the data, all interactions with Redis should be performed through a defined set of Lua scripts (Redis stored procedures). This provides an abstraction layer and allows for complex atomic operations.

**For all User and Collection Management Lua scripts, please refer to `REQUIREMENTS.md` (Section 2.4.1) for the definitive list and specifications.** The list previously here is outdated.

Key Lua scripts to be developed (Card and Set Management - still relevant):

*   **Card Management:**
    *   `add_card(uuid, card_data_json)`: Adds a new card. Updates relevant indexes (pokemon, set, illustrator). `card_data_json` is a JSON string of all card attributes. (See `script:add_card` in `REQUIREMENTS.md`)
    *   `get_card(uuid)`: Retrieves all details for a specific card UUID. Returns a JSON string or map. (See `script:get_card` in `REQUIREMENTS.md`)
    *   `update_card_price(uuid, price_usd, timestamp)`: Updates pricing information for a card. (See `script:update_card_price` in `REQUIREMENTS.md`)
    *   `find_cards_by_pokemon(pokedex_number)`: Returns a list of card UUIDs for a given Pokémon. (See `script:find_cards_by_pokemon` in `REQUIREMENTS.md`)
    *   `find_cards_by_set(set_id)`: Returns a list of card UUIDs for a given set. (See `script:find_cards_by_set` in `REQUIREMENTS.md`)
    *   `find_cards_by_illustrator(illustrator_name)`: Returns a list of card UUIDs for a given illustrator. (See `script:find_cards_by_illustrator` in `REQUIREMENTS.md`)
*   **Set Management:**
    *   `add_set(set_id, set_data_json)`: Adds a new set, including its `release_number`. (See `script:add_set` in `REQUIREMENTS.md`)
    *   `get_set(set_id)`: Retrieves details for a set. (See `script:get_set` in `REQUIREMENTS.md`)

These scripts will encapsulate the logic for interacting with the defined Redis keys and structures, promoting data integrity and simplifying application-level code.
