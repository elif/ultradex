# UltrAdex - Pokémon Card Master Set Organizer

UltrAdex is a tool designed to help Pokémon TCG collectors organize and track their progress towards completing "master sets." A master set, for the purpose of this tool, is defined as every unique front printing of a card for a specific Pokémon species.

## Key Features (Planned)

*   **Comprehensive Card Database:** Access to data for a vast number of Pokémon card printings.
*   **Master Set Definition:** Define the Pokémon species you aim to collect.
*   **Collection Tracking:** Mark the cards you own and see your completion progress.
*   **Customizable Placeholders:** Generate printable placeholders for cards you're missing, tailored with the information you want to see (e.g., card image, set name, number, price). These are perfect for organizing your binders.
*   **Search & Filtering:** Easily find specific cards or browse through sets.

## Project Status

This project is currently in the planning and requirements definition phase.

## Getting Started

This section provides basic instructions for setting up and running the UltrAdex project locally for development.

### Prerequisites

*   **Ruby:** Ensure you have a recent version of Ruby installed (e.g., via rbenv, RVM). Refer to the project's `.ruby-version` file (if present) or Gemfile for specific version compatibility.
*   **Bundler:** Install the Bundler gem: `gem install bundler`.
*   **Redis Stack:** This project uses Redis Stack to leverage its advanced features like RedisJSON and Redis Search. Redis Stack must be installed and running.
    *   **Ubuntu:** A script is provided to simplify installation on Ubuntu: `scripts/install_redis_stack_ubuntu.sh`. Execute it with `bash scripts/install_redis_stack_ubuntu.sh`.
    *   **Other Systems (macOS, Docker, etc.):** Please refer to the official Redis Stack documentation for installation instructions: [https://redis.io/docs/getting-started/install-stack/](https://redis.io/docs/getting-started/install-stack/)
*   **Node.js & Yarn (for Rails 7+ with Hotwire/esbuild):** Ensure Node.js and Yarn are installed if managing JavaScript assets with jsbundling-rails or similar.

### Local Development Setup

1.  **Clone the Repository:**
    ```bash
    git clone <repository_url>
    cd ultradex
    ```
2.  **Install Dependencies:**
    ```bash
    bundle install
    # If applicable for JS:
    # yarn install
    ```
3.  **Ensure Redis Stack is Running:** Start your local Redis Stack server if it's not already running. The default connection is usually `redis://localhost:6379`.
4.  **Database Setup (if applicable for Rails):**
    While Redis Stack is the primary data store for application data, if a relational database is used for other Rails purposes (like user accounts via Devise), you might need to run:
    ```bash
    # rails db:create
    # rails db:migrate
    ```
    Refer to `config/database.yml`.
5.  **Load Lua Scripts into Redis:**
    The application should handle loading necessary Lua scripts into Redis on startup or via a rake task. (Details to be added, e.g., `rails redis:load_scripts`)
6.  **Run the Rails Server:**
    ```bash
    bin/rails server
    ```
    You should then be able to access the application at `http://localhost:3000`.

## Documentation

*   **Requirements:** For a significantly expanded and detailed breakdown of all planned features, data models, technical specifications, and design considerations, please see [REQUIREMENTS.md](REQUIREMENTS.md). This document has been updated to reflect a richer feature set.

## Data Architecture Overview

UltrAdex will utilize **Redis** as its exclusive data store for all information, including the comprehensive card database and user-specific collection data. Access to Redis will be managed through a layer of Lua scripts, ensuring data integrity and controlled operations.

### Card Identification (UUID)

A specific UUID (Unique Universal Identifier) format is defined for each unique card printing:
`[set_release_number]-[pokedex_number]-[variant_code]-[frame_code]`

*   **`set_release_number`**: Chronological identifier for the set's release.
*   **`pokedex_number`**: The Pokémon's National Pokédex number.
*   **`variant_code`**: A letter indicating print style (Normal, Holo, Reverse Holo, Other).
    *   `N`: Normal, `H`: Holofoil, `R`: Reverse Holofoil, `O`: Other.
*   **`frame_code`**: A letter indicating artwork frame type (Standard, Full Art, Special Art, Jumbo).
    *   `S`: Standard, `F`: Full Art, `A`: Special Art, `J`: Jumbo.

This structured UUID allows for precise identification and efficient querying of card data stored in Redis. For detailed Redis data structures, keying schemes, and Lua script specifications, please refer to the `REQUIREMENTS.md` and `AGENTS.md` documents.

## Contributing

Details on how to contribute will be added once the initial framework is in place.

*(This README will be updated as the project progresses.)*
