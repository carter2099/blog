# AGENTS.md

Canonical architecture and implementation reference for AI coding agents working on this codebase.

## Project Overview

Rails 8 personal blog with file-based markdown content storage. Single-author design — expects one authenticated user. Posts are stored as markdown files on disk (`app/posts/*.md`) while metadata (title, path) lives in SQLite. Deployed via Docker Compose to a homelab.

### Technology Stack

| Layer | Tools |
|-------|-------|
| Backend | Rails 8.1.1, Ruby 3.4.8, SQLite3 |
| Frontend | Propshaft, Importmap, Turbo, Stimulus |
| Content | Redcarpet (markdown), RSS gem (Atom feeds) |
| Production | Docker Compose, Solid Cache/Queue/Cable, Thruster |
| Testing | Minitest, Capybara, Selenium (Chrome) |
| Style | Rails Omakase (`rubocop-rails-omakase` + `rubocop-erb`) |

## Common Commands

### Development
```bash
bin/setup                    # Initial project setup
bin/rails server             # Start development server (http://localhost:3000)
bin/rails console            # Open Rails console
bin/rails db:migrate         # Run pending migrations
bin/rails db:reset           # Drop, recreate, and seed database
```

### Testing
```bash
bin/rails test                          # Run all tests
bin/rails test test/models              # Run model tests only
bin/rails test test/controllers         # Run controller tests only
bin/rails test:system                   # Run system tests (requires Chrome)
bin/rails test test/models/post_test.rb # Run a specific test file
bin/rails test test/models/post_test.rb:14  # Run a specific test by line
```

### Code Quality
```bash
bin/rubocop                  # Lint (Rails Omakase + rubocop-erb)
bin/rubocop -a               # Auto-fix lint issues
bin/importmap audit          # JS dependency vulnerability check
```

### Deployment
```bash
docker compose build         # Build Docker image
docker compose up -d         # Start containers (port 3099)
docker compose logs -f       # Tail logs
docker compose exec app bin/rails console  # Console in container
```

## Architecture

### File-Based Content System

This is the core design decision — posts are **files, not database records**.

1. Markdown files live in `app/posts/*.md` (gitignored)
2. `Post` model stores only metadata: `title` and `path` (pointing to the file)
3. Content is read from disk on each request and rendered with Redcarpet
4. Deleted posts are moved to `app/posts/deleted/` (soft delete), not destroyed
5. The asset pipeline **excludes** `app/assets/images/` (`config/application.rb`) — images are managed manually via `PostsHelper`

**Image handling flow:**
Upload → `PostsController#process_images` copies to `app/assets/images/` → `PostsController#process_file` converts Obsidian syntax → `PostsHelper.load_post_images` copies to `public/assets/` for serving

**Obsidian integration:** Converts `![[filename.jpg]]` → `![filename.jpg](/assets/filename.jpg)` via regex in `PostsController#process_file`, enabling seamless Obsidian vault export.

### Authentication System

Custom Rails 8 authentication (no Devise):

- `app/controllers/concerns/authentication.rb` — core auth logic included by `ApplicationController`
- Database-backed sessions: `Session` model tracks IP address and user agent per device
- Signed cookies (`session_id`, httponly, same_site: lax)
- Request context via `Current.user` / `Current.session` (ActiveSupport::CurrentAttributes)
- `allow_unauthenticated_access` skips auth for public actions (index, show, rss)
- Rate limiting on `SessionsController#create`: 10 attempts per 3 minutes
- Password resets use Rails MessageVerifier with 15-minute expiration

### Models

- **User** — `has_secure_password`, normalizes email, has many sessions
- **Session** — belongs to user, tracks IP/user agent for security
- **Post** — validates title/path presence only; content lives on disk
- **Current** — request-scoped attributes: delegates `user` from `session`

### Routing

```
root               → home#index
resource :session   → singular (one session per user)
resources :passwords, param: :token
/posts/*           → explicit routes (not `resources :posts`)
/rss               → posts#rss (Atom feed, last 20 posts)
/up                → health check
```

### Markdown Rendering

Redcarpet configured with `hard_wrap: true`, `filter_html: true`, `fenced_code_blocks: true`. Used in both post display and RSS feed generation.

### Database Configuration (Production)

Four SQLite databases:
- `storage/production.sqlite3` — main app data
- `storage/production_cache.sqlite3` — Solid Cache (256MB max)
- `storage/production_queue.sqlite3` — Solid Queue (concurrency via `JOB_CONCURRENCY` env var)
- `storage/production_cable.sqlite3` — Solid Cable (0.1s polling)

Solid Queue runs inside the Puma process via `plugin :solid_queue` (triggered by `SOLID_QUEUE_IN_PUMA` env var).

### Deployment

- Docker multi-stage build: Ruby 3.4.3-slim base, Bootsnap + asset precompilation
- Runs as non-root `rails:rails` user on port 3099
- `bin/docker-entrypoint` runs `db:prepare` on boot
- Production volumes: `./app/posts`, `./app/assets/images`, `./storage`
- Assumes SSL-terminating reverse proxy (`assume_ssl: true`, `force_ssl: true`)

### CI (GitHub Actions)

Runs on PRs and pushes to main:
1. **scan_js** — `bin/importmap audit`
2. **lint** — `bin/rubocop -f github`
3. **test** — `bin/rails db:test:prepare test test:system` (uploads screenshots on failure)

Brakeman security scanning is present but currently disabled.

### Rails 8 Conventions

- `params.expect()` for parameter validation (not `permit`/`require`)
- Turbo confirmations via `data: { turbo_confirm: ... }`
- Importmap for JavaScript (no bundler)
