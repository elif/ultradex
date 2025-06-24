class HomeController < ApplicationController
  def index
    redis = Rails.application.config.redis_client
    begin
      redis.set("ultradex_test_key", "Hello from Redis! Current time: #{Time.now.iso8601}")
      @redis_message = redis.get("ultradex_test_key")
      @redis_error = nil
    rescue Redis::CannotConnectError => e
      @redis_message = "N/A (Redis connection failed)"
      @redis_error = "Error connecting to Redis: #{e.message}"
    end
  end

  def turbo_frame_content
    # This action will render content specifically for the turbo frame
    render partial: "turbo_content"
  end
end
