#!/bin/bash
set -e

# Start Redis Stack server in the background
# The base image's entrypoint.sh likely does more setup before running redis-stack-server.
# We need to replicate that or find a way to call it correctly.
# A common way is to call the original entrypoint if it exists and can be backgrounded,
# or directly call the redis-stack-server command.

echo "Starting Redis Stack server in background..."
# Attempt to use the base image's original entrypoint logic if possible,
# otherwise, directly start redis-stack-server.
# This assumes `redis-stack-server` is in the PATH.
# The `--daemonize yes` option might not work as expected if the base entrypoint has complex process management.

# Option 1: If base image's /entrypoint.sh handles daemonizing or backgrounding itself when given specific args
# (This is a guess, would need to inspect the base image's entrypoint.sh)
# /entrypoint.sh background-redis-start-command &

# Option 2: Directly start redis-stack-server, assuming it can be daemonized or backgrounded.
# The `redis/redis-stack` image typically runs redis-stack-server in the foreground.
# To run it in the background here, we might need to manage it carefully or use a process manager.
# For simplicity in a dev Dockerfile that combines services, we can try to background it.

# A simple approach for a combined dev image:
nohup redis-stack-server --daemonize no > /var/log/redis-stack.log 2>&1 &
redis_pid=$!
echo "Redis Stack server started with PID $redis_pid"

# Wait a few seconds for Redis to initialize
echo "Waiting for Redis to start..."
sleep 5 # Adjust as needed

# Check if Redis is up
if ! redis-cli ping > /dev/null 2>&1; then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "Redis Stack server did not start correctly. Check /var/log/redis-stack.log inside the container."
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  # Optionally, exit here if Redis is critical for the next command to even try
  # exit 1
else
  echo "Redis Stack server confirmed running."
fi

# If there's a pre-existing server.pid, remove it.
if [ -f /usr/src/app/tmp/pids/server.pid ]; then
  echo "Removing existing server.pid"
  rm /usr/src/app/tmp/pids/server.pid
fi

# Execute the CMD passed to the Dockerfile (e.g., rails server)
echo "Executing command: $@"
exec "$@"
