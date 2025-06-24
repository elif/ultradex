#!/bin/bash
set -e

REDIS_LOG_FILE="/var/log/redis-stack.log"

# Start Redis Stack server in the background.
# The `redis-stack-server` command from the base image is expected to be in the PATH.
# We run it with `nohup` and redirect its output to a log file.
# Using `--daemonize no` because we are managing it with `nohup` and `&`.
echo "Starting Redis Stack server in background... Logs will be at ${REDIS_LOG_FILE}"
nohup redis-stack-server --daemonize no > "${REDIS_LOG_FILE}" 2>&1 &
redis_pid=$!
echo "Redis Stack server process initiated with PID $redis_pid."

# Wait for Redis to start and become responsive.
# This loop tries to ping Redis several times before giving up.
MAX_REDIS_WAIT_SECONDS=30
REDIS_WAIT_INTERVAL_SECONDS=2
elapsed_wait_seconds=0
redis_ready=false

echo "Waiting for Redis to become available (max ${MAX_REDIS_WAIT_SECONDS} seconds)..."
while [ $elapsed_wait_seconds -lt $MAX_REDIS_WAIT_SECONDS ]; do
  if redis-cli ping > /dev/null 2>&1; then
    echo "Redis Stack server confirmed running and responsive."
    redis_ready=true
    break
  fi
  echo "Redis not yet available, waiting ${REDIS_WAIT_INTERVAL_SECONDS}s..."
  sleep $REDIS_WAIT_INTERVAL_SECONDS
  elapsed_wait_seconds=$((elapsed_wait_seconds + REDIS_WAIT_INTERVAL_SECONDS))
done

if [ "$redis_ready" = false ]; then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "Redis Stack server did not become responsive within ${MAX_REDIS_WAIT_SECONDS} seconds."
  echo "Check Redis logs at ${REDIS_LOG_FILE} for more details."
  echo "You might need to increase MAX_REDIS_WAIT_SECONDS in this script."
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  # Optionally, exit if Redis is critical for the application to start.
  # For a development setup, we might allow it to continue so the user can debug.
  # exit 1
fi

# Clean up a pre-existing Rails server PID file if it exists.
# This can prevent the Rails server from starting if the container was improperly stopped.
RAILS_PID_FILE="/usr/src/app/tmp/pids/server.pid"
if [ -f "${RAILS_PID_FILE}" ]; then
  echo "Removing existing Rails server.pid at ${RAILS_PID_FILE}"
  rm -f "${RAILS_PID_FILE}"
fi

# Execute the main command passed to the Docker container (e.g., `rails server`).
echo "Executing main container command: $@"
exec "$@"
