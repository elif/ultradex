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
Rails.application.config.redis_client = Redis.new(url: redis_url)

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
