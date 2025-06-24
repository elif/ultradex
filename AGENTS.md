# AGENTS.md - Guidelines for AI-Assisted Development

This document provides guidelines for AI agents contributing to the UltrAdex project.

## General Principles

1.  **Understand the Goal:** Before making changes, ensure you understand the user's request and the overall objectives of the UltrAdex project as outlined in `README.md` and `REQUIREMENTS.md`.
2.  **Prioritize Clarity:** Code should be clear, well-commented (where necessary), and easy for human developers to understand.
3.  **Follow Requirements:** Adhere to the specifications outlined in `REQUIREMENTS.md` unless explicitly told otherwise by the user.
4.  **Iterative Development:** For complex features, propose a plan and seek user approval. Break down tasks into smaller, manageable steps.
5.  **Test Your Code:** While full test automation might not be in place initially, always manually verify your changes or write simple tests if applicable. (Future goal: Implement a testing framework).
6.  **Use Existing Tools/Libraries:** Prefer using established libraries or APIs (like the Pokémon TCG API mentioned in requirements) over reimplementing complex functionality.
7.  **Communicate:** If a request is unclear, or if you encounter significant roadblocks, communicate with the user using `request_user_input`. Provide updates on your progress.

## Coding Style (General - to be refined)

*   **Language:** The primary language for development will be Python (unless specified otherwise for specific components).
*   **Formatting:** Follow PEP 8 guidelines for Python code.
*   **Naming Conventions:** Use descriptive names for variables, functions, and classes (e.g., `get_card_details()` instead of `gcd()`).
*   **Modularity:** Strive for modular design. Break down code into reusable functions and classes where appropriate.

## File and Project Structure

*   Keep the project organized. New files should be placed in logical directories (e.g., `src/` for source code, `data/` for data files, `docs/` for documentation if it grows beyond root files).
*   Refer to `REQUIREMENTS.md` for the planned data schema and features.

## Specific Tool Usage

*   When modifying existing files, use `replace_with_git_merge_diff` for targeted changes.
*   Use `overwrite_file_with_block` only when replacing an entire file's content is intended and appropriate.
*   Use `create_file_with_block` for new files.
*   Always provide clear and concise commit messages when using `submit`.

## Data Handling and Storage

The UltrAdex project will exclusively use Redis for all data storage. This includes card data, user collections, and any other persistent information.

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

The following structures and keying patterns will be used:

*   **Card Details**: Stored in Redis Hashes.
    *   **Key**: `card:[uuid]` (e.g., `card:123-025-R-S`)
    *   **Fields**: `pokemon_species_name`, `card_name`, `national_pokedex_number` (redundant with UUID but useful for direct hash access), `set_id` (original set identifier like `swsh9`), `set_name`, `series_name`, `release_date`, `card_number_in_set`, `rarity`, `card_type`, `pokemon_types`, `hp`, `illustrator_name`, `image_url_small`, `image_url_large`, `approximate_price_usd`, `last_price_update_timestamp`, `notes`, `variant_code` (from UUID), `frame_code` (from UUID).
*   **Set Information**: Stored in Redis Hashes.
    *   **Key**: `set:[set_id]` (e.g., `set:swsh9`, `set:base1`)
    *   **Fields**: `set_name`, `series_name`, `release_date`, `release_number` (the chronological `set_release_number` used in the card UUID).
    *   *Note*: A separate sorted set `sets_by_release_number` could map `release_number` to `set_id` for easier chronological browsing or assignment of new numbers.
*   **Pokémon to Cards Index**: Redis Sets. Allows finding all card UUIDs for a given Pokémon.
    *   **Key**: `pokemon_cards:[pokedex_number]` (e.g., `pokemon_cards:025`)
    *   **Members**: Set of `[card_uuid]`
*   **Set to Cards Index**: Redis Sets. Allows finding all card UUIDs for a given set.
    *   **Key**: `set_cards:[set_id]` (e.g., `set_cards:swsh9`)
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
    *   **Members**: Set of `[card_uuid]`
    *   *Note*: For simplicity, this model assumes a user either owns a unique card printing (as defined by the UUID) or they don't within a collection. Tracking multiple copies of the exact same UUID with different conditions, purchase prices etc., would require a more complex structure (e.g., a list of JSON objects or additional Hashes per owned card instance). The current `REQUIREMENTS.md` implies more detailed tracking per owned instance, which would need `user:[user_id]:owned_instance:[uuid]:[instance_id]` storing a Hash of details. For this `AGENTS.md`, we'll stick to the simpler model and assume detailed instance tracking is an application layer concern built on top if needed, or that the Lua scripts will handle that complexity.

### Redis Abstraction Layer (Lua Scripts)

To ensure controlled and consistent access to the data, all interactions with Redis should be performed through a defined set of Lua scripts (Redis stored procedures). This provides an abstraction layer and allows for complex atomic operations.

Key Lua scripts to be developed:

*   **Card Management:**
    *   `add_card(uuid, card_data_json)`: Adds a new card. Updates relevant indexes (pokemon, set, illustrator). `card_data_json` is a JSON string of all card attributes.
    *   `get_card(uuid)`: Retrieves all details for a specific card UUID. Returns a JSON string or map.
    *   `update_card_price(uuid, price_usd, timestamp)`: Updates pricing information for a card.
    *   `find_cards_by_pokemon(pokedex_number)`: Returns a list of card UUIDs for a given Pokémon.
    *   `find_cards_by_set(set_id)`: Returns a list of card UUIDs for a given set.
    *   `find_cards_by_illustrator(illustrator_name)`: Returns a list of card UUIDs for a given illustrator.
*   **Set Management:**
    *   `add_set(set_id, set_data_json)`: Adds a new set, including its `release_number`.
    *   `get_set(set_id)`: Retrieves details for a set.
    *   `get_next_release_number()`: Atomically increments and returns the next available `set_release_number`.
*   **User and Collection Management (if accounts are implemented):**
    *   `create_user(user_data_json)`: Creates a new user.
    *   `get_user(user_id)`: Retrieves user details.
    *   `create_collection(user_id, collection_name_slug, collection_data_json)`: Creates a new collection for a user.
    *   `add_card_to_collection(user_id, collection_name_slug, card_uuid)`: Adds a card to a user's collection.
    *   `remove_card_from_collection(user_id, collection_name_slug, card_uuid)`: Removes a card from a user's collection.
    *   `get_collection_cards(user_id, collection_name_slug)`: Retrieves all card UUIDs in a user's collection.
    *   `get_user_collections(user_id)`: Retrieves metadata for all collections of a user.

These scripts will encapsulate the logic for interacting with the defined Redis keys and structures, promoting data integrity and simplifying application-level code.

By following these guidelines, AI agents can contribute effectively and help build a high-quality UltrAdex application.
