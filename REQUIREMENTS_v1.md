# UltrAdex Requirements

## 1. Introduction

UltrAdex is a software tool designed to assist Pokémon card collectors in building "master sets." A master set is defined as every unique front printing of a card for a specific Pokémon species. The tool will maintain a comprehensive database of Pokémon card printings and allow users to track their collections and generate customizable placeholder images for cards they are missing. These placeholders are intended for use in binders.

## 2. Data Requirements

### 2.1. Card Data Attributes

The system shall store the following information for each unique Pokémon card printing in Redis:

*   **`card_uuid`**: A unique identifier for each distinct card printing. The format is: `[set_release_number]-[pokedex_number]-[variant_code]-[frame_code]`
    *   **`set_release_number`**: Chronological number for the set's release.
    *   **`pokedex_number`**: National Pokédex number (e.g., `025`).
    *   **`variant_code`**: Single letter for print style:
        *   `N`: Normal
        *   `H`: Holofoil
        *   `R`: Reverse Holofoil
        *   `O`: Other
    *   **`frame_code`**: Single letter for artwork frame type:
        *   `S`: Standard Frame
        *   `F`: Full Art Frame
        *   `A`: Alternate/Special Art Frame
        *   `J`: Jumbo Card
    *   This `card_uuid` is the primary key for cards.
*   **`original_set_id`**: Original set identifier from source API (e.g., `base1`).
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
*   **`approximate_price_usd`**: An estimated market price of the card in USD. This should be updated periodically. Consider different conditions (e.g., Near Mint, Lightly Played) if feasible, or standardize on one (e.g., Near Mint).
*   **`notes`**: Optional field for any additional relevant information about a specific printing (e.g., "Staff Prerelease", "1st Edition").

### 2.2. Data Source and Management (Redis Focus)

