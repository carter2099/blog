# AGENTS.md

Canonical architecture and implementation reference for AI coding agents working on this codebase.

## Project Overview

Rails 8 personal blog with file-based markdown content storage. Single-author design — expects one authenticated user. Posts and reviews are stored as markdown files on disk while metadata lives in SQLite. Deployed via Docker Compose to a homelab.

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
bin/rake                               # Default: rubocop + test (use this to verify changes)
bin/rails test                         # Run all tests
bin/rails test test/models             # Run model tests only
bin/rails test test/controllers        # Run controller tests only
bin/rails test:system                  # Run system tests (requires Chrome)
bin/rails test test/models/post_test.rb      # Run a specific test file
bin/rails test test/models/post_test.rb:14   # Run a specific test by line
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

This is the core design decision — posts and reviews use **files for content, database for metadata**.

1. Markdown files live in `app/posts/*.md` and `app/reviews/*.md` (both gitignored)
2. Models store metadata: `Post` has `title` and `path`; `Review` has `title`, `rating`, `author`, `review_type_id`, `main_image`, and `path` (path is optional for reviews)
3. Content is read from disk on each request via `MarkdownRenderer.render_file(path)`
4. Deleted items are moved to `app/posts/deleted/` or `app/reviews/deleted/` (soft delete)
5. The asset pipeline **excludes** `app/assets/images/` (`config/application.rb`) — images are managed manually

**Image handling flow:**
Upload → controller `process_images` copies to `app/assets/images/` → `process_file` converts Obsidian syntax → `PostsHelper.load_post_images` copies to `public/assets/` for serving

**Obsidian integration:** Converts `![[filename.jpg]]` → `![filename.jpg](/assets/filename.jpg)` via regex in `process_file`, enabling seamless Obsidian vault export.

**Important:** Images are served from `public/assets/` via direct `/assets/filename` paths — NOT through the Propshaft asset pipeline. Do not use `image_tag` for user-uploaded images; use plain `<img src="/assets/...">` tags instead.

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
- **Post** — validates title/path presence; content lives on disk
- **Review** — belongs to `ReviewType`; validates title/rating; rating is float 0-5; `author` required for books; optional `path` (markdown content) and `main_image` (filename served from `/assets/`); `formatted_rating` returns display string like `4/5` or `3.5/5`
- **ReviewType** — has many reviews; constants: `BOOK=1`, `MOVIE=2`, `SHOW=3`, `PRODUCT=4`; names are singular (Book, Movie, Show, Product)
- **Current** — request-scoped attributes: delegates `user` from `session`

### Controllers

Posts and Reviews controllers share the same patterns:
- `process_file(file)` — saves markdown, converts Obsidian image syntax
- `process_images(images)` — copies to `app/assets/images/`, calls `PostsHelper.load_post_images`
- `validate_params` — uses `params.expect()` (Rails 8 style, not `permit`/`require`)
- File operations rescue `StandardError` and flash errors

Reviews controller additionally has:
- `process_main_image(image)` — saves single image, stores filename on `@review.main_image`, calls `PostsHelper.load_post_images`

RSS feed (`PostsController#rss`) generates Atom XML combining the 20 most recent posts and reviews.

### Routing

```
root               → home#index
resource :session   → singular (one session per user)
resources :passwords, param: :token
/posts/*           → explicit routes (not `resources :posts`)
/reviews/*         → explicit routes (not `resources :reviews`)
/rss               → posts#rss (Atom feed, last 20 items)
/up                → health check
```

### Markdown Rendering

`lib/markdown_renderer.rb` — Redcarpet configured with `hard_wrap: true`, `filter_html: true`, `fenced_code_blocks: true`. Used in both post/review display and RSS feed generation.

### Database

**Schema:**
- `users` — email_address (unique), password_digest
- `sessions` — user_id, ip_address, user_agent
- `posts` — title, path
- `reviews` — title, rating (float), author, path (nullable), review_type_id, main_image (nullable)
- `review_types` — name (unique); IDs: 1=Book, 2=Movie, 3=Show, 4=Product

**Production** uses four SQLite databases:
- `storage/production.sqlite3` — main app data
- `storage/production_cache.sqlite3` — Solid Cache (256MB max)
- `storage/production_queue.sqlite3` — Solid Queue
- `storage/production_cable.sqlite3` — Solid Cable

**SQLite caveat:** `execute` with multi-statement SQL only runs the first statement. Always use separate `execute` calls for multiple SQL statements.

### Deployment

- Docker multi-stage build: Ruby 3.4.3-slim base, Bootsnap + asset precompilation
- Runs as non-root `rails:rails` user on port 3099
- `bin/docker-entrypoint` runs `db:prepare` on boot
- Production volumes: `./app/posts`, `./app/reviews`, `./app/assets/images`, `./storage`
- Assumes SSL-terminating reverse proxy (`assume_ssl: true`, `force_ssl: true`)
- Solid Queue runs inside Puma via `plugin :solid_queue` (triggered by `SOLID_QUEUE_IN_PUMA` env var)

### CI (GitHub Actions)

Runs on PRs and pushes to main:
1. **scan_js** — `bin/importmap audit`
2. **lint** — `bin/rubocop -f github`
3. **test** — `bin/rails db:test:prepare test test:system` (uploads screenshots on failure)

### Rails 8 Conventions

- `params.expect()` for parameter validation (not `permit`/`require`)
- Turbo confirmations via `data: { turbo_confirm: ... }`
- Importmap for JavaScript (no bundler)
- Hand-written CSS in `app/assets/stylesheets/application.css` (no framework)
