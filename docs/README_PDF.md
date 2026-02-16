# Building PDF Documentation for JutulDarcy.jl

This directory contains scripts to build both the web-based documentation and a compiled PDF version.

**Note**: The repository includes a pre-built PDF (`JutulDarcy_Documentation.pdf`) in the root directory that is automatically updated via GitHub Actions whenever documentation changes are pushed to the main branch.

## What's Included in the PDF

The PDF documentation includes:

- **Introduction** - Overview of JutulDarcy.jl and its features
- **Getting Started** - Installation and basic setup
- **Your First Simulation** - Detailed walkthrough of a first example
- **FAQ** - Frequently asked questions
- **Fundamentals** - Core concepts (high-level overview, input files, systems, solutions)
- **Detailed API** - In-depth documentation (forces, wells, primary/secondary variables, parameters, plotting, utilities)
- **Parallelism and Compilation** - MPI, GPU, and compiled execution
- **References** - Package information, paper list, Jutul functions, and bibliography
- **Examples** - Complete code examples organized by category:
  - **Introduction** - Basic examples illustrating fundamental features
  - **Workflow** - Complete workflows and advanced use cases
  - **Data Assimilation** - History matching, optimization, and sensitivity analysis
  - **Geothermal** - Geothermal reservoir simulation
  - **Compositional** - Compositional flow and multi-component systems
  - **Discretization** - Different discretization schemes
  - **Properties** - Fluid properties and relationships
- **Validation** - Validation cases with comparisons to other simulators and benchmarks

For the full interactive examples with code execution, plots, and detailed output, visit https://sintefmath.github.io/JutulDarcy.jl/

## Building the PDF Documentation

There are two approaches to building PDF documentation for JutulDarcy.jl:

### Approach 1: Using Pandoc (Recommended - Simpler)

This approach converts the markdown files directly to PDF using Pandoc.

#### Prerequisites
- **Pandoc**: https://pandoc.org/installing.html
- **LaTeX Distribution** (for PDF output):
  - **Linux**: `sudo apt-get install texlive-full`
  - **macOS**: `brew install --cask mactex`
  - **Windows**: Install MiKTeX or TeX Live

#### Building with Pandoc

1. **Navigate to the docs directory:**
   ```bash
   cd docs/
   ```

2. **Run the build script:**
   
   **Option A - Using Make (simplest):**
   ```bash
   make pdf
   ```
   
   **Option B - Direct script execution:**
   ```bash
   bash build_pdf_pandoc.sh
   ```
   
   This will create `JutulDarcy_Documentation.pdf` in the `docs/` directory.

3. **Clean up (optional):**
   ```bash
   make clean
   ```

### Approach 2: Using Documenter.jl (Advanced)

This approach uses Julia's Documenter.jl to generate LaTeX documentation.

**Note**: Documenter.jl's LaTeX writer was moved to a separate package (DocumenterLaTeX.jl) which has compatibility issues with recent Documenter versions. This approach is provided for reference but may require additional setup.

#### Prerequisites
- Julia (already installed)
- LaTeX distribution (same as above)

#### Building with Documenter

1. **Navigate to the docs directory:**
   ```bash
   cd docs/
   ```

2. **Install Julia dependencies** (first time only):
   ```bash
   julia --project -e 'using Pkg; Pkg.instantiate()'
   ```

3. **Run the PDF build script:**
   ```bash
   julia --project make_pdf.jl
   ```

4. **Compile the generated LaTeX:**
   ```bash
   cd build/
   pdflatex JutulDarcy.jl.tex
   pdflatex JutulDarcy.jl.tex  # Run twice for references
   ```

## Files

- `make.jl` - Main documentation build script (generates HTML/Vitepress documentation)
- `make_pdf.jl` - PDF documentation build script using Documenter.jl (advanced, may have compatibility issues)
- `build_pdf_pandoc.sh` - Shell script to build PDF using Pandoc (recommended) - automatically calls the example generation scripts
- `generate_examples_for_pdf.jl` - Julia script that converts .jl example files to simplified markdown format for PDF inclusion
- `generate_example_overview.jl` - Julia script that generates the example overview page with listings by category
- `Makefile` - Simple Makefile for building PDF with `make pdf` command
- `Project.toml` - Julia dependencies for documentation building
- `package.json` - Node.js dependencies for Vitepress
- `src/` - Documentation source files (Markdown)
- `src/index_pdf.md` - PDF-friendly version of the index page
- `src/examples/` - Generated markdown files for examples (created by `generate_examples_for_pdf.jl`)

## How PDF Generation Works

The PDF generation process follows these steps:

1. **Generate Example Overview** (`generate_example_overview.jl`):
   - Creates a summary page listing all examples by category
   - Output: `src/examples/overview/example_overview.md`

2. **Generate Example Content** (`generate_examples_for_pdf.jl`):
   - Converts all `.jl` example files to simplified markdown
   - Preserves code structure, equations, and explanations
   - Follows Literate.jl markdown conventions
   - Output: 39 markdown files in `src/examples/*/` directories

3. **Build PDF** (`build_pdf_pandoc.sh`):
   - Calls the two generation scripts above
   - Collects all markdown files in the correct order:
     - Manual sections (Introduction, Fundamentals, API, Parallelism, References)
     - Example overview + all 39 example files across 7 categories
     - Validation intro + 9 validation examples
   - Uses Pandoc with XeLaTeX to generate the PDF with:
     - Table of contents (3 levels deep)
     - Section numbering
     - Syntax highlighting for code blocks
     - Support for Unicode and LaTeX equations

## Notes

- The Pandoc approach is **recommended** for most users as it's simpler and doesn't require Julia package resolution
- The PDF now includes **complete example code and validation cases** (39 examples + 9 validation models), not just overviews
- Examples are presented as code with explanations but without executed output (plots/results) to keep PDF size reasonable
- A pre-built PDF is available in the root directory of the repository (`JutulDarcy_Documentation.pdf`)
- The PDF is automatically regenerated by GitHub Actions when documentation or examples change on the main branch
- For the most up-to-date documentation with interactive examples, plots, and executed output, visit the online documentation at https://sintefmath.github.io/JutulDarcy.jl/

## Troubleshooting

### Missing LaTeX packages
If you get errors about missing LaTeX packages, install them using your LaTeX distribution's package manager:
- For TeX Live: `tlmgr install <package-name>`
- For MiKTeX: Packages are usually installed automatically when needed

### Pandoc not found
Install Pandoc from https://pandoc.org/installing.html

### Out of memory errors during LaTeX compilation
If the PDF compilation runs out of memory, you may need to:
1. Reduce the documentation content
2. Increase LaTeX's memory limits
3. Use a more powerful machine or cloud build service
