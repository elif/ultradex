# ultradex/app/lib/redis_scripts.rb
module RedisScripts
  LUA_SCRIPT_DIR = Rails.root.join('ultradex', 'redis', 'lua_scripts')
  @script_shas = {}

  def self.redis_client
    Rails.application.config.redis_client
  end

  def self.load_all_scripts
    # Ensure Redis client is available and can connect
    # Pinging is a lightweight way to check the connection.
    begin
      unless redis_client && redis_client.ping == "PONG"
        Rails.logger.warn "Redis client not configured or not responding. Skipping Lua script loading."
        return
      end
    rescue Redis::BaseError => e
      Rails.logger.error "Redis connection error during script loading: #{e.message}. Skipping Lua script loading."
      return
    end

    Dir.glob(LUA_SCRIPT_DIR.join('*.lua')).each do |script_file|
      script_name = File.basename(script_file, '.lua').to_sym
      begin
        script_content = File.read(script_file)
        sha = redis_client.script(:load, script_content)
        @script_shas[script_name] = sha
        Rails.logger.info "Loaded Lua script: #{script_name} (SHA: #{sha})"
      rescue Errno::ENOENT => e
        Rails.logger.error "Lua script file not found: #{script_file}. #{e.message}"
      rescue Redis::BaseError => e # Catch Redis specific errors
        Rails.logger.error "Redis error loading script #{script_name} (SHA: #{@script_shas[script_name]}): #{e.message}"
        # Depending on policy, you might want to re-raise or prevent app startup
      rescue StandardError => e
        Rails.logger.error "Error loading Lua script #{script_name}: #{e.message}"
      end
    end
  end

  def self.sha_for(script_name)
    @script_shas[script_name.to_sym] || raise("SHA for script '#{script_name}' not found. Was it loaded and is Redis running?")
  end

  # Convenience method to execute a loaded script by name
  def self.execute(script_name, keys: [], argv: [])
    sha = sha_for(script_name)
    redis_client.evalsha(sha, keys: keys, argv: argv)
  rescue Redis::CommandError => e
    # If the error is NOSCRIPT, it means Redis doesn't have the SHA.
    # This can happen if Redis was flushed or restarted.
    # We can try to reload the specific script or all scripts.
    if e.message.include?("NOSCRIPT")
      Rails.logger.warn "NOSCRIPT error for #{script_name}. Attempting to reload scripts."
      load_all_scripts # Reload all scripts
      sha = sha_for(script_name) # Get the new SHA
      redis_client.evalsha(sha, keys: keys, argv: argv) # Retry execution
    else
      raise # Re-raise other command errors
    end
  end

  # Getter for script_shas, mainly for inspection or debugging
  def self.loaded_script_shas
    @script_shas.dup # Return a copy
  end
end
