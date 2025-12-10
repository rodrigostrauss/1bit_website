# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Static personal blog/website (1bit.com.br) - a Portuguese-language programming blog focused on C++, debugging, and software engineering. Uses plain HTML 4.0/CSS with no build system, templating, or CMS.

## Development Commands

```bash
# Start local development server (port 8000)
node server.js

# Validate all links before deployment (MANDATORY - must exit 0)
./check_links.sh

# Deployment (GitHub Pages auto-deploys on push)
git add <files> && git commit -m "message" && git push
```

## Architecture

**URL Structure:**
- Homepage links: `content.1bit/article_name` (no trailing slash)
- Articles stored as: `content.1bit/article_name/index.html`
- Both local server and GitHub Pages auto-route directories to index.html

**Path Conventions (critical for both local and production):**
- From article pages: `../../` to reach root
- CSS reference: `../../1bit.css`
- Images: `../../images/filename.png`
- Cross-article links: `../../content.1bit/other_article`

**Directory Structure:**
- `content.1bit/` - Main content (articles, about, contact)
- `content.1bit/weblog/` - 360+ blog posts as individual directories
- `images/` - Image assets (organized in subdirectories)
- `1bit.css` - Single global stylesheet

## Critical Constraints

1. **Do not change homepage link structure** - external sites link to `content.1bit/article_name` paths
2. **Always run `./check_links.sh`** before pushing - catches broken CSS, images, and links
3. **Maintain `../../` relative paths** in article pages - required for both environments
4. **Use UTF-8 encoding** for new/edited files (legacy content may be ISO-8859)
5. **Domain is `1bit.com.br`** (no www prefix)

## Testing

```bash
# Test single article
curl -s http://localhost:8000/content.1bit/bom_programador

# Test all main content paths
for path in about bom_programador contact flexibilidade managed \
            nao_ouca_ninguem opensource programador; do
  curl -s -o /dev/null -w "$path: %{http_code}\n" http://localhost:8000/content.1bit/$path
done
```
