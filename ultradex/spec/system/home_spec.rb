require 'rails_helper'

RSpec.describe "HomePage Smoke Test", type: :system do
  before do
    # For system tests, especially those involving JavaScript, ensure a JS-capable driver is used.
    # This is configured in rails_helper.rb: driven_by :selenium_chrome_headless, js: true
    # The `js: true` tag on the describe block or individual examples enables this.
  end

  describe "Visiting the home page", js: true do
    it "loads successfully and displays welcome message" do
      visit root_path
      expect(page).to have_http_status(:ok)
      expect(page).to have_content("UltrAdex Home")
      expect(page).to have_content("Welcome to the UltrAdex application!")
    end

    it "displays a message from Redis" do
      # Mock Redis connection for this test to ensure predictability
      # and avoid actual Redis dependency during unit/feature testing if Redis is not running.
      # However, for a true "smoke test" of the scaffolding, we might want it to hit Redis.
      # For now, let's assume Redis is up and the initializer worked.
      # The controller sets a dynamic time, so we check for a part of the message.
      visit root_path
      expect(page).to have_content("Message from Redis:")
      # Check for the static part of the message, as the timestamp will change.
      expect(find("#redis-message")).to have_text(/Hello from Redis! Current time:/)
    end

    it "interacts with the Stimulus 'hello' controller" do
      visit root_path
      expect(find('[data-hello-target="output"]')).to have_text("Stimulus controller is active!") # Initial text from connect()

      click_button "Greet!"
      expect(find('[data-hello-target="output"]')).to have_text(/Hello from Stimulus at \d{1,2}:\d{2}:\d{2} (AM|PM)?/) # Text after click
    end

    it "interacts with the Turbo Frame" do
      visit root_path
      expect(page.find('turbo-frame#turbo_content_area')).to have_text("This content is inside a Turbo Frame.")

      click_link "Load Other Content"

      # Wait for Turbo Frame to update
      expect(page.find('turbo-frame#turbo_content_area')).to have_text(/This content was dynamically loaded into the Turbo Frame at \d{1,2}:\d{2}:\d{2}/)
      expect(page.find('turbo-frame#turbo_content_area')).to have_link("Load original content again")
    end

    context "when Redis is down (simulated)" do
      before do
        # This is a more advanced way to test failure, by stubbing the client.
        # For this initial scaffolding, we might not need such a deep test,
        # but it's good to be aware of how one might do it.
        allow(Rails.application.config).to receive(:redis_client).and_return(
          instance_double(Redis, get: nil, set: nil).tap do |mock_redis|
            allow(mock_redis).to receive(:get).with("ultradex_test_key").and_raise(Redis::CannotConnectError, "Simulated connection error")
            allow(mock_redis).to receive(:set).with(any_args).and_raise(Redis::CannotConnectError, "Simulated connection error")
          end
        )
      end

      it "displays an error message if Redis connection fails" do
        visit root_path
        expect(page).to have_content("Message from Redis: N/A (Redis connection failed)")
        expect(page).to have_content("Error: Error connecting to Redis: Simulated connection error")
      end
    end
  end
end
