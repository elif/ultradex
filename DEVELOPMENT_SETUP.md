# UltrAdex Development Environment Setup (Docker-Based)

Welcome to UltrAdex! This guide walks you through setting up and using the Docker-based development environment. This is the recommended way to work on the project as it ensures consistency and includes all necessary services.

## 1. Prerequisites

*   **Git:** For cloning the repository.
    *   Installation: [https://git-scm.com/book/en/v2/Getting-Started-Installing-Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
*   **Docker and Docker Compose:**
    *   **Docker Desktop (Windows/macOS):** The easiest way is to install Docker Desktop, which includes Docker Compose.
        *   Download: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
    *   **Linux:** Install Docker Engine and Docker Compose plugin separately.
        *   Docker Engine: [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/) (select your distribution)
        *   Docker Compose Plugin: [https://docs.docker.com/compose/install/linux/](https://docs.docker.com/compose/install/linux/) (recommended way to get `docker compose`)
    *   Ensure Docker is running after installation.
    *   **Note on Docker Compose command:** This guide uses `docker compose` (with a space), which is the current standard syntax for the Docker Compose CLI plugin. Older `docker-compose` (with a hyphen) syntax might still work if you have an older version installed, but `docker compose` is preferred.

## 2. Getting Started

1.  **Clone the Repository:**
    Navigate to where you want to store the project and clone it:
    ```bash
    git clone <repository_url> # Replace <repository_url> with the actual Git URL
    cd ultradex
    ```
    *(The project files, including `Dockerfile` and `docker-compose.yml`, are located within the `ultradex` directory of the repository.)*

2.  **Build and Start the Docker Environment:**
    From the root of the `ultradex` project directory (where `docker-compose.yml` is located), run:
    ```bash
    docker compose up --build
    ```
    *   `--build`: This flag tells Docker Compose to build the `app` image from the `Dockerfile` before starting the services. You only strictly need this the first time or when you make changes to the `Dockerfile` or files it depends on (like `Gemfile`).
    *   This command will:
        *   Build the custom Docker image for the application (which includes Ruby, Node.js, Yarn, system dependencies, and Redis Stack).
        *   Start the `app` service (running Rails and Redis Stack).
        *   Start the `db` service (PostgreSQL).
        *   Display logs from all services in your terminal.
    *   The first build can take some time as it downloads base images and installs all dependencies. Subsequent starts will be much faster.

    To run in detached mode (in the background):
    ```bash
    docker compose up -d --build
    ```
    You can then view logs with `docker compose logs -f` or `docker compose logs app` / `docker compose logs db`.

3.  **Initial Application Setup (First Time Only):**
    Once the containers are up and running (especially `db` which has a healthcheck), you'll need to set up the database for the Rails application. Open a new terminal window/tab, navigate to the `ultradex` project directory, and run:
    ```bash
    docker compose exec app bin/rails db:setup
    ```
    *   This command executes `bin/rails db:setup` *inside* the `app` container.
    *   It will create the development and test databases, load the schema, and run seeds (if any).

    If you need to run migrations later:
    ```bash
    docker compose exec app bin/rails db:migrate
    ```

## 3. Common Development Tasks (Inside Docker)

All Rails, Rake, Bundler, and Yarn commands should be executed *inside* the `app` Docker container using `docker compose exec app <command>`.

*   **Accessing Rails Console:**
    ```bash
    docker compose exec app bin/rails c
    ```

*   **Running RSpec Tests:**
    *   Ensure the test database is prepared:
        ```bash
        docker compose exec app bin/rails db:test:prepare
        ```
    *   Run all tests:
        ```bash
        docker compose exec app bundle exec rspec
        ```
    *   Run a specific test file:
        ```bash
        docker compose exec app bundle exec rspec spec/models/card_spec.rb
        ```

*   **Installing/Updating Gems:**
    1.  Modify your `Gemfile` locally.
    2.  Run bundler inside the container:
        ```bash
        docker compose exec app bundle install
        ```
    *   If `bundle install` fails or you change system dependencies in the `Dockerfile`, you might need to rebuild the image: `docker compose build app` (or `docker compose up --build`).

*   **Installing/Updating Yarn Packages:**
    1.  Modify `package.json` locally.
    2.  Run Yarn inside the container:
        ```bash
        docker compose exec app yarn install
        ```

*   **Viewing Logs:**
    *   If running `docker compose up` in the foreground, logs are streamed to your terminal.
    *   If running in detached mode (`-d`):
        ```bash
        docker compose logs -f          # Follow logs from all services
        docker compose logs app       # Logs for the app service
        docker compose logs db        # Logs for the db service
        ```

*   **Stopping the Environment:**
    *   If running in the foreground, press `Ctrl+C` in the terminal where `docker compose up` is running.
    *   If running in detached mode, or from another terminal:
        ```bash
        docker compose down
        ```
        This stops and removes the containers. Add `-v` to also remove named volumes (`postgres_data`, `bundle_cache`) if you want a completely clean slate (caution: this deletes your database data).

## 4. Accessing the Application

*   **Web Application:** Once the `app` service is running (after `docker compose up`), you can access the Rails application in your browser at:
    [http://localhost:3000](http://localhost:3000)

*   **Redis (RedisInsight):** The `redis/redis-stack` base image also exposes RedisInsight on port `8001` by default. Since our `app` container (which includes Redis Stack) forwards port `6379` but not `8001` in the `docker-compose.yml`, RedisInsight won't be directly accessible from the host via the `app` service's port mappings.
    *   To access RedisInsight, you could add `8001:8001` to the `app` service's ports in `docker-compose.yml` if needed.
    *   Alternatively, connect to Redis on `localhost:6379` using any Redis client from your host machine.

*   **PostgreSQL Database:** If you added `- "5432:5432"` to the `db` service's ports in `docker-compose.yml` (it is included by default), you can connect to the PostgreSQL database from your host machine using a GUI tool (like pgAdmin, DBeaver) or `psql`:
    *   Host: `localhost`
    *   Port: `5432`
    *   User: `ultradex_user` (defined in `docker-compose.yml`)
    *   Password: `ultradex_password` (defined in `docker-compose.yml`)
    *   Database: `ultradex_development` (defined in `docker-compose.yml`)

## 5. Troubleshooting

*   **Port Conflicts:** If `localhost:3000` or `localhost:5432` are already in use on your host machine, Docker Compose will fail to start the services. Stop the conflicting service or change the host-side port mapping in `docker-compose.yml` (e.g., `"3001:3000"`).
*   **Build Failures:** Check the output of `docker compose up --build` carefully. Errors during `bundle install` or system package installation will be shown there.
*   **"Error response from daemon: driver failed programming external connectivity..."**: Often means the port is already in use.
*   **Slow Performance (macOS/Windows with many files):** File system synchronization between the host and Docker container can sometimes be slow if the application involves a very large number of files being actively watched or accessed. Ensure `.dockerignore` is comprehensive.
*   **Permissions Issues:** The `Dockerfile` (and `docker-compose.yml` volume mounts) are set up to use an `appuser`. If you encounter permission errors inside the container, ensure file ownership and permissions are correct. The `bundle_cache` is defined as a named volume, which helps avoid some host permission issues.
*   **Redis Not Starting:** Check logs using `docker compose logs app`. The entrypoint script (`docker-entrypoint.sh`) attempts to start Redis and includes checks. Logs from Redis itself are in `/var/log/redis-stack.log` inside the `app` container.
*   **Database Connection Issues:**
    *   Ensure the `db` service is healthy (`docker compose ps`).
    *   Verify `DATABASE_URL` in the `app` service environment variables (in `docker-compose.yml`) matches the `db` service's PostgreSQL credentials and service name (`db`).

This Dockerized setup should provide a consistent and isolated development environment for everyone working on UltrAdex.
```
