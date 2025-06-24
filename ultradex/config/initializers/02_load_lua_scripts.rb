# ultradex/config/initializers/02_load_lua_scripts.rb

# The numeric prefix '02_' helps ensure this runs after '01_redis.rb' (if it were named that)
# or generally after the Redis client is expected to be set up.
# Using Rails.application.config.after_initialize is a more robust way.

Rails.application.config.after_initialize do
  # Check if running in a context where DB/Redis access is expected (server, console, tests)
  # Avoid running during asset precompilation or other rake tasks that don't need DB.
  should_load_scripts = defined?(Rails::Server) ||
                        defined?(Rails::Console) ||
                        defined?(Puma) || # Common server
                        (defined?(Rails::TestUnitReporter) && Rails.env.test?) || # Minitest
                        (defined?(RSpec) && Rails.env.test?) # RSpec

  if should_load_scripts
    if Rails.application.config.try(:redis_client)
      begin
        # Attempt a simple command to ensure Redis is responsive before loading scripts
        if Rails.application.config.redis_client.ping == "PONG"
          RedisScripts.load_all_scripts
          Rails.logger.info "Lua scripts loading process initiated by RedisScripts module."
        else
          Rails.logger.warn "Redis client ping failed. Skipping Lua script loading."
        end
      rescue Redis::BaseError => e # Catch all Redis errors, including connection errors
        Rails.logger.error "Failed to connect to Redis or Redis error during initial ping: #{e.message}. Lua scripts not loaded."
        # Depending on the application's criticality for Redis, you might:
        # 1. Raise an error to halt startup (if Redis is absolutely essential)
        #   raise "Critical Redis connection failed: #{e.message}"
        # 2. Log and continue (if the app can run in a degraded state or if scripts are loaded on demand)
        # For this project, Redis is critical. However, failing loudly here might be too disruptive for all environments.
        # The RedisScripts.execute method has a NOSCRIPT check and reload attempt.
      end
    else
      Rails.logger.warn "Redis client (Rails.application.config.redis_client) not configured. Skipping Lua script loading."
    end
  else
    # Rails.logger.debug "Not a server, console, or test environment. Skipping Lua script loading." # Optional: for debugging
  end
end
