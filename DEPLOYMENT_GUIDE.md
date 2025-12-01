# 1bit.com.br Website Deployment Guide

## Important Rules

### 1. Always Test Locally First
**NEVER deploy to production without testing locally first.**

```bash
# Start local server
node server.js

# Server runs at http://localhost:8000/
```

### 2. Do NOT Change Homepage Links
The links in `index.html` must remain unchanged because:
- External websites link to these URLs
- Changing them would break existing links across the web
- Format: `content.1bit/article_name` (without /index.html)

### 3. Domain Information
- Primary domain: `1bit.com.br` (without www)
- `www.1bit.com.br` → redirects to `1bit.com.br` (301)
- GitHub Pages serves the site

## Local Testing Workflow

### Step 1: Start Local Server
```bash
node server.js
# Output: Server running at http://localhost:8000/
```

### Step 2: Run Automated Link Checker (RECOMMENDED)
```bash
./check_links.sh
```

This script automatically checks:
- All CSS files load correctly
- All images are accessible
- Homepage and article pages work
- No broken links on the site

**Exit codes:**
- `0` = All checks passed, safe to deploy ✅
- `1` = Found broken links, fix before deploying ❌

The link checker will show detailed output like:
```
📄 Checking: Poder e flexibilidade
  CSS files:
  ✓ http://localhost:8000/1bit.css
  Images:
  ✓ http://localhost:8000/images/logo2.png
  ✓ http://localhost:8000/images/rebarba1.png
  ...
```

### Step 3: Manual Tests (if needed)

If you want to manually test specific things:

#### Test Homepage
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/
# Expected: 200
```

### Step 3: Test Article Links
```bash
# Test all main article links from homepage
curl -s -o /dev/null -w "%{http_code} - bom_programador\n" http://localhost:8000/content.1bit/bom_programador
curl -s -o /dev/null -w "%{http_code} - programador\n" http://localhost:8000/content.1bit/programador
curl -s -o /dev/null -w "%{http_code} - flexibilidade\n" http://localhost:8000/content.1bit/flexibilidade
curl -s -o /dev/null -w "%{http_code} - managed\n" http://localhost:8000/content.1bit/managed
curl -s -o /dev/null -w "%{http_code} - about\n" http://localhost:8000/content.1bit/about
# Expected: All 200
```

### Step 4: Test Content Rendering
```bash
# Check if actual content loads (not Cloudflare challenge)
curl -s http://localhost:8000/content.1bit/bom_programador | grep -i "cloudflare\|One moment" | wc -l
# Expected: 0 (no Cloudflare content)

# Check actual article title appears
curl -s http://localhost:8000/content.1bit/bom_programador | grep "<h4>" | head -1
# Expected: <h4>Como ser um bom programador</h4>
```

### Step 5: Test Navigation Links in Articles
```bash
# Test logo link
curl -s http://localhost:8000/content.1bit/bom_programador | grep 'href="../../"' | head -1
# Expected: <a href="../../"><img src="../../images/logo_novo_2.png"...

# Test sidebar links
curl -s http://localhost:8000/content.1bit/bom_programador | grep 'href="../../content.1bit/about"'
# Expected: href="../../content.1bit/about"
```

## Deployment Workflow

### Step 1: Make Changes
Edit files as needed in the repository.

### Step 2: Test Locally (MANDATORY)
```bash
# Make sure server is running
node server.js &

# Run link checker
./check_links.sh

# If all checks pass, proceed to commit
```

**CRITICAL:** Never skip this step! The link checker will catch:
- Broken CSS paths
- Missing images
- Incorrect relative links
- 404 errors

before you deploy to production.

### Step 3: Commit Changes
```bash
git add <files>
git commit -m "Description of changes

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 4: Push to GitHub
```bash
git push
```

### Step 5: Wait for GitHub Pages Deployment
```bash
# Wait 30-60 seconds for GitHub Pages to rebuild
sleep 30
```

### Step 6: Verify Live Site
```bash
# Test homepage
curl -sL -o /dev/null -w "%{http_code}\n" https://1bit.com.br/
# Expected: 200

# Test article pages
curl -sL -o /dev/null -w "%{http_code}\n" https://1bit.com.br/content.1bit/bom_programador/
# Expected: 200

# Verify navigation links work
curl -sL https://1bit.com.br/content.1bit/bom_programador/ | grep 'href="../../"' | head -1
# Expected: Logo link should be href="../../"
```

## File Structure

### Article Pages Structure
Article pages in `content.1bit/` directories must follow this structure:

```
content.1bit/
├── article_name/
│   └── index.html
```

### Navigation Links in Article Pages

**Logo Link (returns to homepage):**
```html
<a href="../../"><img src="../../images/logo_novo_2.png" border="0" alt="logo"/></a>
```

**Top Menu Links:**
```html
<a class="top_menu_link" href="../../content.1bit/links">Links</a>
<a class="top_menu_link" href="../../content.1bit/contact">Contato</a>
<a class="top_menu_link" href="../../content.1bit/busca">Busca no site</a>
<a class="top_menu_link" href="../../content.1bit/about">Sobre...</a>
```

