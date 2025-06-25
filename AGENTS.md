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

*   **Language:** This is a ruby/rails 7 project using hotwire ux and redis backend. The only language other than ruby is lua for redis stored procedures.
*   **Formatting:** strict adherance to ruby idioms like DRY, principle of least surprise, code should read like english. do not include extra syntax if it is not needed (like optional parenthesis)
*   **Naming Conventions:** Use natural language names for variables, functions, and classes (e.g., `get_card_details` instead of `gcd()`).
*   **Modularity:** Strive for clear object encapsulation. Even where it results in small files, maintain object oriented principles and separate object domain functionality in a consistent manner.

## File and Project Structure

*   Keep the project organized. New files should be placed in logical directories consistent with rails paradigms.
*   Refer to `REQUIREMENTS.md` for the planned data schema and features.

## Specific Tool Usage

*   When modifying existing files, use `replace_with_git_merge_diff` for targeted changes.
*   Use `overwrite_file_with_block` only when replacing an entire file's content is intended and appropriate.
*   Use `create_file_with_block` for new files.
*   Commit messages for `submit` must be plain text, maximum 30 words, with no special formatting.

## Working with the Dockerized Environment

This project uses Docker and Docker Compose for its development environment. This ensures all services (Rails app, PostgreSQL database, Redis) are running consistently.

*   **Executing Commands:** Most development tasks that involve running commands (e.g., Rails generators, Rake tasks, `bundle install`, `yarn install`, RSpec tests) must be executed *inside* the application container. The primary service is named `app`.
    *   Use `docker compose exec app <your_command_here>`. For example:
        *   `docker compose exec app bin/rails g model User name:string`
        *   `docker compose exec app bundle exec rspec`
        *   `docker compose exec app rake db:migrate`
    *   Remember that the `run_in_bash_session` tool in your environment executes commands on a host that *can run* Docker commands, but is not necessarily *inside* the container. Your `run_in_bash_session` commands should be prefixed with `sudo docker compose exec app ...` if they need to run within the Rails application's context. The working directory for `run_in_bash_session` is `/app/ultradex/` (the directory containing `docker-compose.yml`).

*   **Service Management:**
    *   To start all services: `sudo docker compose up -d` (from the `ultradex/` directory).
    *   To stop all services: `sudo docker compose down` (from the `ultradex/` directory).
    *   To view logs: `sudo docker compose logs -f app` or `sudo docker compose logs db`.

*   **Modifying Docker Configuration:**
    *   If you need to modify `Dockerfile`, `docker-compose.yml`, `docker-entrypoint.sh`, or other files crucial to the Docker setup, these changes must be carefully tested.
    *   After such changes, attempt to rebuild the relevant image (e.g., `sudo docker compose build app`) and then restart the services (`sudo docker compose up -d`) to ensure everything still works correctly.
    *   The environmental disk space issue you (Jules) encountered previously might prevent these commands from running successfully in the current sandbox. Report this if it occurs.

*   **Refer to Documentation:** For comprehensive instructions on setting up, running, and managing the Docker environment, please consult the `DEVELOPMENT_SETUP.md` file in the repository root.

*   **`Gemfile.lock`:** Ensure `ultradex/Gemfile.lock` is kept up-to-date and is consistent with `ultradex/Gemfile`. If you modify `ultradex/Gemfile`, you should run `sudo docker compose exec app bundle install` to update the lock file, and then ensure the updated `ultradex/Gemfile.lock` is part of your changes.

By following these guidelines, AI agents can contribute effectively and help build a high-quality UltrAdex application.
