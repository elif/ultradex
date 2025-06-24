# Dockerfile for Ultradex Application
# This Dockerfile sets up an environment for a Rails 7 application with Redis Stack.

# Base image with Redis Stack
FROM redis/redis-stack:latest AS base

# Set ARGs for versions to easily update them at build time
ARG RUBY_VERSION=3.1.2
ARG NODE_MAJOR=18
ARG BUNDLER_VERSION="~> 2.3.0" # Match typical Rails 7 bundler version

# Switch to root user for system installations
USER root

# --- Install Essential System Dependencies ---
# Update package lists and install sudo first, then other common dependencies.
# Grouping installations in a single RUN command reduces image layers.
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    build-essential \
    curl \
    git \
    libpq-dev \
    # Dependencies for Ruby compilation
    libssl-dev \
    zlib1g-dev \
    libreadline-dev \
    libyaml-dev \
    libffi-dev \
    # Dependencies for Nokogiri (common Rails gem)
    libxml2-dev \
    libxslt1-dev \
    # Dependencies for image processing gems (e.g., 'mini_magick' or 'rmagick')
    imagemagick \
    # Clean up apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*

# --- Install Node.js and Yarn ---
# Node.js is required for the Rails asset pipeline (e.g., esbuild, importmaps if not using Sprockets fully).
# Yarn is a common JavaScript package manager.
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install --global yarn \
    && rm -rf /var/lib/apt/lists/*

# --- Install Ruby ---
# Compile Ruby from source for the specified version.
ARG RUBY_DOWNLOAD_SHA256=b5aae5537506674595e259c09551a85990774980db791758659cb013de7917f4 # Official SHA256 for ruby-3.1.2.tar.gz
RUN mkdir -p /usr/local/src/ruby \
    && curl -fsSL "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz" -o "/usr/local/src/ruby/ruby-${RUBY_VERSION}.tar.gz" \
    && echo "${RUBY_DOWNLOAD_SHA256} /usr/local/src/ruby/ruby-${RUBY_VERSION}.tar.gz" | sha256sum -c - \
    && cd /usr/local/src/ruby \
    && tar -xzf "ruby-${RUBY_VERSION}.tar.gz" \
    && cd "ruby-${RUBY_VERSION}" \
    && ./configure --disable-install-rdoc --disable-install-capi \
    && make -j "$(nproc)" \
    && make install \
    && rm -rf /usr/local/src/ruby

# --- Install Bundler ---
# Install a specific version of Bundler.
RUN gem install bundler --version "${BUNDLER_VERSION}"

# --- Create Application User ---
# Create a non-root user 'appuser' to run the application for security best practices.
RUN groupadd --gid 1000 appuser \
    && useradd --uid 1000 --gid 1000 --shell /bin/bash --create-home appuser \
    # Allow appuser to use sudo for specific commands if necessary (e.g., chmod in entrypoint by root for system files).
    # This line in sudoers is generally for convenience in dev; review for production.
    && echo "appuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/appuser \
    && chmod 0440 /etc/sudoers.d/appuser

# --- Application Setup ---
# Set the working directory for the application.
WORKDIR /usr/src/app

# Configure Bundler to install gems into the appuser's home directory.
# This avoids permission issues and keeps gems user-specific.
ENV GEM_HOME /home/appuser/.gems
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_BIN $GEM_HOME/bin
# Add gems bin path to the system PATH for both root and appuser.
ENV PATH $GEM_HOME/bin:$PATH

# Copy Gemfile and Gemfile.lock to leverage Docker cache.
# These files define Ruby dependencies. Gemfile.lock is crucial for reproducible builds.
# Ensure Gemfile.lock is committed to your repository.
# The --chown flag ensures these files are owned by appuser.
COPY --chown=appuser:appuser Gemfile Gemfile.lock ./

# Switch to appuser to install gems.
USER appuser

# Install application gems using Bundler.
# The --jobs flag speeds up installation by parallelizing.
# The --retry flag makes the command more resilient to transient network issues.
RUN bundle install --jobs "$(nproc)" --retry 3

# Switch back to root user to copy the rest of the application code
# and the entrypoint script, ensuring correct ownership and permissions for system locations.
USER root

# Copy the rest of the application code into the container.
# The --chown flag ensures all application files are owned by appuser.
COPY --chown=appuser:appuser . .

# --- Entrypoint & CMD ---
# Copy the custom entrypoint script to a system path and make it executable.
# The entrypoint script will start Redis and then execute the main container command (CMD).
COPY --chown=root:root docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch back to appuser for running the application.
USER appuser

# Expose the Rails server port.
# Note: Redis port 6379 is already exposed by the base redis/redis-stack image.
EXPOSE 3000

# Define the entrypoint and default command for the container.
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
