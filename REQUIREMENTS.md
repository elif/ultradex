# UltrAdex Requirements

## 1. Introduction

UltrAdex is a software tool designed to assist Pokémon card collectors in building "master sets." A master set is defined as every unique front printing of a card for a specific Pokémon species. The tool will maintain a comprehensive database of Pokémon card printings and allow users to track their collections and generate customizable placeholder images for cards they are missing. These placeholders are intended for use in binders.

## 2. Data Requirements

### 2.1. Card Data Attributes

The system shall store the following information for each unique Pokémon card printing:

*   **`card_uuid`**: A unique identifier for each distinct card printing, crucial for data retrieval and organization. The format is: `[set_release_number]-[pokedex_number]-[variant_code]-[frame_code]`
    *   **`set_release_number`**: A chronological number assigned to each set upon its release (e.g., `1`, `2`, ...). This requires a mechanism to assign and track these numbers globally for all sets.
    *   **`pokedex_number`**: The National Pokédex number of the Pokémon (e.g., `025` for Pikachu, `006` for Charizard). Use leading zeros for consistency (e.g., 3 digits).
    *   **`variant_code`**: A single letter representing the card's print style:
        *   `N`: Normal (non-holo)
        *   `H`: Holofoil (standard holo pattern in the image box)
        *   `R`: Reverse Holofoil (holo pattern on the card body)
        *   `O`: Other (e.g., special textured, gold cards, unique finishes)
    *   **`frame_code`**: A single letter representing the card's artwork frame type:
        *   `S`: Standard Frame
        *   `F`: Full Art Frame
        *   `A`: Alternate/Special Art Frame
        *   `J`: Jumbo Card
    *   *Example UUID*: `123-025-R-S` could represent a Reverse Holo Pikachu from the 123rd released set with a standard art frame.
    *   This `card_uuid` replaces the previous `card_id` concept and will be the primary key for cards.
