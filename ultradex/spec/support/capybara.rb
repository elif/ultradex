# spec/support/capybara.rb
require 'capybara/rspec'

# This file is not strictly necessary if all Capybara config is in rails_helper.rb,
# but it's good practice to have it for larger configurations.

# You can configure Capybara settings here, for example:
# Capybara.default_driver = :selenium_chrome_headless
# Capybara.javascript_driver = :selenium_chrome_headless
# Capybara.server = :puma, { Silent: true } # To silence Puma STDOUT in tests

# If using Webdrivers gem, you can specify browser versions if needed:
# Webdrivers::Chromedriver.required_version = '114.0.5735.90' # Example

# Make sure this file is required by `rails_helper.rb`.
# The line `Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }`
# in `rails_helper.rb` should take care of this.

RSpec.configure do |config|
  # Additional Capybara related configurations can go here.
  # For example, if you want to ensure a clean state for certain test types:
  # config.before(:each, type: :system) do
  #   # Code to reset application state if needed
  # end
end
