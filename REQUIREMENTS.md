# UltrAdex Requirements

## 1. Introduction

UltrAdex is a software tool designed to assist Pokémon card collectors in building "master sets." A master set is defined as every unique front printing of a card for a specific Pokémon species. The tool will maintain a comprehensive database of Pokémon card printings and allow users to track their collections and generate customizable placeholder images for cards they are missing. These placeholders are intended for use in binders.

## 2. Data Requirements

### 2.1. Card Data Attributes

The system shall store the following information for each unique Pokémon card printing:

*   **`card_id`**: A unique identifier for the card printing (e.g., `base1-4` for Base Set Charizard, `swsh9-1` for Brilliant Stars Arceus V). The format typically combines a set identifier with the card's number in that set.
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

*   **Source:** The primary data source will be a reputable Pokémon TCG API. [https://pokemontcg.io/](https://pokemontcg.io/) is the current candidate. Evaluation of its terms of service, data completeness (especially for variants and older sets), accuracy, and update frequency is required.
*   **Updates:** The system should have a mechanism to periodically update its local database from the chosen API. A nightly batch job is recommended, fetching new sets, card data, and price updates. Changed cards will be updated or new ones added.
*   **Local Storage:** A local database will be used. SQLite is suitable for local development and single-user desktop application deployments due to its simplicity. For a potential web application deployment with multiple users, PostgreSQL would be a more robust choice.

### 2.3. User-Specific Collection Data

This data is stored locally or synced if user accounts are implemented.

*   **`user_id`**: Unique identifier for a user (relevant if accounts are implemented, see FR3.5).
*   **`collection_id`**: Unique identifier for a user-defined master set (e.g., "Pikachu Master Set"). Links to `pokemon_species_name` or a list of such names.
*   **`owned_card_instance_id`**: A unique identifier for each specific copy of a card a user owns. This allows tracking multiple copies of the same card printing with different attributes.
*   **`card_id`**: Foreign key linking to the `card_id` in the main card data attributes, identifying the specific printing owned.
*   **`quantity_owned`**: Number of copies of this specific card printing the user owns with these exact attributes (condition, language, etc.). Defaults to 1.
*   **`condition`**: Condition of the owned card (e.g., Enum: "Mint", "Near Mint", "Lightly Played", "Moderately Played", "Heavily Played", "Damaged").
*   **`language_owned`**: Language of the owned card (e.g., "English", "Japanese", "German", "French"). Defaults to "English".
*   **`purchase_price`**: Price paid by the user for the card. Stored in the user's preferred currency (see FR3.7.1).
*   **`purchase_date`**: Date the user acquired the card.
*   **`user_notes_on_owned_card`**: Optional user-specific notes for this owned card (e.g., "Graded PSA 9", "From childhood collection").

## 3. Functional Requirements

### 3.1. Master Set Definition and Management

*   **FR3.1.1:** Users shall be able to define one or more "master sets" they wish to collect.
*   **FR3.1.2:** Defining a master set involves selecting one or more Pokémon species.
*   **FR3.1.3:** The system shall display all known unique printings for the selected Pokémon species when a user is viewing or defining a master set. Users should be able to easily distinguish between different versions (e.g., regular, holo, reverse holo, 1st edition, stamped promos, other variants noted in `notes`) of the same card artwork.

### 3.2. Collection Tracking

*   **FR3.2.1:** For each card printing in the database, users shall be able to mark if they own one or more copies. This involves creating/updating entries in the User-Specific Collection Data (Section 2.3), including details like quantity, condition, language, purchase price, and purchase date.
*   **FR3.2.2:** The system shall visually distinguish between owned and unowned cards when displaying lists of cards (e.g., color coding, icons).
*   **FR3.2.3:** Users shall be able to view statistics for their collection, such as:
    *   Percentage complete for a defined master set (based on unique `card_id`s).
    *   Total number of unique cards owned.
    *   Total number of cards owned (including duplicates).
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
*   **FR3.5.2:** If accounts are not implemented or for users preferring local data, all user-specific data (collections, preferences) must be exportable and importable via local files (e.g., JSON, CSV).
*   **FR3.5.3 (If accounts implemented):** A mechanism for password recovery (e.g., email-based) would be required for cloud-synced accounts.
*   **FR3.5.4 (If accounts implemented):** Users should be able to export their data even if using cloud-synced accounts.

### 3.6. Data Synchronization and Backup

*   **FR3.6.1:** For local data management (no cloud accounts or user preference), users shall be able to explicitly trigger a backup of their entire user-specific data (collections, settings as per Section 2.3 and 3.7) to a single, user-chosen file location.
*   **FR3.6.2:** Users shall be able to restore their user-specific data from a previously created backup file. This will overwrite current user data.
*   **FR3.6.3:** If cloud-based user accounts are implemented (FR3.5), user-specific data shall be automatically synced to a secure cloud backend when an internet connection is available. The system should handle offline modifications gracefully and sync them when connectivity is restored.

### 3.7. Settings/Configuration

*   **FR3.7.1:** Users shall be able to set their preferred currency for displaying prices (e.g., USD, EUR, GBP, JPY). The system will use `approximate_price_usd` as the base and convert it using periodically updated exchange rates. The source for exchange rates needs to be defined (e.g., a free currency conversion API).
*   **FR3.7.2:** Users shall be able to define their default placeholder customization settings (template, information to include, dimensions, etc.).
*   **FR3.7.3:** Users shall be able to manage the frequency of automatic data updates from the external Pokémon TCG API (e.g., daily, weekly, manual only) or trigger a manual update at any time.
*   **FR3.7.4:** Users shall be able to set their default language for owned cards and preferred condition for pricing if the API provides multiple values.

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

*   **NFR4.4.1:** The codebase shall be well-structured, adhering to relevant language-specific best practices (e.g., PEP 8 for Python).
*   **NFR4.4.2:** Code shall be commented appropriately to explain complex logic, data structures, or API interactions.
*   **NFR4.4.3:** An `AGENTS.md` file will be maintained with guidelines for AI-assisted development.
*   **NFR4.4.4:** Configuration (API keys, database paths for local dev) should be externalized from code.

### 4.5. Scalability

*   **NFR4.5.1:** The system must efficiently handle a growing database of cards, potentially tens of thousands to hundreds of thousands of unique printings, as new sets are released over many years.
*   **NFR4.5.2:** If web-deployed, the system should be scalable to handle a moderate number of concurrent users (specifics to be defined if this path is chosen).

### 4.6. Availability

*   **NFR4.6.1:** If deployed as a web application, aim for high availability (e.g., 99.9% uptime). For a local desktop application, this is primarily about application stability and ensuring it runs correctly on supported operating systems.

### 4.7. Security (Primarily if web-deployed or with cloud accounts)

*   **NFR4.7.1:** If user accounts are implemented, passwords must be stored securely (e.g., hashed and salted).
*   **NFR4.7.2:** Communication with any backend API (for user data sync or card data) should use HTTPS.
*   **NFR4.7.3:** API keys for external services must be stored securely and not exposed in client-side code.

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
    *   Tabs for: General (preferred currency, language defaults), Data (API update settings, manual update trigger, backup/restore local data), Placeholder (default placeholder settings).

## 6. Future Considerations (Out of Scope for Initial Version, unless priorities change)

*   Support for multiple languages for card data (Japanese, German, French, etc.).
*   Tracking different card conditions and their respective market prices more granularly from API, if available.
*   Community features: sharing collections (anonymized or public), public wishlists, trading features.
*   Price history tracking and graphing for individual cards and overall collection.
*   Direct integration with collection management platforms (e.g., TCGPlayer inventory, Pokellector).
*   Mobile application (iOS, Android).
*   Support for other TCGs (Magic: The Gathering, Yu-Gi-Oh!, Lorcana).
*   Advanced reporting and analytics on collection data.
*   Barcode scanning for quick card identification (if feasible with available APIs/hardware).

## 7. Technical Stack (Preliminary)

This outlines potential technologies. Final decisions depend on project evolution (e.g., desktop vs. web app).

### 7.1. Frontend

*   **Desktop Application:** Python with a GUI library such as CustomTkinter (modern Tkinter theming), PyQt, or Kivy.
*   **Web Application:** HTML, CSS, JavaScript with a framework like React, Vue, or Svelte.

### 7.2. Backend (primarily for Web Application or Cloud Sync)

*   **Python:** Frameworks like Django (full-featured) or Flask (lightweight) with Django Rest Framework / Flask-RESTful for APIs.
*   **Database Interaction:** SQLAlchemy ORM for Python applications.

### 7.3. Database

*   **Local/Development/Desktop:** SQLite.
*   **Production Web Application:** PostgreSQL or MySQL.

### 7.4. External APIs

*   **Pokémon TCG Data:** `https://pokemontcg.io/` (primary candidate, needs final vetting).
*   **Currency Conversion:** A reliable API for exchange rates if multi-currency support (FR3.7.1) is implemented (e.g., [https://www.exchangerate-api.com/](https://www.exchangerate-api.com/), or similar free/freemium tier).

## 8. Deployment Considerations

### 8.1. Desktop Application

*   Packaging into executable installers for major OS:
    *   **Windows:** PyInstaller, cx_Freeze.
    *   **macOS:** PyInstaller, py2app.
    *   **Linux:** PyInstaller, or distribution through package managers (e.g., Flatpak, Snap).

### 8.2. Web Application

*   Containerization using Docker.
*   Hosted on cloud platforms such as:
    *   PaaS (Platform as a Service): Heroku, Google App Engine, AWS Elastic Beanstalk.
    *   IaaS (Infrastructure as a Service): AWS EC2, Google Compute Engine, Azure VMs (requires more manual setup).
*   Web server (e.g., Gunicorn, Nginx).

## 9. Glossary

*   **Master Set:** For this project, all unique front printings of a card for a specific Pokémon species. This includes different artworks, holographic patterns, promotional stamps, and other distinct visual variations.
*   **Unique Front Printing:** A card that is visually distinguishable from another on its front side. See `notes` in 2.1 and NFR4.1.1 for examples of what this encompasses.
*   **Placeholder:** A printable, card-sized image or document containing key information about a Pokémon card that a collector is missing from their collection. Used to reserve a spot in a binder.
*   **Variant:** A version of a card that differs from its "standard" printing. Examples: 1st Edition, Shadowless (for Base Set), Staff stamped promos, reverse holos, set-specific stamp promos (e.g., E3 Pikachu).
*   **Reverse Holo:** A card where the holographic pattern is on the body of the card itself, rather than just the artwork box (as in a traditional holo).
*   **TCG API:** Trading Card Game Application Programming Interface. A service that provides programmatic access to card data.
*   **Owned Card Instance:** A specific physical copy of a card in a user's collection, potentially with unique attributes like condition or purchase price.

This document will serve as the foundation for the development of UltrAdex. It will be updated as necessary throughout the project lifecycle.
