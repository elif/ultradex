# Stage 1: Base image with Redis Stack and build tools
FROM redis/redis-stack:latest AS base

# Install sudo as it might be needed by some setup scripts or for user management
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# --- System Dependencies for Ruby, Node, Yarn, PostgreSQL Client, and Rails app ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libpq-dev \
    # Deps for Ruby compilation
    libssl-dev \
    zlib1g-dev \
    libreadline-dev \
    libyaml-dev \
    libffi-dev \
    # Deps for Nokogiri (common Rails dep)
    libxml2-dev \
    libxslt1-dev \
    # Deps for other gems
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# --- Install Node.js and Yarn ---
ARG NODE_MAJOR=18 # Specify Node.js major version (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install --global yarn \
    && rm -rf /var/lib/apt/lists/*

# --- Install Ruby 3.1.2 ---
ARG RUBY_VERSION=3.1.2
ARG RUBY_DOWNLOAD_SHA256=b5aae5537506674595e259c09551a85990774980db791758659cb013de7917f4
# Official SHA256 for ruby-3.1.2.tar.gz

RUN mkdir -p /usr/local/src/ruby \
    && curl -fsSL https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz -o /usr/local/src/ruby/ruby-${RUBY_VERSION}.tar.gz \
    && echo "${RUBY_DOWNLOAD_SHA256} /usr/local/src/ruby/ruby-${RUBY_VERSION}.tar.gz" | sha256sum -c - \
    && cd /usr/local/src/ruby \
    && tar -xzf ruby-${RUBY_VERSION}.tar.gz \
    && cd ruby-${RUBY_VERSION} \
    && ./configure --disable-install-rdoc --disable-install-capi \
    && make -j "$(nproc)" \
    && make install \
    && rm -rf /usr/local/src/ruby

# --- Install Bundler ---
RUN gem install bundler --version "~> 2.3.0" # Match typical Rails 7 bundler version

# --- Create a non-root user for the application ---
RUN groupadd --gid 1000 appuser \
    && useradd --uid 1000 --gid 1000 --shell /bin/bash --create-home appuser \
    && echo "appuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/appuser \
    && chmod 0440 /etc/sudoers.d/appuser

# --- Application Setup ---
WORKDIR /usr/src/app

# Copy Gemfile and Gemfile.lock first to leverage Docker cache
COPY Gemfile Gemfile.lock ./

# Install gems (as root first, then chown, or directly as appuser if permissions allow writing to Gem home)
# Ensure gems are installed system-wide or in a path accessible by appuser
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_BIN $GEM_HOME/bin
ENV BUNDLE_APP_CONFIG $GEM_HOME
ENV PATH $BUNDLE_BIN:$PATH

RUN bundle install --jobs "$(nproc)" --retry 3 \
    && chmod -R 777 $GEM_HOME # Make gems accessible to appuser, or chown $GEM_HOME to appuser

# Copy the rest of the application code
COPY . .

# Ensure app directory is owned by appuser
RUN chown -R appuser:appuser /usr/src/app

# Switch to non-root user
USER appuser

# Expose Rails server port (Redis port 6379 is already exposed by base image)
EXPOSE 3000

# --- Entrypoint & CMD ---
# The base redis/redis-stack image has an entrypoint `/entrypoint.sh` and CMD `["redis-stack-server"]`
# We need to run Redis in the background and then our app.
# Create a custom entrypoint script.

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN sudo chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
