# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8 personal blog application with file-based markdown content storage. Posts are stored as markdown files on disk while metadata lives in SQLite. The app uses Rails 8's built-in authentication system and is deployed via Docker Compose to a homelab.

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
bin/rails test                        # Run all tests
bin/rails test test/models            # Run model tests
bin/rails test test/controllers       # Run controller tests
bin/rails test:system                 # Run system tests
bin/rails test <path/to/test.rb>      # Run specific test file
bin/rails test <path/to/test.rb>:<line> # Run specific test method
```

### Code Quality
```bash
bin/rubocop                  # Run linter (uses Rails Omakase style + rubocop-erb)
bin/rubocop -a               # Auto-fix linting issues
bin/importmap audit          # Check JavaScript dependency vulnerabilities
```

### Deployment
```bash
docker compose build         # Build the Docker image
docker compose up -d         # Start containers in background
docker compose logs -f       # View container logs
docker compose exec app bin/rails console  # Rails console in container
```

## Architecture

### Authentication System
- Custom Rails 8 authentication (no Devise)
- Database-backed sessions with signed cookies
- Multi-device support via separate Session records
- Request context stored in `Current.user` and `Current.session` via ActiveSupport::CurrentAttributes
- Authentication concern in `app/controllers/concerns/authentication.rb` provides session management

### Models & Relationships
- **User**: Has many sessions, uses `has_secure_password`
- **Session**: Belongs to user, tracks IP address and user agent for security
- **Post**: Minimal model with title/path validation - actual content lives in markdown files
- **Current**: Request-scoped attributes for accessing current user/session

### File-Based Content System
- Blog posts stored as markdown files in `app/posts/*.md`
- Post model stores metadata (title, path) in database
- Content is read from disk and rendered with Redcarpet
- Images stored in `app/assets/images/` and copied to `public/assets/` via PostsHelper
- Deleted posts moved to `app/posts/deleted/` (soft delete pattern)

### Obsidian Integration
The PostsController automatically converts Obsidian wiki-link image syntax:
- Input: `![[filename.jpg]]`
- Output: `![filename.jpg](/assets/filename.jpg)`

This enables seamless export from Obsidian vaults.

### Database Configuration
Production uses multiple SQLite databases:
- `production` - Main application data
- `production_cache` - Solid Cache storage
- `production_queue` - Solid Queue jobs
- `production_cable` - Solid Cable WebSocket data

### RSS Feed
- Atom format feed available at `/rss`
- Generated from last 20 posts
- Uses the `rss` gem

## Key Files & Patterns

### Controllers
- `ApplicationController` includes `Authentication` concern
- `PostsController` handles markdown rendering, file uploads, and image processing
- Rate limiting on `SessionsController#create` (10 requests per 3 minutes)
- Use `params.expect()` for Rails 8 parameter validation

### Image Handling Flow
1. Upload image via post form
2. Controller calls `process_images` to copy to `app/assets/images/`
3. Controller calls `process_file` to convert Obsidian syntax
4. PostsHelper.load_post_images copies images to `public/assets/`

### Markdown Rendering
Redcarpet configured with:
- `hard_wrap: true` - Preserves line breaks
- `filter_html: true` - Sanitizes HTML
- `fenced_code_blocks: true` - Supports ``` code blocks

## Testing Strategy
- Uses Minitest (Rails default)
- Parallel execution enabled
- System tests use Capybara + Selenium WebDriver
- CI runs: importmap audit, rubocop, and full test suite

## Deployment
- Deployed via Docker Compose to homelab
- Ruby 3.4.3 slim base image
- Multi-stage build with Bootsnap and asset precompilation
- Runs on port 3099 as non-root user (rails:rails)
- Solid Queue supervisor runs in Puma process (not separate container)

## Technology Stack
- **Backend**: Rails 8.1.1, Ruby 3.4.3, SQLite3
- **Frontend**: Propshaft, Importmap, Turbo, Stimulus
- **Content**: Redcarpet (markdown), RSS (feeds)
- **Production**: Docker Compose, Solid Cache, Solid Queue, Solid Cable, Thruster
- **Testing**: Minitest, Capybara, Selenium

## Important Notes
- This is a single-author blog (expects one authenticated user)
- Posts are files, not database records - be careful with file operations
- Asset pipeline excludes `app/assets/images` - images handled manually via PostsHelper
- Password reset tokens use Rails message verifier (time-limited signed tokens)
- Style guide is Rails Omakase (inherited via rubocop-rails-omakase gem)
