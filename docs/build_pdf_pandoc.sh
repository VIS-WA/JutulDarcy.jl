#!/bin/bash
# Build PDF documentation for JutulDarcy.jl using Pandoc
# This script collects all markdown documentation and compiles it to PDF

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building JutulDarcy.jl PDF Documentation${NC}"
echo "============================================="

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo -e "${RED}Error: pandoc is not installed${NC}"
    echo "Please install pandoc from https://pandoc.org/installing.html"
    exit 1
fi

# Check if xelatex is installed (required by pandoc for PDF output with Unicode)
if ! command -v xelatex &> /dev/null; then
    echo -e "${YELLOW}Warning: xelatex is not installed${NC}"
    echo "Pandoc requires a LaTeX engine for PDF output."
    echo "Please install a LaTeX distribution:"
    echo "  - Linux: sudo apt-get install texlive-xetex"
    echo "  - macOS: brew install --cask mactex"
    echo "  - Windows: Install MiKTeX or TeX Live"
    exit 1
fi

echo -e "${GREEN}Prerequisites check passed${NC}"

# Create temporary directory for processing
TMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TMP_DIR"

# Function to clean markdown files for Pandoc PDF generation
# Converts Documenter.jl-specific syntax to standard Pandoc markdown:
# - Display math: ```math ... ``` → $$ ... $$
# - Inline math: ``...`` → $...$
# - Removes any remaining @docs, @example, @raw, @bibliography, @autodocs blocks
#   (note: @docs blocks should already be resolved by resolve_docs_blocks.jl)
# - Cleans up @ref and @cite link syntax
clean_markdown() {
    local input="$1"
    local output="$2"
    local tmp1=$(mktemp)
    local tmp2=$(mktemp)

    # Pass 1: Remove 4-backtick Documenter.jl / Vitepress blocks
    sed -e '/^````@example/,/^````$/d' \
        -e '/^````@raw/,/^````$/d' \
        "$input" > "$tmp1"

    # Pass 2: Remove remaining Documenter.jl blocks that were not resolved
    sed -e '/^```@docs$/,/^```$/d' \
        -e '/^```@example/,/^```$/d' \
        -e '/^```@raw/,/^```$/d' \
        -e '/^```@bibliography/,/^```$/d' \
        -e '/^```@autodocs/,/^```$/d' \
        "$tmp1" > "$tmp2"

    # Pass 3: Convert math syntax, clean references, remove Vitepress syntax
    sed -e '/^```math$/,/^```$/{s/^```math$/\$\$/;s/^```$/\$\$/}' \
        -e 's/\[`\([^`]*\)`\](@ref[^)]*)/\1/g' \
        -e 's/\[\([^]]*\)\](@ref[^)]*)/\1/g' \
        -e 's/\[\([^]]*\)\](@cite[^)]*)/\1/g' \
        -e 's/``[[:space:]]*\([^`]*[^`[:space:]]\)[[:space:]]*``/$\1$/g' \
        -e '/^::: details/d' \
        -e '/^:::$/d' \
        "$tmp2" > "$output"

    rm -f "$tmp1" "$tmp2"
}

# Generate example overview first
echo "Generating example overview..."
julia generate_example_overview.jl

# Generate all example markdown files for PDF
echo "Generating example markdown files..."
julia generate_examples_for_pdf.jl

# Resolve @docs blocks: copy source tree and replace @docs with real docstrings
echo "Preparing source files..."
RESOLVED_SRC="$TMP_DIR/resolved_src"
cp -r src "$RESOLVED_SRC"

echo "Resolving @docs blocks (extracting docstrings)..."
if julia --project=. resolve_docs_blocks.jl "$RESOLVED_SRC" 2>&1; then
    echo -e "${GREEN}@docs blocks resolved successfully${NC}"
else
    echo -e "${YELLOW}Warning: Could not resolve @docs blocks. API documentation may be incomplete in the PDF.${NC}"
fi

# Use the resolved source tree for all subsequent file collection
SRC_DIR="$RESOLVED_SRC"

# Collect pages in the correct order following make.jl structure
echo "Collecting documentation pages..."
COUNTER=1

