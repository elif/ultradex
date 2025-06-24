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
    # Dependencies for Ruby compilation (some still needed by RVM or gems)
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
    # For RVM installation and SSL certs
    gnupg \
    ca-certificates \
    # Clean up apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*

# --- Install Node.js and Yarn ---
# Node.js is required for the Rails asset pipeline (e.g., esbuild, importmaps if not using Sprockets fully).
# Yarn is a common JavaScript package manager.
RUN set -x \
    && curl -sL https://deb.nodesource.com/setup_${NODE_MAJOR}.x -o nodesource_setup.sh \
    && bash nodesource_setup.sh \
    && apt-get update \
    && apt-get install -y nodejs npm \
    && npm install --global yarn \
    && rm -rf /var/lib/apt/lists/* \
    && rm nodesource_setup.sh

# --- Create Application User ---
# Create a non-root user 'appuser' to run the application for security best practices.
# This is done before RVM installation so RVM can be installed as the user.
RUN groupadd --gid 1000 appuser \
    && useradd --uid 1000 --gid 1000 --shell /bin/bash --create-home appuser \
    && echo "appuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/appuser \
    && chmod 0440 /etc/sudoers.d/appuser

# --- Install RVM, Ruby, and Bundler ---
# Switch to appuser to install RVM and Ruby in the user's home directory.
USER appuser
WORKDIR /home/appuser

# Install RVM GPG keys and RVM itself.
# Using bash -l -c to ensure RVM environment is sourced for subsequent commands.
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
    && curl -sSL https://get.rvm.io | bash -s stable \
    && /bin/bash -l -c "rvm install ${RUBY_VERSION} && \
        rvm use ${RUBY_VERSION} --default && \
        gem install bundler -v '${BUNDLER_VERSION}' && \
        rvm cleanup all"

# --- Application Setup ---
WORKDIR /usr/src/app

# Set environment variables for RVM and Bundler.
# The RVM path needs to be sourced. This is typically done by a login shell.
# For Docker, we often set PATH explicitly or use `rvm do` for commands.
# Note: GEM_HOME and BUNDLE_PATH are managed by RVM.
ENV PATH /home/appuser/.rvm/gems/ruby-${RUBY_VERSION}/bin:/home/appuser/.rvm/gems/ruby-${RUBY_VERSION}@global/bin:/home/appuser/.rvm/rubies/ruby-${RUBY_VERSION}/bin:/home/appuser/.rvm/bin:$PATH

# Copy Gemfile and Gemfile.lock to leverage Docker cache.
# These files define Ruby dependencies. Gemfile.lock is crucial for reproducible builds.
# Ensure Gemfile.lock is committed to your repository.
# Ownership is already appuser as we switched user.
COPY Gemfile Gemfile.lock ./

# Install application gems using Bundler.
# Ensure RVM environment is loaded using `bash -l -c`.
RUN /bin/bash -l -c "bundle install --jobs \"$(nproc)\" --retry 3"

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
