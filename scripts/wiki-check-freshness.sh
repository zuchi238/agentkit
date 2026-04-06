#!/usr/bin/env bash
# Check provenance freshness across all wiki pages.
# Compares source hashes in frontmatter against current file hashes.
# Usage: ./scripts/wiki-check-freshness.sh

set -euo pipefail

WIKI_DIR="wiki"
STALE=0
VALID=0
MISSING=0

echo "=== Wiki Freshness Check ==="
echo ""

# Find all wiki markdown files with source hashes in frontmatter
for wiki_file in $(find "$WIKI_DIR" -name "*.md" -type f); do
    # Extract source file/hash pairs from frontmatter
    in_frontmatter=false
    in_sources=false
    current_file=""

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if $in_frontmatter; then
                break  # End of frontmatter
            else
                in_frontmatter=true
                continue
            fi
        fi

        if $in_frontmatter; then
            if [[ "$line" =~ ^sources: ]]; then
                in_sources=true
                continue
            fi

            if $in_sources; then
                if [[ "$line" =~ ^[[:space:]]+- ]]; then
                    # Could be start of new source entry or a field
                    if [[ "$line" =~ file:[[:space:]]*\"?([^\"]+)\"? ]]; then
                        current_file="${BASH_REMATCH[1]}"
                    fi
                elif [[ "$line" =~ hash:[[:space:]]*\"?([a-f0-9]+)\"? ]]; then
                    expected_hash="${BASH_REMATCH[1]}"
                    if [[ -n "$current_file" ]]; then
                        if [[ -f "$current_file" ]]; then
                            actual_hash=$(sha256sum "$current_file" | cut -c1-8)
                            if [[ "$actual_hash" == "$expected_hash" ]]; then
                                ((VALID++))
                            else
                                echo "STALE: $wiki_file"
                                echo "  source: $current_file"
                                echo "  expected: $expected_hash  actual: $actual_hash"
                                echo ""
                                ((STALE++))
                            fi
                        else
                            echo "MISSING: $wiki_file"
                            echo "  source: $current_file (file not found)"
                            echo ""
                            ((MISSING++))
                        fi
                        current_file=""
                    fi
                elif [[ ! "$line" =~ ^[[:space:]] ]]; then
                    in_sources=false
                fi
            fi
        fi
    done < "$wiki_file"
done

echo "=== Summary ==="
echo "Valid:   $VALID"
echo "Stale:   $STALE"
echo "Missing: $MISSING"

if [[ $STALE -gt 0 || $MISSING -gt 0 ]]; then
    exit 1
fi