*   **`original_set_id`**: The original set identifier if available from the source API (e.g., `base1`, `swsh9`). Useful for referencing external API data.
*   **`pokemon_species_name`**: The name of the Pokémon featured on the card (e.g., "Pikachu", "Charizard").
*   **`card_name`**: The full name of the card as it appears on the card (e.g., "Charizard VMAX", "Birthday Pikachu").
*   **`national_pokedex_number`**: The National Pokédex number of the Pokémon species.
*   **`set_name`**: The name of the expansion set the card belongs to (e.g., "Base Set", "Brilliant Stars").
*   **`set_id`**: A unique identifier for the set (e.g., `base1`, `swsh9`).
*   **`series_name`**: The name of the series the set belongs to (e.g., "Sword & Shield Series", "Original Series").
*   **`release_date`**: The official release date of the set or card.
*   **`card_number_in_set`**: The collector number of the card within its set (e.g., "4/102", "TG01/TG30").
*   **`rarity`**: The rarity of the card (e.g., "Common", "Uncommon", "Rare", "Holo Rare", "Ultra Rare", "Secret Rare").
*   **`card_type`**: Type of card (e.g., "Pokémon", "Trainer", "Energy").
*   **`pokemon_types`**: If `card_type` is "Pokémon", the Pokémon's type(s) (e.g., "Fire", "Water", "Grass, Psychic").
*   **`hp`**: If `card_type` is "Pokémon", the Hit Points of the Pokémon.
*   **`illustrator_name`**: The name of the artist who illustrated the card.
*   **`image_url_small`**: A URL to a small, low-resolution image of the card front.
*   **`image_url_large`**: A URL to a large, high-resolution image of the card front.
*   **`approximate_price_usd`**: An estimated market price of the card in USD, typically reflecting Near Mint condition, sourced from an aggregation of online marketplaces or a dedicated pricing API (e.g., TCGPlayer API). This should be updated periodically.
*   **`last_price_update_timestamp`**: Timestamp indicating when `approximate_price_usd` was last updated.
*   **`notes`**: Optional field for any additional relevant information about a specific printing (e.g., "Staff Prerelease", "1st Edition", "Reverse Holo", "Jumbo"). This field helps distinguish printings that might otherwise share many attributes. "Unique front printing" aims to capture all visually distinct card fronts, including common promotional variants (e.g., McDonald's promos, Prerelease promos with set stamps), different holo patterns if they are cataloged by the API, and major recognized error cards if data is available.

### 2.2. Data Source and Management

*   **Source:** The primary data source will be a reputable Pokémon TCG API. [https://pokemontcg.io/](https://pokemontcg.io/) is the current candidate. Evaluation of its terms of service, data completeness (especially for variants and older sets), accuracy, and update frequency is required. The data fetched from this API will be transformed and stored in Redis.
*   **Updates:** The system should have a mechanism to periodically update its Redis database from the chosen API. A nightly batch job is recommended, fetching new sets, card data, and price updates. Changed cards will be updated or new ones added in Redis. This process will involve generating the correct `card_uuid` for new entries.
*   **Data Storage:** All data will be stored exclusively in **Redis**.

### 2.3. Redis Data Structures and Keying Scheme

This section details the Redis structures used to store UltrAdex data. All interactions with these structures must go through the defined Lua script abstraction layer.

#### 2.3.1. Core Data Structures:

*   **Card Details**: Stored in Redis Hashes.
    *   **Key**: `card:[card_uuid]` (e.g., `card:123-025-R-S`)
    *   **Fields**:
        *   `pokemon_species_name`: (e.g., "Pikachu")
        *   `card_name`: (e.g., "Charizard VMAX")
        *   `national_pokedex_number`: (e.g., `025`)
        *   `original_set_id`: (e.g., `swsh9`)
        *   `set_name`: (e.g., "Brilliant Stars")
        *   `series_name`: (e.g., "Sword & Shield Series")
        *   `release_date`: (e.g., "2022-02-25")
        *   `card_number_in_set`: (e.g., "TG01/TG30")
        *   `rarity`: (e.g., "Holo Rare")
        *   `card_type`: (e.g., "Pokémon")
        *   `pokemon_types`: (e.g., "Fire", "Water, Psychic" - stored as a comma-separated string or JSON array)
        *   `hp`: (e.g., `120`)
        *   `illustrator_name`: (e.g., "Ken Sugimori")
        *   `image_url_small`: URL
        *   `image_url_large`: URL
        *   `approximate_price_usd`: (e.g., `15.99`)
        *   `last_price_update_timestamp`: Unix timestamp
        *   `notes`: (e.g., "Staff Prerelease")
        *   `variant_code`: (e.g., `R` - from `card_uuid`)
        *   `frame_code`: (e.g., `S` - from `card_uuid`)
        *   `set_release_number`: (e.g., `123` - from `card_uuid`)

*   **Set Information**: Stored in Redis Hashes.
    *   **Key**: `set:[original_set_id]` (e.g., `set:swsh9`)
    *   **Fields**:
        *   `set_name`: (e.g., "Brilliant Stars")
        *   `series_name`: (e.g., "Sword & Shield Series")
        *   `release_date`: (e.g., "2022-02-25")
        *   `release_number`: The chronological `set_release_number` used in `card_uuid` (e.g., `123`). This is critical for generating `card_uuid`s.
        *   `total_cards`: (optional, total cards in the set from API)
*   **Global Set Release Number Counter**: Redis Integer.
    *   **Key**: `global:next_set_release_number`
    *   **Usage**: Atomically incremented (`INCR`) to get a new `set_release_number` when a new set is first processed.

#### 2.3.2. Indexing Structures (Primarily Redis Sets):

*   **Pokémon to Cards Index**:
    *   **Key**: `idx:pokemon_cards:[national_pokedex_number]` (e.g., `idx:pokemon_cards:025`)
    *   **Members**: Set of `[card_uuid]`
*   **Set (Original ID) to Cards Index**:
    *   **Key**: `idx:set_cards:[original_set_id]` (e.g., `idx:set_cards:swsh9`)
    *   **Members**: Set of `[card_uuid]`
*   **Illustrator to Cards Index**:
    *   **Key**: `idx:illustrator_cards:[normalized_illustrator_name]` (e.g., `idx:illustrator_cards:ken_sugimori`)
    *   **Members**: Set of `[card_uuid]`
*   **Card Name Search Index (Simplified)**: While Redis is not a full-text search engine, simple name matching can be supported.
    *   **Key**: `idx:card_name_words:[word_token]` (e.g., `idx:card_name_words:pikachu`, `idx:card_name_words:vmax`)
    *   **Members**: Set of `[card_uuid]` that include this word in their `card_name`. (Requires preprocessing of card names).
    *   *Alternative*: Use Redis Search module for more advanced searching if available.

#### 2.3.3. User-Specific Collection Data:

This data is stored per user and requires user identification.

*   **User Details** (if accounts are implemented, FR3.5): Stored in Redis Hashes.
    *   **Key**: `user:[user_id]`
    *   **Fields**: `username`, `email_hash` (if storing email), `preferences_json`, `creation_date`.
*   **User Collection Metadata**: Stored in Redis Hashes.
    *   **Key**: `user:[user_id]:collection_meta:[collection_slug]` (e.g., `user:xyz789:collection_meta:my-pikachu-set`)
        *   `collection_slug` should be a URL-friendly version of the collection name.
    *   **Fields**: `display_name` (e.g., "My Pikachu Set"), `target_pokemon_pokedex_numbers_json` (JSON array of Pokédex numbers), `creation_date`, `description`, `last_updated`.
*   **User Owned Card Instances**: This structure supports tracking individual copies with their specific details as per original requirements. Stored in Redis Hashes.
    *   **Key**: `user:[user_id]:owned_instance:[card_uuid]:[instance_id]`
        *   `instance_id`: A unique ID for this specific copy owned by the user (e.g., a timestamp, or a simple counter like `1`, `2`). This allows a user to own multiple copies of the *same* `card_uuid` but track them separately.
    *   **Fields**:
        *   `collection_slugs_json`: JSON array of collection slugs this instance belongs to (a card can be in multiple "master sets" a user defines).
        *   `quantity`: Typically 1 for unique instance tracking. If not using `instance_id` for true uniqueness but rather for "versions" of an owned card, this could be >1. For precise per-copy tracking, `quantity` on this hash should be 1.
        *   `condition`: (e.g., "Near Mint")
        *   `language_owned`: (e.g., "English")
        *   `purchase_price`: (e.g., `10.50`)
        *   `purchase_date`: (e.g., "2023-01-15")
        *   `user_notes_on_owned_card`: (e.g., "Graded PSA 9")
        *   `added_to_collection_date`: Timestamp.
*   **Index: User's Collections**: Redis Set. Stores slugs of all collections for a user.
    *   **Key**: `user:[user_id]:collections`
    *   **Members**: Set of `[collection_slug]`
*   **Index: Cards in User Collection**: Redis Set. Links a collection to the `card_uuid`s it contains (regardless of how many instances of that `card_uuid` the user owns). This is for quickly knowing which *unique printings* are in a collection.
    *   **Key**: `user:[user_id]:collection_cards:[collection_slug]`
    *   **Members**: Set of `[card_uuid]` (unique card printings).

### 2.4. Data Abstraction Layer (Redis Lua Scripts)

All data access (read, write, update, delete) to Redis MUST be performed through a well-defined set of Lua scripts executed server-side by Redis. This ensures:
*   **Atomicity**: Complex operations involving multiple keys can be performed atomically.
*   **Encapsulation**: The application code does not need to know the low-level details of Redis keys and data structures.
*   **Performance**: Reduces network round-trips for complex operations.
*   **Data Integrity**: Centralized logic for data manipulation.

#### 2.4.1. Key Lua Scripts (Examples - full list to be extensive):

*   **Card & Set Management Scripts:**
    *   `script:add_card(keys_json, args_json)`:
        *   KEYS: `card:[card_uuid]`, `idx:pokemon_cards:[pokedex_number]`, `idx:set_cards:[original_set_id]`, `idx:illustrator_cards:[norm_illustrator_name]`, relevant `idx:card_name_words:*`.
        *   ARGS: `card_uuid`, all card data fields as a JSON string.
        *   Logic: Creates the card hash, adds UUID to all relevant indexes.
    *   `script:get_card(keys_json, args_json)`: KEYS: `card:[card_uuid]`. ARGS: `card_uuid`. Returns card hash.
    *   `script:update_card_price(keys_json, args_json)`: KEYS: `card:[card_uuid]`. ARGS: `card_uuid`, `new_price`, `timestamp`. Updates price fields.
    *   `script:find_cards_by_pokemon(keys_json, args_json)`: KEYS: `idx:pokemon_cards:[pokedex_number]`. ARGS: `pokedex_number`. Returns set of `card_uuid`s.
    *   `script:add_set(keys_json, args_json)`:
        *   KEYS: `set:[original_set_id]`, `global:next_set_release_number` (if assigning release number here).
        *   ARGS: `original_set_id`, all set data fields as JSON string (including `release_number` if pre-assigned, or flag to assign).
        *   Logic: Creates set hash. Optionally gets next `release_number`.
    *   `script:get_next_set_release_number(keys_json, args_json)`: KEYS: `global:next_set_release_number`. ARGS: none. Returns `INCR global:next_set_release_number`.

*   **User & Collection Management Scripts:**
    *   `script:create_user_collection(keys_json, args_json)`:
        *   KEYS: `user:[user_id]:collection_meta:[collection_slug]`, `user:[user_id]:collections`.
        *   ARGS: `user_id`, `collection_slug`, collection metadata JSON.
        *   Logic: Creates metadata hash, adds slug to user's list of collections.
    *   `script:add_owned_card_instance(keys_json, args_json)`:
        *   KEYS: `user:[user_id]:owned_instance:[card_uuid]:[instance_id]`, `user:[user_id]:collection_cards:[collection_slug]` (for each collection it's in).
        *   ARGS: `user_id`, `card_uuid`, `instance_id`, owned instance data JSON (including `collection_slugs_json`).
        *   Logic: Creates the owned instance hash. Adds `card_uuid` to the `collection_cards` set for each specified collection if not already present.
    *   `script:remove_owned_card_instance(keys_json, args_json)`:
        *   KEYS: `user:[user_id]:owned_instance:[card_uuid]:[instance_id]`, potentially `user:[user_id]:collection_cards:[collection_slug]` if this is the last instance of a card_uuid in a collection.
        *   ARGS: `user_id`, `card_uuid`, `instance_id`.
        *   Logic: Deletes the instance hash. May need logic to check if `card_uuid` should be removed from `collection_cards` if no other instances of this `card_uuid` exist for that collection.
    *   `script:get_collection_details(keys_json, args_json)`:
        *   KEYS: `user:[user_id]:collection_meta:[collection_slug]`, `user:[user_id]:collection_cards:[collection_slug]`.
        *   ARGS: `user_id`, `collection_slug`.
        *   Logic: Returns metadata and the set of unique `card_uuid`s in the collection. To get all *instances*, further calls to get `owned_instance` hashes would be needed by the application, or a more complex script.
    *   `script:get_all_owned_instances_for_card_in_collection(keys_json, args_json)`: (More advanced)
        *   KEYS: Scan `user:[user_id]:owned_instance:[card_uuid]:*`
        *   ARGS: `user_id`, `card_uuid`, `collection_slug`
        *   Logic: Iterates through instances of a `card_uuid` for a user, filters by `collection_slug` in their `collection_slugs_json` field.

This list is not exhaustive but illustrates the principle. The Ruby on Rails application backend will be responsible for loading these Lua scripts into Redis (e.g., during an initialization phase or on-demand) and calling them with appropriate arguments using a Ruby Redis client like `redis-rb`.

### 2.5. User-Specific Collection Data (Legacy - Now Integrated into Redis Section)

This data is stored locally or synced if user accounts are implemented. (This section header is legacy, content moved to 2.3.3)

*   **`user_id`**: Unique identifier for a user (relevant if accounts are implemented, see FR3.5).
*   **`collection_id`**: (Now `collection_slug`) Unique identifier for a user-defined master set.
*   **`owned_card_instance_id`**: (Now composite key `user:[user_id]:owned_instance:[card_uuid]:[instance_id]`) A unique identifier for each specific copy of a card a user owns.
*   **`card_id`**: (Now `card_uuid`) Foreign key linking to the main card data, identifying the specific printing owned.
*   **`quantity_owned`**: Number of copies of this specific card printing the user owns. (Handled by `instance_id` for unique copies, or a field within the instance hash).
*   **`condition`**: Condition of the owned card (e.g., Enum: "Mint", "Near Mint", "Lightly Played", "Moderately Played", "Heavily Played", "Damaged").
*   **`language_owned`**: Language of the owned card (e.g., "English", "Japanese", "German", "French"). Defaults to "English".
*   **`purchase_price`**: Price paid by the user for the card. Stored in the user's preferred currency (see FR3.7.1).
*   **`purchase_date`**: Date the user acquired the card.
*   **`user_notes_on_owned_card`**: Optional user-specific notes for this owned card (e.g., "Graded PSA 9", "From childhood collection").

## 3. Functional Requirements

### 3.1. Master Set Definition and Management

*   **FR3.1.1:** Users shall be able to define one or more "master sets" they wish to collect.
*   **FR3.1.2:** Defining a master set involves selecting one or more Pokémon species (by name or Pokédex number). This information is stored in the `User Collection Metadata` (see 2.3.3).
*   **FR3.1.3:** The system shall display all known unique printings (based on `card_uuid`) for the selected Pokémon species when a user is viewing or defining a master set. Lua scripts will query the `idx:pokemon_cards:[pokedex_number]` index. Users should be able to distinguish versions based on the `variant_code` and `frame_code` in the `card_uuid` and other attributes in the `card:[card_uuid]` hash.

### 3.2. Collection Tracking

*   **FR3.2.1:** For each card printing (`card_uuid`) in the database, users shall be able to mark if they own one or more copies. This involves creating/updating `User Owned Card Instances` (see 2.3.3) using Lua scripts, including details like condition, language, purchase price, and purchase date for each specific instance.
*   **FR3.2.2:** The system shall visually distinguish between owned and unowned `card_uuid`s when displaying lists of cards. This can be determined by checking for the existence of related `User Owned Card Instances` for the current user and relevant `card_uuid`.
*   **FR3.2.3:** Users shall be able to view statistics for their collection, such as:
    *   Percentage complete for a defined master set (based on unique `card_uuid`s present in `user:[user_id]:collection_cards:[collection_slug]` compared to all `card_uuid`s for the target Pokémon).
    *   Total number of unique `card_uuid`s owned across all collections.
    *   Total number of owned card instances (summing up all `user:[user_id]:owned_instance:[card_uuid]:[instance_id]` records for a user).
    *   Estimated total market value of the collection (sum of `approximate_price_usd` for owned cards, adjusted for user's currency).
    *   Total spent on collection (sum of `purchase_price` for owned cards).

### 3.3. Placeholder Generation

*   **FR3.3.1:** Users shall be able to select a Pokémon species (or a defined master set) to generate placeholders for.
*   **FR3.3.2:** By default, placeholders will be generated for cards the user has marked as unowned for the selected species/master set.
*   **FR3.3.3:** Users shall be able to manually select or deselect specific card printings for which to generate placeholders, overriding the default.
*   **FR3.3.4:** Users shall be able to customize the information displayed on each placeholder. Customizable elements include:
    *   Card Name
    *   Set Name
    *   Card Number in Set
    *   Rarity
    *   Approximate Price (in user's preferred currency)
    *   Pokémon Species Name
    *   Card Image (Small)
    *   Pokémon Types
    *   HP
    *   Illustrator Name
    *   A small, custom text field for user notes (e.g., "Trade Target," "High Priority").
*   **FR3.3.5:** Users shall be able to choose a template or layout for the placeholders (e.g., "Minimalist Text," "Image Focused," "Data Rich"). The system should provide a few default templates.
*   **FR3.3.6:** Users shall be able to specify the sort order for the generated placeholders. Sorting options shall include:
    *   Release Date (Set, then Card Number)
    *   National Pokédex Number (then Release Date)
    *   Card Name
    *   Set Name (then Card Number)
    *   Rarity
    *   Approximate Price
*   **FR3.3.7:** The system shall generate an image file (e.g., PNG, JPG) or a multi-page PDF containing the customized placeholders. The output should be suitable for printing, with clear divisions for cutting out individual placeholders. Options for multiple placeholders per page (e.g., 3x3 grid for 9 placeholders on an A4/Letter page) and optional cut lines/guides shall be available.
*   **FR3.3.8:** Placeholder dimensions should default to standard Pokémon card size (63mm x 88mm). Users shall be able to input custom dimensions in millimeters or inches.

### 3.4. Search and Filtering

*   **FR3.4.1:** Users shall be able to search the entire card database by:
    *   Pokémon Species Name
    *   Card Name
    *   Set Name
    *   Illustrator Name
    *   National Pokédex Number
*   **FR3.4.2:** Users shall be able to filter search results by:
    *   Set Name
    *   Series Name
    *   Rarity
    *   Card Type
    *   Pokémon Types
    *   Owned/Unowned status
    *   Release Date range
*   **FR3.4.3:** Search results shall display key card information and a small image.

### 3.5. User Account Management (Optional - Phase 2)

*   **FR3.5.1:** Users may be able to create an account to save their collections and preferences. Accounts could be local to the machine or cloud-synced for access across multiple devices.
*   **FR3.5.2:** If accounts are not implemented or for users preferring local data, all user-specific data (collections, preferences stored in Redis under user-specific keys) must be exportable and importable. Export format could be a Redis RDB dump filtered for the user's keys, or more commonly, JSON/CSV generated by querying the user's data via Lua scripts.
*   **FR3.5.3 (If accounts implemented):** A mechanism for password recovery would be required. User PII like email for recovery should be handled with care, potentially hashed or stored separately from main Redis data if necessary for compliance.
*   **FR3.5.4 (If accounts implemented):** Users should be able to export their data (as in FR3.5.2) even if using cloud-synced accounts.

### 3.6. Data Synchronization and Backup (Redis Context)

*   **FR3.6.1:** For local data management (e.g., desktop app running its own Redis instance), users shall be able to explicitly trigger a backup. This could be achieved by Redis's own `BGSAVE` or `SAVE` commands, creating an RDB file. The application would manage these files.
*   **FR3.6.2:** Users shall be able to restore their user-specific data from a backup file. This would involve replacing the current Redis data file (if Redis is stopped) or selectively restoring data if possible (more complex).
*   **FR3.6.3:** If cloud-based user accounts are implemented with a central Redis instance, this instance must have robust backup and restore procedures managed by the service provider (e.g., automated snapshots, point-in-time recovery). Client-side data is simply a view of this central store. Offline modifications would need a client-side queue and conflict resolution strategy upon reconnection if the client also caches data.

### 3.7. Settings/Configuration

User preferences and settings will be stored in Redis, likely within the `user:[user_id]` hash or a dedicated `user:[user_id]:settings` hash.

*   **FR3.7.1:** Preferred currency: Stored as a field in user settings. Conversion logic applied at display time.
*   **FR3.7.2:** Default placeholder settings: Stored as a JSON string or individual fields in user settings.
*   **FR3.7.3:** API update frequency (for the global card database): This is a system-level setting, not user-specific. Manual trigger by an admin user might be possible.
*   **FR3.7.4:** Default language/condition for owned cards: Stored in user settings.

## 4. Non-Functional Requirements

### 4.1. Data Accuracy and Comprehensiveness

*   **NFR4.1.1:** The card data must be as comprehensive and accurate as possible. Initial focus is on official English language TCG printings. This includes standard set releases, common promotional cards (e.g., Prerelease promos, McDonald's collections, cereal promos), and major, widely recognized variants (e.g., "Staff" versions, 1st Edition vs. Unlimited, distinct holo patterns if cataloged by the source API). Japanese or other language printings are a future enhancement.
*   **NFR4.1.2:** The pricing data (`approximate_price_usd`) should be indicative and updated regularly (e.g., daily or weekly from the source). Users must understand this is an approximation and market values can fluctuate rapidly.

### 4.2. Usability

*   **NFR4.2.1:** The application shall be intuitive and easy to navigate for users familiar with Pokémon cards and general software. A brief introductory tutorial or easily accessible help section explaining key features and data points (like how "master set" is defined) should be included.
*   **NFR4.2.2:** UI elements should be clearly labeled, provide good visual feedback to user actions, and maintain consistency throughout the application.
*   **NFR4.2.3:** Placeholder customization should be user-friendly, ideally with a live preview.
*   **NFR4.2.4:** Error handling should be clear and provide actionable information to the user where possible.

### 4.3. Performance

*   **NFR4.3.1:** Database queries (search, filtering, loading master sets) should generally complete within 2-3 seconds for typical datasets.
*   **NFR4.3.2:** Placeholder image generation for a typical master set (e.g., 50-100 placeholders) should complete within 10-30 seconds, depending on complexity and output format. PDF generation might take longer.
*   **NFR4.3.3:** Application startup time should be reasonable (e.g., under 5-10 seconds for a desktop app).

### 4.4. Maintainability

*   **NFR4.4.1:** The codebase shall be well-structured, adhering to relevant language-specific best practices (e.g., Ruby style guides, Rails conventions).
*   **NFR4.4.2:** Code shall be commented appropriately to explain complex logic, data structures, or API interactions.
*   **NFR4.4.3:** An `AGENTS.md` file will be maintained with guidelines for AI-assisted development.
*   **NFR4.4.4:** Configuration (API keys, database paths for local dev) should be externalized from code.

### 4.5. Scalability

*   **NFR4.5.1:** Redis is known for high performance and can handle large datasets if memory is sufficient. The defined keying scheme and use of Lua scripts aim for efficient data retrieval. Data modeling choices (e.g., appropriate use of Hashes vs Sets) are important. The growth to hundreds of thousands of unique printings (card UUIDs) is feasible.
*   **NFR4.5.2:** Redis can handle many concurrent connections. For a web-deployed system, scaling would involve a robust Redis setup (e.g., Sentinel for HA, Cluster for sharding if dataset grows beyond single instance memory) and stateless application servers.

### 4.6. Availability (Redis Context)

*   **NFR4.6.1:** If deployed as a web application using a managed Redis service (e.g., AWS ElastiCache, Azure Cache for Redis), high availability is often a feature of the service. If self-hosting Redis, setup with Redis Sentinel for failover is crucial. For a local desktop application running an embedded or local Redis, availability depends on the stability of the local Redis instance and the application itself.

### 4.7. Security (Redis Context)

*   **NFR4.7.1:** If user accounts are implemented:
    *   Passwords must be hashed securely (e.g., Argon2, scrypt, bcrypt) by the application backend *before* any user data (even a user ID derived from username) is stored or used in Redis keys. Redis itself does not store passwords.
    *   User IDs used in Redis keys should be non-guessable if possible (e.g., UUIDs generated by the application).
*   **NFR4.7.2:** Communication between the application backend and Redis should be secured, especially if Redis is not on localhost. This can involve network ACLs, Redis `requirepass` (password), and potentially TLS/SSL connections if Redis is configured for it and network is untrusted.
*   **NFR4.7.3:** API keys for external services (Pokémon TCG API, currency conversion) must be stored securely in the application backend's configuration, not in Redis or client-side code.
*   **NFR4.7.4:** Redis itself should be protected from unauthorized access (firewall, bind to trusted interfaces, strong password).
*   **NFR4.7.5:** Lua scripts do not inherently add security vulnerabilities if they only operate on data via the provided KEYS and ARGS and do not execute arbitrary commands or access external systems. Care must be taken in script development.

## 5. User Interface (UI) Conceptual Sketch

*(This section provides a high-level idea of the UI. Detailed UI/UX design is a separate activity.)*

*   **Main View/Dashboard:**
    *   Overview of defined master sets and their completion progress (graphical display).
    *   Quick links: "Browse/Search All Cards," "Generate Placeholders," "Manage Master Sets," "Settings."
    *   Summary statistics (total cards owned, collection value).
*   **Card Browser View:**
    *   Prominent search bar and advanced filter panel (collapsible).
    *   Grid or list view of cards (toggleable), showing small image, card name, set name, card number, rarity, owned status.
    *   Clicking a card navigates to the "Card Detail View."
    *   Ability to quick-mark as owned/unowned directly from the list/grid view (for the primary/default copy).
*   **Card Detail View:**
    *   Displays all data attributes from Section 2.1 for the selected card.
    *   Large card image.
    *   Section for managing owned copies:
        *   List of owned copies with their specific attributes (condition, language, price paid).
        *   Button to "Add this card to collection" or "Edit owned copies."
        *   Form to input/edit quantity, condition, language, purchase price/date, notes for an owned copy.
*   **Master Set Management View:**
    *   List of current user-defined master sets.
    *   Option to "Create New Master Set" (prompts for name and Pokémon species selection).
    *   For each master set: display completion stats, links to view cards in the set, generate placeholders for it, edit, or delete.
*   **Placeholder Generation View:**
    *   Step 1: Select Pokémon species or existing master set.
    *   Step 2: Display list of unowned cards (default) or all cards (option) with checkboxes. Ability to select/deselect all.
    *   Step 3: Customization panel:
        *   Choose placeholder template.
        *   Select fields to include (checkboxes based on FR3.3.4).
        *   Set sort order.
        *   Set placeholder dimensions and page layout options (grid size, cut lines).
    *   Live preview of a single sample placeholder that updates as customization options are changed.
    *   "Generate Placeholders" button (initiates file download/creation).
*   **Settings View:**
    *   Tabs for: General (preferred currency, language defaults from user settings in Redis), Data (system-level API update settings, manual admin trigger, backup/restore local Redis RDB file), Placeholder (default placeholder settings from user settings in Redis).

## 6. Technical Stack

This project will be developed as a web application.

### 6.1. Backend Framework

*   **Ruby on Rails:** A web application framework written in Ruby. It follows the MVC (Model-View-Controller) pattern.

### 6.2. Frontend Framework

*   **Hotwire:** An approach to building web applications by sending HTML, instead of JSON, over the wire. This includes:
    *   **Turbo:** For fast page navigation and dynamic updates.
    *   **Stimulus:** A modest JavaScript framework for HTML enhancements.
*   **Tailwind CSS (or other CSS framework):** For styling the application. (To be decided during Rails project generation).

### 6.3. Database

*   **Primary Data Store:** **Redis**. All persistent data including card information, user collections, and settings will be stored in Redis.
    *   For local development: A local Redis instance.
    *   For production: A managed Redis service (e.g., AWS ElastiCache, Azure Cache for Redis, Google Cloud Memorystore) or a self-hosted, highly-available Redis setup (using Sentinel and/or Cluster).
*   **Data Abstraction:** All Redis operations will be performed via **Lua scripts** executed on the Redis server. The Rails application will use a Ruby Redis client (e.g., `redis-rb`) to connect to Redis, load, and execute these Lua scripts.
*   **Secondary Database (Optional):** While Redis is the primary data store, a traditional SQL database (e.g., PostgreSQL, MySQL, SQLite) might be used by Rails for features like user authentication (if using Devise or similar gems that rely on ActiveRecord) or other non-core data. This is secondary to Redis. For the core application data (cards, collections, etc.), Redis remains the exclusive store.

### 6.4. External APIs

*   **Pokémon TCG Data:** `https://pokemontcg.io/` (primary candidate, needs final vetting).
*   **Currency Conversion:** A reliable API for exchange rates if multi-currency support (FR3.7.1) is implemented (e.g., [https://www.exchangerate-api.com/](https://www.exchangerate-api.com/), or similar free/freemium tier).

## 7. Deployment Considerations

The web application can be deployed using various methods:

*   **Containerization:** Using Docker is highly recommended for packaging the Rails application, Redis (if not using a managed service), and any other dependencies. This allows for consistent environments across development, staging, and production.
    *   Docker Compose can be used for local development and simpler multi-container setups.
    *   Kubernetes or similar orchestration platforms for scalable production deployments.
*   **Cloud Platforms:**
    *   **PaaS (Platform as a Service):** Services like Heroku, Render, Fly.io, or AWS Elastic Beanstalk can simplify deployment and management of Rails applications. They often have integrated support or add-ons for Redis.
    *   **IaaS (Infrastructure as a Service):** Deploying on virtual machines (e.g., AWS EC2, Google Compute Engine, Azure VMs) provides more control but requires more manual setup for the Rails server (e.g., Puma, Unicorn), web server (e.g., Nginx), Redis, and deployment pipelines.
*   **Web Server:** A robust web server like Nginx or Apache is typically used in front of the Rails application server (e.g., Puma) to handle static assets, SSL termination, and load balancing.
*   **Background Jobs:** If the application involves background tasks (e.g., fetching data from the Pokémon TCG API, processing images), a background job framework like Sidekiq (which uses Redis) or Good Job will be needed and deployed alongside the web application.

## 8. Glossary

*   **Master Set:** For this project, all unique front printings of a card (as identified by `card_uuid`) for a specific Pokémon species. This includes different artworks, holographic patterns (as per `variant_code`), frame types (as per `frame_code`), promotional stamps, and other distinct visual variations captured by the `card_uuid` definition and supporting attributes.
*   **`card_uuid` (Card Unique Universal Identifier)**: The primary identifier for a unique card printing, with the format `[set_release_number]-[pokedex_number]-[variant_code]-[frame_code]`. See section 2.1 for full details.
*   **Unique Front Printing:** A card that is visually distinguishable from another on its front side, uniquely identified by its `card_uuid`.
*   **Placeholder:** A printable, card-sized image or document containing key information about a Pokémon card (referenced by its `card_uuid`) that a collector is missing from their collection. Used to reserve a spot in a binder.
*   **Variant:** A version of a card that differs from its "standard" printing. Examples: 1st Edition, Shadowless (for Base Set), Staff stamped promos, reverse holos, set-specific stamp promos (e.g., E3 Pikachu).
*   **Reverse Holo:** A card where the holographic pattern is on the body of the card itself, rather than just the artwork box (as in a traditional holo).
*   **TCG API:** Trading Card Game Application Programming Interface. A service that provides programmatic access to card data.
*   **Owned Card Instance:** A specific physical copy of a card in a user's collection, potentially with unique attributes like condition or purchase price.

This document will serve as the foundation for the development of UltrAdex. It will be updated as necessary throughout the project lifecycle.