*   **Source:** The primary data source will be a reputable Pokémon TCG API (e.g., [https://pokemontcg.io/](https://pokemontcg.io/)). Data fetched will be processed and stored in Redis.
*   **Updates:** The system should periodically update its Redis database from the API. This involves generating `card_uuid`s for new entries.
*   **Data Storage:** Exclusively **Redis**. All card data, user collections, etc., will reside in Redis.

### 2.3. Redis Data Structures and Keying Scheme (Simplified Overview)

(For a detailed breakdown, refer to the main `REQUIREMENTS.md` document.)

*   **Card Details**: Redis Hashes. Key: `card:[card_uuid]`. Fields include all attributes from 2.1.
*   **Set Information**: Redis Hashes. Key: `set:[original_set_id]`. Fields: `set_name`, `release_number`, etc.
*   **Global Set Release Counter**: Redis Integer. Key: `global:next_set_release_number`.
*   **Indexes (Redis Sets)**:
    *   `idx:pokemon_cards:[pokedex_number]` (Members: `card_uuid`s)
    *   `idx:set_cards:[original_set_id]` (Members: `card_uuid`s)
*   **User Data (if implemented)**:
    *   User Collections: e.g., `user:[user_id]:collection_cards:[collection_slug]` (Set of `card_uuid`s).
    *   Owned Instances: e.g., `user:[user_id]:owned_instance:[card_uuid]:[instance_id]` (Hash of details: condition, price).

### 2.4. Data Abstraction Layer (Redis Lua Scripts)

All Redis interactions must be through Lua scripts. Examples:
*   `add_card(uuid, data_json)`
*   `get_card(uuid)`
*   `add_card_to_collection(user_id, collection_slug, card_uuid)`
*   `get_collection_cards(user_id, collection_slug)`

(Refer to `REQUIREMENTS.md` for a more comprehensive list of scripts and detailed structures).

## 3. Functional Requirements

### 3.1. Master Set Definition and Management

*   **FR3.1.1:** Users shall be able to define one or more "master sets" they wish to collect.
*   **FR3.1.2:** Defining a master set involves selecting one or more Pokémon species.
*   **FR3.1.3:** The system shall display all known unique printings for the selected Pokémon species when a user is viewing or defining a master set.

### 3.2. Collection Tracking

*   **FR3.2.1:** For each card printing (identified by `card_uuid`), users shall be able to mark if they own one or more copies by creating `owned_instance` records in Redis.
*   **FR3.2.2:** The system shall visually distinguish between owned and unowned `card_uuid`s.
*   **FR3.2.3:** Users shall be able to view statistics for their collection (e.g., percentage complete for a master set based on `card_uuid`s in their collection set vs. all `card_uuid`s for that Pokémon).

### 3.3. Placeholder Generation

*   **FR3.3.1:** Users shall be able to select a Pokémon species (or a defined master set) to generate placeholders for.
*   **FR3.3.2:** By default, placeholders will be generated for cards the user has marked as unowned for the selected species/master set.
*   **FR3.3.3:** Users shall be able to manually select or deselect specific card printings for which to generate placeholders, overriding the default.
*   **FR3.3.4:** Users shall be able to customize the information displayed on each placeholder. Customizable elements include:
    *   Card Name
    *   Set Name
    *   Card Number in Set
    *   Rarity
    *   Approximate Price
    *   Pokémon Species Name
    *   Card Image (Small)
*   **FR3.3.5:** Users shall be able to choose a template or layout for the placeholders.
*   **FR3.3.6:** Users shall be able to specify the sort order for the generated placeholders. Sorting options shall include:
    *   Release Date (Set, then Card Number)
    *   National Pokédex Number (then Release Date)
    *   Card Name
    *   Set Name (then Card Number)
    *   Rarity
    *   Approximate Price
*   **FR3.3.7:** The system shall generate an image file (e.g., PNG, JPG) or a multi-page PDF containing the customized placeholders. The output should be suitable for printing, with clear divisions for cutting out individual placeholders.
*   **FR3.3.8:** Placeholder dimensions should be standard trading card size (approx. 2.5 x 3.5 inches or 63x88mm) or configurable by the user.

### 3.4. Search and Filtering

*   **FR3.4.1:** Users shall be able to search the entire card database by:
    *   Pokémon Species Name
    *   Card Name
    *   Set Name
    *   Illustrator Name
*   **FR3.4.2:** Users shall be able to filter search results by:
    *   Set Name
    *   Series Name
    *   Rarity
    *   Card Type
    *   Pokémon Types
    *   Owned/Unowned status
*   **FR3.4.3:** Search results shall display key card information and a small image.

### 3.5. User Account Management (Optional - Phase 2)

*   **FR3.5.1:** Users may be able to create an account to save their collections and preferences.
*   **FR3.5.2:** Data (user collections, preferences from Redis) should be exportable/importable (e.g., JSON) if accounts are not implemented or for backup.

## 4. Non-Functional Requirements

### 4.1. Data Accuracy and Comprehensiveness (Stored in Redis)

*   **NFR4.1.1:** The card data must be as comprehensive and accurate as possible, reflecting all official English printings. Consideration for Japanese or other language printings could be a future enhancement.
*   **NFR4.1.2:** The pricing data should be indicative and updated regularly, but users should understand it's an approximation.

### 4.2. Usability

*   **NFR4.2.1:** The application shall be intuitive and easy to navigate for users familiar with Pokémon cards.
*   **NFR4.2.2:** UI elements should be clearly labeled and provide good feedback to user actions.
*   **NFR4.2.3:** Placeholder customization should be user-friendly.

### 4.3. Performance

*   **NFR4.3.1:** Database queries (search, filtering, loading master sets) should complete within 2-3 seconds.
*   **NFR4.3.2:** Placeholder image generation for a typical master set (e.g., 50-100 placeholders) should complete within 10-20 seconds.

### 4.4. Maintainability

*   **NFR4.4.1:** The codebase shall be well-structured, following good programming practices.
*   **NFR4.4.2:** Code shall be commented where necessary to explain complex logic.
*   **NFR4.4.3:** An `AGENTS.md` file will be maintained with guidelines for AI-assisted development.

### 4.5. Scalability

*   **NFR4.5.1:** The system should be able to handle a growing database of cards as new sets are released (tens of thousands of entries).

### 4.6. Availability

*   **NFR4.6.1:** If deployed as a web application, aim for high availability. For a local application, this is less critical.

## 5. User Interface (UI) Conceptual Sketch

*(This section provides a high-level idea of the UI. Detailed UI/UX design is a separate activity.)*

*   **Main View/Dashboard:**
    *   Overview of defined master sets and their completion progress.
    *   Quick links to "Browse Cards," "Generate Placeholders," "Manage Master Sets."
*   **Card Browser View:**
    *   Search bar and filter options.
    *   Grid or list view of cards with images and key details.
    *   Ability to click a card to see more details and mark as owned/unowned.
*   **Master Set Management View:**
    *   List of current master sets.
    *   Option to create a new master set (select Pokémon species).
    *   Option to edit or delete existing master sets.
*   **Placeholder Generation View:**
    *   Select Pokémon species or master set.
    *   List of unowned cards with checkboxes.
    *   Customization panel for placeholder content and appearance.
    *   Sort order selection.
    *   "Generate" button.
    *   Preview of a sample placeholder.

This document outlines an earlier version of requirements. For the most current and detailed specifications, including the definitive Redis data model and Lua script designs, please refer to `REQUIREMENTS.md`.