# 1. Introduction section (from index_pdf.md, or fallback to index.md)
if [ -f "$SRC_DIR/index_pdf.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/index_pdf.md" "$TMP_DIR/${padded}_index.md"
    echo "  Added: Introduction"
    COUNTER=$((COUNTER + 1))
elif [ -f "$SRC_DIR/index.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/index.md" "$TMP_DIR/${padded}_index.md"
    echo "  Added: Introduction (from index.md)"
    COUNTER=$((COUNTER + 1))
fi

# 2. Getting started
if [ -f "$SRC_DIR/man/intro.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/man/intro.md" "$TMP_DIR/${padded}_intro.md"
    echo "  Added: Getting started"
    COUNTER=$((COUNTER + 1))
fi

# 3. First example
if [ -f "$SRC_DIR/man/first_ex.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/man/first_ex.md" "$TMP_DIR/${padded}_first_ex.md"
    echo "  Added: Your first simulation"
    COUNTER=$((COUNTER + 1))
fi

# 4. FAQ
if [ -f "$SRC_DIR/extras/faq.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/extras/faq.md" "$TMP_DIR/${padded}_faq.md"
    echo "  Added: FAQ"
    COUNTER=$((COUNTER + 1))
fi

# 5. Fundamentals section
echo "  Section: Fundamentals"
for section in highlevel basics/input_files basics/systems basics/solution; do
    if [ -f "$SRC_DIR/man/$section.md" ]; then
        printf -v padded "%02d" $COUNTER
        clean_markdown "$SRC_DIR/man/$section.md" "$TMP_DIR/${padded}_$(basename $section).md"
        echo "    Added: man/$section.md"
        COUNTER=$((COUNTER + 1))
    fi
done

# 6. Detailed API section
echo "  Section: Detailed API"
for section in basics/forces basics/wells basics/primary basics/secondary basics/parameters basics/plotting basics/utilities; do
    if [ -f "$SRC_DIR/man/$section.md" ]; then
        printf -v padded "%02d" $COUNTER
        clean_markdown "$SRC_DIR/man/$section.md" "$TMP_DIR/${padded}_$(basename $section).md"
        echo "    Added: man/$section.md"
        COUNTER=$((COUNTER + 1))
    fi
done

# 7. Parallelism and compilation section
echo "  Section: Parallelism and compilation"
for section in advanced/mpi advanced/gpu advanced/compiled; do
    if [ -f "$SRC_DIR/man/$section.md" ]; then
        printf -v padded "%02d" $COUNTER
        clean_markdown "$SRC_DIR/man/$section.md" "$TMP_DIR/${padded}_$(basename $section).md"
        echo "    Added: man/$section.md"
        COUNTER=$((COUNTER + 1))
    fi
done

# 8. References section
echo "  Section: References"
if [ -f "$SRC_DIR/man/basics/package.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/man/basics/package.md" "$TMP_DIR/${padded}_package.md"
    echo "    Added: man/basics/package.md"
    COUNTER=$((COUNTER + 1))
fi

if [ -f "$SRC_DIR/extras/paper_list.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/extras/paper_list.md" "$TMP_DIR/${padded}_paper_list.md"
    echo "    Added: extras/paper_list.md"
    COUNTER=$((COUNTER + 1))
fi

if [ -f "$SRC_DIR/ref/jutul.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/ref/jutul.md" "$TMP_DIR/${padded}_jutul_ref.md"
    echo "    Added: ref/jutul.md"
    COUNTER=$((COUNTER + 1))
fi

if [ -f "$SRC_DIR/extras/refs.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/extras/refs.md" "$TMP_DIR/${padded}_refs.md"
    echo "    Added: extras/refs.md"
    COUNTER=$((COUNTER + 1))
fi

# 9. Examples section
echo "  Section: Examples"
if [ -f "$SRC_DIR/examples/overview/example_overview.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/examples/overview/example_overview.md" "$TMP_DIR/${padded}_example_overview.md"
    echo "    Added: examples/overview/example_overview.md"
    COUNTER=$((COUNTER + 1))
fi

# Add all example categories in order
for category in introduction workflow data_assimilation geothermal compositional discretization properties; do
    category_dir="$SRC_DIR/examples/$category"
    if [ -d "$category_dir" ]; then
        echo "  Subsection: $category examples"
        # Process all .md files in the category directory
        for ex_file in "$category_dir"/*.md; do
            if [ -f "$ex_file" ]; then
                ex_name=$(basename "$ex_file")
                printf -v padded "%02d" $COUNTER
                clean_markdown "$ex_file" "$TMP_DIR/${padded}_ex_${category}_${ex_name}"
                echo "    Added: examples/$category/$ex_name"
                COUNTER=$((COUNTER + 1))
            fi
        done
    fi
done

# 10. Validation section
echo "  Section: Validation"
if [ -f "$SRC_DIR/man/validation.md" ]; then
    printf -v padded "%02d" $COUNTER
    clean_markdown "$SRC_DIR/man/validation.md" "$TMP_DIR/${padded}_validation.md"
    echo "    Added: man/validation.md"
    COUNTER=$((COUNTER + 1))
fi

# Add validation examples
validation_dir="$SRC_DIR/examples/validation"
if [ -d "$validation_dir" ]; then
    echo "  Subsection: Validation models"
    for val_file in "$validation_dir"/*.md; do
        if [ -f "$val_file" ]; then
            val_name=$(basename "$val_file")
            printf -v padded "%02d" $COUNTER
            clean_markdown "$val_file" "$TMP_DIR/${padded}_val_${val_name}"
            echo "    Added: validation/$val_name"
            COUNTER=$((COUNTER + 1))
        fi
    done
fi

# Combine all markdown files
echo "Combining markdown files..."
COMBINED_MD="$TMP_DIR/combined.md"
cat $TMP_DIR/*.md > "$COMBINED_MD"

# Build PDF with pandoc
OUTPUT_PDF="JutulDarcy_Documentation.pdf"
echo -e "${GREEN}Building PDF with Pandoc...${NC}"
echo "This may take a few minutes..."

DOCS_DIR="$(cd "$(dirname "$0")" && pwd)"
pandoc "$COMBINED_MD" \
    -o "$OUTPUT_PDF" \
    --pdf-engine=xelatex \
    --resource-path="$DOCS_DIR:$DOCS_DIR/src:$DOCS_DIR/src/assets" \
    --include-in-header="$DOCS_DIR/pdf_header.tex" \
    --toc \
    --toc-depth=3 \
    --number-sections \
    --highlight-style=tango \
    --variable=geometry:margin=1in \
    --variable=documentclass:report \
    --variable=fontsize:11pt \
    --variable=papersize:letter \
    --metadata title="JutulDarcy.jl Documentation" \
    --metadata author="Olav Møyner and contributors" \
    --metadata date="$(date +%Y-%m-%d)" \
    2>&1 | grep -v "Missing character" || true

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$TMP_DIR"

if [ -f "$OUTPUT_PDF" ]; then
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}Success!${NC}"
    echo "PDF documentation created: $OUTPUT_PDF"
    echo "File size: $(du -h $OUTPUT_PDF | cut -f1)"
else
    echo -e "${RED}Error: PDF generation failed${NC}"
    exit 1
fi
