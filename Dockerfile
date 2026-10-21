ARG RUBY_VERSION=3.4.3
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages and apply Debian security updates, since the base image
# tag is no longer rebuilt (ca-certificates upgrades its stale CA bundle)
RUN apt-get update -qq && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install --no-install-recommends -y ca-certificates curl libjemalloc2 libvips sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Rebuild Thruster at the Gemfile.lock version with a patched Go toolchain;
# the gem's prebuilt binary lags Go security releases.
FROM docker.io/library/golang:1.27.3-alpine@sha256:f2c872bcee949b7be9c490efd02b48a8a2fbf947cdf533f1c58525ec9d8170fd AS thrust
COPY Gemfile.lock ./
RUN version="$(sed -n 's/^    thruster (\([0-9.]*\))$/\1/p' Gemfile.lock)" && \
    test -n "$version" && \
    CGO_ENABLED=0 GOBIN=/usr/local/bin go install -trimpath "github.com/basecamp/thruster/cmd/thrust@v${version}"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Replace the gem's prebuilt Thruster binary, which exe/thrust execs
COPY --from=thrust /usr/local/bin/thrust /tmp/thrust
RUN target="$(bundle exec ruby -e 'print File.join(Gem.loaded_specs["thruster"].full_gem_path, "exe", [Gem::Platform.local.cpu, Gem::Platform.local.os].join("-"), "thrust")')" && \
    test -x "$target" && \
    install -m 0755 /tmp/thrust "$target" && \
    rm /tmp/thrust

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p app/posts app/reviews && \
    chown -R rails:rails app/posts app/reviews db log public storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

ENV PORT=3099
EXPOSE $PORT
CMD ./bin/rails server -p $PORT
