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

## Future AI Agent Instructions

*   (This section will be updated with more specific instructions as the project evolves, e.g., database interaction protocols, API usage guidelines, UI component standards.)

By following these guidelines, AI agents can contribute effectively and help build a high-quality UltrAdex application.
