# UltrAdex Development Environment Setup

Welcome to UltrAdex! This guide will walk you through setting up your local development environment.

## 1. Prerequisites

Before you begin, ensure you have the following:

*   **Git:** For cloning the repository.
*   **A Terminal/Command Line Interface:** For running commands.
*   **A Text Editor or IDE:** For viewing and editing code (e.g., VS Code, RubyMine).

## 2. Core Dependencies

### 2.1. Ruby Version Manager (Recommended)

It's highly recommended to use a Ruby version manager like `rbenv` or `RVM` to manage your Ruby versions. This project uses **Ruby 3.1.2**.

*   **rbenv:**
    *   Installation: [https://github.com/rbenv/rbenv#installation](https://github.com/rbenv/rbenv#installation)
    *   After installing rbenv, install `ruby-build` (plugin for rbenv): [https://github.com/rbenv/ruby-build#installation](https://github.com/rbenv/ruby-build#installation)
    *   Install Ruby 3.1.2:
        ```bash
        rbenv install 3.1.2
        rbenv global 3.1.2 # Or use rbenv local 3.1.2 in the project directory
        ```
*   **RVM:**
    *   Installation: [https://rvm.io/rvm/install](https://rvm.io/rvm/install)
    *   Install Ruby 3.1.2:
        ```bash
        rvm install 3.1.2
        rvm use 3.1.2 --default # Or create a .ruby-version file with "3.1.2" in the project root
        ```
*   Verify your Ruby version:
    ```bash
    ruby -v
    # Should output: ruby 3.1.2...
    ```

### 2.2. Bundler

Bundler manages Ruby gem dependencies.
```bash
gem install bundler
```

### 2.3. Node.js and Yarn (for Rails 7+ Asset Pipeline)

Rails 7 uses Node.js and Yarn to manage JavaScript assets.
*   **Node.js:** Install a recent LTS version. You can use `nvm` (Node Version Manager) or download from [https://nodejs.org/](https://nodejs.org/).
*   **Yarn:** Install via npm (which comes with Node.js):
    ```bash
    npm install --global yarn
    ```

### 2.4. PostgreSQL (Secondary Database)

While Redis Stack is the primary data store for application data, Rails uses PostgreSQL for some internal features and potentially user authentication in the future.

*   **macOS (Homebrew):**
    ```bash
    brew install postgresql
    brew services start postgresql # To start it and have it run on login
    # You might need to create a user matching your system username if it doesn't exist:
    # createuser -s $(whoami)
    ```
*   **Ubuntu/Debian:**
    ```bash
    sudo apt update
    sudo apt install postgresql postgresql-contrib libpq-dev
    sudo systemctl start postgresql
    sudo systemctl enable postgresql # To start on boot
    # Create a PostgreSQL user (replace 'your_username' with your Linux username):
    # sudo -u postgres createuser --interactive --pwprompt your_username
    # Then grant database creation rights:
    # sudo -u postgres psql -c "ALTER USER your_username CREATEDB;"
    ```
*   **Windows:**
    *   Download the installer from [https://www.postgresql.org/download/windows/](https://www.postgresql.org/download/windows/).
    *   Ensure the `bin` directory of your PostgreSQL installation (containing `pg_config`) is in your system's PATH.

### 2.5. Redis Stack (Primary Database)

This is critical for the application. **Redis Stack must be running before you start the Rails application.**

*   **Ubuntu:**
    *   The project includes a script. Run it with sudo:
        ```bash
        sudo bash scripts/install_redis_stack_ubuntu.sh
        ```
    *   This script will install, enable, and start the `redis-stack-server` service.
    *   Verify it's running: `systemctl status redis-stack-server` (should show active/running).
    *   If you need to restart it: `sudo systemctl restart redis-stack-server`.

*   **macOS (Homebrew):**
    *   Follow the official Redis Stack Homebrew instructions: [https://redis.io/docs/getting-started/install-stack/homebrew/](https://redis.io/docs/getting-started/install-stack/homebrew/)
    *   Typically:
        ```bash
        brew tap redis-stack/redis-stack
        brew install redis-stack
        ```
    *   To start Redis Stack server (if not automatically started by brew services):
        ```bash
        redis-stack-server --daemonize yes # Run as a background daemon
        # Or, to run in foreground (useful for seeing logs):
        # redis-stack-server
        ```
    *   You can also use `brew services start redis-stack` to have it managed by Homebrew services.

*   **Windows (Docker - Recommended):**
    *   Install Docker Desktop for Windows: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
    *   Run Redis Stack using Docker:
        ```bash
        docker run -d --name redis-stack -p 6379:6379 -p 8001:8001 redis/redis-stack:latest
        ```
    *   This command downloads the latest Redis Stack image, starts a container named `redis-stack`, and maps the necessary ports. Port `6379` is for Redis, and `8001` is for RedisInsight (optional web UI).
    *   To stop: `docker stop redis-stack`
    *   To start again: `docker start redis-stack`
    *   To view logs: `docker logs redis-stack`

*   **Other Linux Distributions / Manual Docker:**
    *   Refer to the official Redis Stack installation guide: [https://redis.io/docs/getting-started/install-stack/](https://redis.io/docs/getting-started/install-stack/)

*   **Verify Redis is Running:**
    *   Regardless of your OS, you can test if Redis is running by using `redis-cli`:
        ```bash
        redis-cli ping
        # Expected output: PONG
        ```
    *   If `redis-cli` is not in your PATH, it's often bundled with Redis Stack installations or can be installed separately (`sudo apt install redis-tools` on Ubuntu).

## 3. Project Setup

1.  **Clone the Repository:**
    ```bash
    git clone <repository_url> # Replace <repository_url> with the actual Git URL
    cd ultradex
    ```
    If you're Steve, the repository is likely already cloned for you. Navigate to the `ultradex` directory inside the project.

2.  **Set Local Ruby Version (if using rbenv/RVM and haven't set global):**
    *   If using `rbenv`:
        ```bash
        rbenv local 3.1.2
        ```
    *   If using `RVM` and no `.ruby-version` file exists, RVM might pick it up automatically if you `cd` out and back into the directory, or you can create a `.ruby-version` file containing `3.1.2`.

3.  **Install Gem Dependencies:**
    ```bash
    bundle install
    ```
    *   **Troubleshooting `pg` gem installation:**
        *   If you see errors related to `pg_config` or missing PostgreSQL headers:
            *   **macOS/Linux:** Ensure `libpq-dev` (Ubuntu) or `postgresql` (Homebrew) is installed. Make sure `pg_config` is in your PATH.
            *   **Windows:** Ensure the `bin` directory of your PostgreSQL installation is in your PATH. You might need to specify the path during gem installation if it still fails:
                `gem install pg -- --with-pg-config="C:/path/to/your/PostgreSQL/version/bin/pg_config.exe"` (Adjust the path accordingly).

4.  **Install JavaScript Dependencies:**
    ```bash
    yarn install
    ```

5.  **Set up Rails Databases (PostgreSQL):**
    This will create the development and test databases defined in `config/database.yml`.
    ```bash
    bin/rails db:setup
    ```
    This command typically runs `db:create`, `db:schema:load` (or `db:migrate`), and `db:seed`.

## 4. Running the Application

1.  **Ensure Redis Stack is Running!**
    *   This is crucial. If Redis Stack is not running or accessible, the application will fail to load Lua scripts and will not function correctly.
    *   Verify with `redis-cli ping` (should return `PONG`).

2.  **Start the Rails Server:**
    ```bash
    bin/rails server
    # Or shorter:
    # ./bin/rails s
    ```

3.  **Access the Application:**
    *   Open your web browser and go to `http://localhost:3000`.

4.  **Confirm Lua Scripts Loaded:**
    *   When the Rails server starts, you should see messages in the server log (your terminal) indicating that Lua scripts were loaded. Look for lines like:
        `Loaded Lua script: add_card (SHA: ...)`
        `Lua scripts loading process initiated by RedisScripts module.`
    *   If you see errors related to Redis connection or script loading, double-check that Redis Stack is running and accessible at `redis://localhost:6379`.

## 5. Running Tests

The project uses RSpec for testing.

### 5.1. Full Test Suite

1.  **Ensure Redis Stack is running.** (See Section 2.5)
2.  **Ensure your test database (PostgreSQL) is set up:**
    *   `bin/rails db:test:prepare`
    (This command ensures your test database schema is up to date. It's good practice to run it before testing if you've made migration changes.)

3.  **Run RSpec:**
    ```bash
    bundle exec rspec
    ```
    Or to run a specific file:
    ```bash
    bundle exec rspec spec/models/card_spec.rb
    ```

### 5.2. Selected Unit Test Script (Quick Checks)

For quick checks, especially for core model logic without running the full RSpec suite or if you suspect issues with the broader Rails environment loading, a custom script is provided. This script can run a subset of tests.

**Script Location:** `scripts/run_selected_unit_tests.rb`

**Purpose:**
*   Allows running pure Ruby unit tests (e.g., for UUID logic in the Card model) without needing Redis or full Rails boot.
*   Allows running specific model tests (e.g., `card_spec.rb`) that do interact with Redis, but with a more controlled, minimal Rails environment setup by the script itself.

**Prerequisites:**
*   Ensure gem dependencies are installed: `bundle install`

**How to Run:**

Make the script executable (if not already):
```bash
chmod +x scripts/run_selected_unit_tests.rb
```

Execute the script from the project root (`ultradex` directory):
```bash
./scripts/run_selected_unit_tests.rb [options]
```

**Available Options:**

*   `-l LEVEL`, `--level LEVEL`: Specifies the test level to run.
    *   `uuid`: Runs only the pure Ruby UUID helper tests from the Card model. Does *not* require Redis or a full Rails boot. This is a very basic sanity check.
        ```bash
        ./scripts/run_selected_unit_tests.rb --level uuid
        ```
    *   `check-redis-setup`: Connects to Redis and attempts to load Lua scripts, but does not run any RSpec tests. Useful for verifying Redis connectivity and script loading independently. Requires Redis.
        ```bash
        ./scripts/run_selected_unit_tests.rb --level check-redis-setup
        ```
    *   `card-redis`: (Default if no level is specified) Runs a tagged subset of core Redis operation tests from `spec/models/card_spec.rb`. This level *requires* Redis Stack to be running and accessible.
        ```bash
        ./scripts/run_selected_unit_tests.rb --level card-redis
        # Or simply:
        # ./scripts/run_selected_unit_tests.rb
        ```
    *   `all-card`: Runs all tests in `spec/models/card_spec.rb`. Requires Redis.
        ```bash
        ./scripts/run_selected_unit_tests.rb --level all-card
        ```
*   `-r URL`, `--redis-url URL`: Specify the Redis URL if it's not the default (`redis://localhost:6379/0` or `ENV['REDIS_URL']`).
    ```bash
    ./scripts/run_selected_unit_tests.rb --redis-url redis://localhost:6380/1
    ```
*   `-f FORMATTER`, `--format FORMATTER`: Specify the RSpec formatter (e.g., `documentation`, `progress`). Default is `documentation`.
    ```bash
    ./scripts/run_selected_unit_tests.rb --format progress
    ```
*   `-v`, `--[no-]verbose`: Enable verbose output from the script itself (not RSpec's verbosity).
*   `-h`, `--help`: Show help message with all options.

**Example Usage:**

*   Run only UUID tests:
    ```bash
    ./scripts/run_selected_unit_tests.rb -l uuid
    ```
*   Run Card model tests (requires Redis):
    ```bash
    ./scripts/run_selected_unit_tests.rb
    ```
*   Run Card model tests with a specific Redis instance and verbose script output:
    ```bash
    ./scripts/run_selected_unit_tests.rb -r redis://mycustom.redis:1234/0 -v
    ```

**Note:** The `card-redis` and `all-card` levels attempt to run RSpec tests by loading parts of the Rails environment. If these tests fail, it could be due to the test logic itself or issues with how the script sets up the minimal environment for RSpec. For definitive test results, especially if encountering discrepancies, always rely on the full `bundle exec rspec` suite. This script is primarily a development and quick diagnostic tool.

## Common Issues & Troubleshooting

*   **"Redis::CannotConnectError" / "Failed to connect to Redis":**
    *   Ensure Redis Stack server is running. Use `redis-cli ping`.
    *   Check the `REDIS_URL` environment variable if you've set one (defaults to `redis://localhost:6379/0`).
    *   Check firewall settings if Redis is running on a different machine or in Docker with incorrect port mapping.
*   **`pg` gem installation fails:** See "Troubleshooting `pg` gem installation" in section 3.
*   **Ruby version errors:** Ensure you are using Ruby 3.1.2 (check with `ruby -v`). Use `rbenv` or `RVM`.
*   **Yarn/Node errors:** Ensure Node.js and Yarn are installed correctly.

If you encounter other issues, please provide the full error message and steps you took. Good luck!
```
