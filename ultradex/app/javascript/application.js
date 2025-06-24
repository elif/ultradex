// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers" // For Stimulus controllers

// Example: If you wanted to import Tailwind's base styles, components, and utilities
// This would typically be handled by the tailwindcss-rails gem's installation process
// via `rails tailwindcss:install` which sets up `app/assets/stylesheets/application.tailwind.css`
// and configures PostCSS. For the JS part, Stimulus is the main concern here.

console.log("Hello from application.js");