**Sidebar Menu Links:**
```html
<h2><a href="../../#artigos" style="text-decoration:none;">Artigos</a></h2>
<h2><a href="../../content.1bit/weblog" style="text-decoration:none;">Blog</a></h2>
<h2><a href="../../cpp/wiki" style="text-decoration:none;">Wiki C/C++</a></h2>
```

### Resource Paths in Article Pages
```html
<link href="../../1bit.css" type="text/css" rel="stylesheet">
<img src="../../images/rebarba1.png" alt="rebarba">
```

## Common Tasks

### Adding a New Article

1. **Create directory and file:**
```bash
mkdir -p content.1bit/new_article
```

2. **Create content.1bit/new_article/index.html with correct paths:**
   - Logo: `href="../../"`
   - CSS: `href="../../1bit.css"`
   - Images: `src="../../images/..."`
   - Top menu: `href="../../content.1bit/..."`
   - Sidebar: `href="../../content.1bit/..."`

3. **Test locally:**
```bash
node server.js
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/content.1bit/new_article
```

4. **Add link to homepage (index.html):**
```html
<h6><a href="content.1bit/new_article">Article Title</a></h6>
```
Note: Homepage uses relative paths WITHOUT `../../`

5. **Deploy:**
```bash
git add content.1bit/new_article/index.html index.html
git commit -m "Add new article"
git push
```

### Fixing Broken Navigation

If navigation links don't work in article pages:

1. **Check logo link:**
```bash
# Should be href="../../"
grep 'href=""' content.1bit/*/index.html
```

2. **Check top menu links:**
```bash
# Should be href="../../content.1bit/*"
grep 'href="content.1bit/' content.1bit/*/index.html
```

3. **Fix with:**
```bash
# Replace empty logo href
sed -i 's|href=""|href="../../"|g' content.1bit/*/index.html

# Fix top menu links (if needed, do manually with Edit tool)
```

### Downloading Missing Content from Internet Archive

```bash
# Download from archive.org
curl -L "http://web.archive.org/web/20070311224615/http://www.1bit.com.br/content.1bit/article_name" > /tmp/article_raw.html

# Clean up with Python script
python3 << 'EOF'
import re
with open('/tmp/article_raw.html', 'r', encoding='latin-1') as f:
    content = f.read()

# Remove Internet Archive wrapper
content = re.sub(r'^.*?<!DOCTYPE', '<!DOCTYPE', content, flags=re.DOTALL)
content = re.sub(r'<script[^>]*src="https://web-static\.archive\.org[^"]*"[^>]*></script>\s*', '', content)
content = re.sub(r'<link[^>]*href="https://web-static\.archive\.org[^"]*"[^>]*>\s*', '', content)

# Fix paths
content = re.sub(r'/web/\d+im_/http://www\.1bit\.com\.br/', '../../', content)
content = re.sub(r'http://web\.archive\.org/web/\d+/(http[^"]+)', r'\1', content)
content = re.sub(r'<!--\s*FILE ARCHIVED ON.*$', '', content, flags=re.DOTALL)

with open('/tmp/article_clean.html', 'w', encoding='utf-8') as f:
    f.write(content)
EOF

# Copy to destination
cp /tmp/article_clean.html content.1bit/article_name/index.html
```

## Troubleshooting

### Issue: Links return 404
**Solution:** Check if `index.html` exists in the directory:
```bash
ls -la content.1bit/article_name/index.html
```

### Issue: Cloudflare challenge page appears
**Solution:** Content file was not properly downloaded. Re-download from Internet Archive.

### Issue: Navigation links don't work in articles
**Solution:** Check relative paths are correct (../../)
```bash
curl -s http://localhost:8000/content.1bit/article | grep 'href="../../"'
```

### Issue: Images don't load
**Solution:** Check image paths use ../../images/
```bash
grep 'src=".*images/' content.1bit/article/index.html
```

## Quick Reference

### All Article Links from Homepage
```
content.1bit/about
content.1bit/bom_programador
content.1bit/contact
content.1bit/flexibilidade
content.1bit/managed
content.1bit/nao_ouca_ninguem
content.1bit/opensource
content.1bit/programador
content.1bit/weblog
content.1bit/windbg1
content.1bit/windbg2
content.1bit/windbg3
```

### Test All Articles at Once
```bash
for path in about bom_programador contact flexibilidade managed nao_ouca_ninguem opensource programador weblog windbg1 windbg2 windbg3; do
  echo -n "$path: "
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/content.1bit/$path
done
```

### Verify Live Deployment
```bash
# Wait for deployment
sleep 30

# Test all articles
for path in about bom_programador contact flexibilidade managed nao_ouca_ninguem opensource programador; do
  echo -n "$path: "
  curl -sL -o /dev/null -w "%{http_code}\n" https://1bit.com.br/content.1bit/$path/
done
```

## Notes

- Local server handles directory routing automatically (e.g., `/content.1bit/article` → `/content.1bit/article/index.html`)
- GitHub Pages also handles this, but may require trailing slash in some cases
- Always preserve homepage link format to maintain backward compatibility
- Encoding: Files use UTF-8, but some legacy content may use Latin-1
