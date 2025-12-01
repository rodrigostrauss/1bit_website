#!/bin/bash

# Link Checker Script for 1bit.com.br
# Tests all resources and links on local server before deployment

BASE_URL="http://localhost:8000"
FAILED=0

echo "=================================="
echo "1bit.com.br Link Checker"
echo "=================================="
echo ""
echo "Testing local server at: $BASE_URL"
echo ""

# Check if server is running
if ! curl -s -o /dev/null -w "%{http_code}" "$BASE_URL" | grep -q "200"; then
    echo "❌ ERROR: Local server not running at $BASE_URL"
    echo "Please start the server with: node server.js"
    exit 1
fi

echo "✓ Server is running"
echo ""

# Function to check a URL
check_url() {
    local url=$1
    local context=$2
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    if [ "$status" = "200" ]; then
        echo "  ✓ $url"
        return 0
    else
        echo "  ❌ $url (HTTP $status)"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Function to extract and check resources from a page
check_page_resources() {
    local page_url=$1
    local page_name=$2

    echo "📄 Checking: $page_name"
    echo "   URL: $page_url"

    # Download the page
    local html=$(curl -s "$page_url")

    # Extract and check CSS files
    echo "  CSS files:"
    local css_files=$(echo "$html" | grep -o 'href="[^"]*\.css"' | sed 's/href="//;s/"$//')
    if [ -z "$css_files" ]; then
        echo "  ⚠️  No CSS files found"
    else
        for css in $css_files; do
            # Convert relative path to absolute URL
            if [[ "$css" == http* ]]; then
                check_url "$css" "External CSS"
            elif [[ "$css" == /* ]]; then
                check_url "$BASE_URL$css" "CSS"
            elif [[ "$css" == ../../* ]]; then
                # For pages in content.1bit/article/
                local base_path=$(echo "$page_url" | sed 's|/[^/]*$||' | sed 's|/[^/]*$||')
                local resolved=$(echo "$css" | sed 's|^\.\./\.\./||')
                check_url "$BASE_URL/$resolved" "CSS"
            else
                check_url "$BASE_URL/$css" "CSS"
            fi
        done
    fi

    # Extract and check image files
    echo "  Images:"
    local images=$(echo "$html" | grep -o 'src="[^"]*\.\(png\|jpg\|jpeg\|gif\|svg\)"' | sed 's/src="//;s/"$//')
    if [ -z "$images" ]; then
        echo "  ℹ️  No images found"
    else
        local img_count=0
        for img in $images; do
            img_count=$((img_count + 1))
            # Skip external images
            if [[ "$img" == http* ]]; then
                continue
            fi

            # Convert relative path to absolute URL
            if [[ "$img" == /* ]]; then
                check_url "$BASE_URL$img" "Image"
            elif [[ "$img" == ../../* ]]; then
                local resolved=$(echo "$img" | sed 's|^\.\./\.\./||')
                check_url "$BASE_URL/$resolved" "Image"
            else
                check_url "$BASE_URL/$img" "Image"
            fi

            # Limit output for pages with many images
            if [ $img_count -gt 5 ]; then
                echo "  ... (checking remaining images silently)"
                break
            fi
        done

        # Check remaining images silently
        for img in $images; do
            if [[ "$img" == http* ]]; then
                continue
            fi

            if [[ "$img" == /* ]]; then
                url="$BASE_URL$img"
            elif [[ "$img" == ../../* ]]; then
                local resolved=$(echo "$img" | sed 's|^\.\./\.\./||')
                url="$BASE_URL/$resolved"
            else
                url="$BASE_URL/$img"
            fi

            status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
            if [ "$status" != "200" ]; then
                echo "  ❌ $url (HTTP $status)"
                FAILED=$((FAILED + 1))
            fi
        done
    fi

    echo ""
}

# Test homepage
echo "=================================="
echo "Testing Homepage"
echo "=================================="
check_page_resources "$BASE_URL/" "Homepage (index.html)"

# Test main article pages
echo "=================================="
echo "Testing Article Pages"
echo "=================================="

ARTICLES=(
    "bom_programador:Como ser um bom programador"
    "programador:Como ser um programador"
    "flexibilidade:Poder e flexibilidade"
    "managed:Unmanaged e Managed"
    "nao_ouca_ninguem:Não ouça ninguém"
    "about:Sobre"
    "windbg1:WinDbg parte 1"
    "windbg2:WinDbg parte 2"
    "windbg3:WinDbg parte 3"
)

for article in "${ARTICLES[@]}"; do
    IFS=: read -r slug title <<< "$article"
    check_page_resources "$BASE_URL/content.1bit/$slug" "$title"
done

# Test using wget spider mode for thorough link checking
echo "=================================="
echo "Running wget Spider Check"
echo "=================================="
echo "This will recursively check all links..."
echo ""

# Create temp directory for wget output
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Run wget in spider mode
wget --spider \
     --recursive \
     --level=2 \
     --no-verbose \
     --no-directories \
     --delete-after \
     --timeout=10 \
     --tries=1 \
     "$BASE_URL/" 2>&1 | grep -E "(URL:|failed:|404)" | while read line; do
    if echo "$line" | grep -q "404\|failed"; then
        echo "❌ $line"
        FAILED=$((FAILED + 1))
    fi
done

cd - > /dev/null
rm -rf "$TEMP_DIR"

echo ""
echo "=================================="
echo "Summary"
echo "=================================="

if [ $FAILED -eq 0 ]; then
    echo "✅ All checks passed! Safe to deploy."
    exit 0
else
    echo "❌ Found $FAILED broken link(s)/resource(s)"
    echo "Please fix before deploying!"
    exit 1
fi
