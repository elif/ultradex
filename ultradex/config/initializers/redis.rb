# config/initializers/redis.rb

# Default to localhost if REDIS_URL is not set.
# In production, REDIS_URL should be configured in the environment.
redis_url = ENV.fetch('REDIS_URL') { 'redis://localhost:6379/0' }

# Create a global Redis client instance.
# Using a global variable like $redis is common in smaller Rails apps for simplicity,
# though for larger applications, dependency injection or a service locator pattern might be preferred.
# Alternatively, assign to a constant: REDIS_CLIENT = Redis.new(url: redis_url)
# $redis = Redis.new(url: redis_url)

# Or, to make it available through Rails.application.config
if defined?($RUNNING_VIA_CUSTOM_SCRIPT) && $RUNNING_VIA_CUSTOM_SCRIPT && Rails.application.config.redis_client
  # If running via the custom script and the script has already set a Redis client (e.g. from --redis-url option),
  # trust that setup and don't overwrite it.
  # The script sets ENV['REDIS_URL'], which this initializer will pick up if the client isn't pre-set.
  # This check provides an additional layer of safety if the script directly sets Rails.application.config.redis_client.
  if Rails.application.config.redis_client.options[:url] == redis_url
    puts "Redis initializer: Custom script detected. Using pre-configured redis_client for matching URL: #{redis_url}" if Rails.env.development?
  else
    puts "Redis initializer: Custom script detected, but pre-configured redis_client URL does not match ENV REDIS_URL. Re-initializing." if Rails.env.development?
    # This case is tricky: if script set a client to X, but ENV['REDIS_URL'] (which this file uses) is Y.
    # The script currently sets ENV['REDIS_URL'] to its option, so they should match.
    # For safety, if they somehow diverge, let this initializer's logic based on ENV['REDIS_URL'] take precedence.
    Rails.application.config.redis_client = Redis.new(url: redis_url)
  end
else
  # Standard behavior: create a new Redis client.
  # This will also be the path if the custom script sets ENV['REDIS_URL'] and relies on this initializer
  # to create the client, rather than pre-setting Rails.application.config.redis_client itself.
  Rails.application.config.redis_client = Redis.new(url: redis_url)
end

# You can then access it via Rails.application.config.redis_client

# Example of how to test the connection (optional, for debugging during initialization)
begin
  # test_connection = Rails.application.config.redis_client.ping
  # puts "Redis connection successful: PING response: #{test_connection}" if Rails.env.development?
rescue Redis::CannotConnectError => e
  # puts "Failed to connect to Redis: #{e.message}" if Rails.env.development?
  # Depending on the application's needs, you might want to raise the error
  # or handle it gracefully if Redis is not strictly required for the app to boot.
  # For this project, Redis is critical, so failing loudly might be appropriate.
  raise e if Rails.env.development? || Rails.env.test? # Fail fast in dev/test if Redis is down
  # In production, you might have different error handling (e.g., logging and attempting to reconnect)
end

# Ensure the client is properly configured for use with Lua scripting if needed.
# The `redis-rb` gem supports EVAL and EVALSHA directly.
# Example: Rails.application.config.redis_client.eval("return ARGV[1]", argv: ["Hello Redis!"])

# If you plan to load Lua scripts from files and store their SHAs:
# Create a class or module to manage Lua scripts.
# For example:
#
# module RedisScripts
#   LUA_SCRIPT_DIR = Rails.root.join('redis', 'lua_scripts')
#
#   def self.load_script(redis_client, script_name)
#     script_path = LUA_SCRIPT_DIR.join("#{script_name}.lua")
#     raise "Lua script not found: #{script_path}" unless File.exist?(script_path)
#     script_content = File.read(script_path)
#     redis_client.script(:load, script_content)
#   end
#
#   # Example: Load a script and store its SHA
#   # SCRIPT_SHA_GET_KEY = load_script(Rails.application.config.redis_client, 'get_key_example')
#   #
#   # To execute:
#   # Rails.application.config.redis_client.evalsha(SCRIPT_SHA_GET_KEY, keys: ['mykey'])
# end

# For now, we'll just set up the client. Lua script management will be handled later.

puts "Redis initializer loaded. Client configured for URL: #{redis_url}" if Rails.env.development?
