require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ultradex
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.eager_load_paths << Rails.root.join("lib")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Redis configuration for caching (can be expanded for other uses)
    config.cache_store = :redis_cache_store, { url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' }, namespace: "cache" }

  end
end
