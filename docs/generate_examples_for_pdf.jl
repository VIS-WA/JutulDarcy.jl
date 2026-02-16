#!/usr/bin/env julia

# Generate simplified example markdown files for PDF documentation
# 
# This script converts .jl example files to markdown format suitable for PDF
# without requiring code execution (which would be needed for full Literate.jl processing).
#
# The script processes all examples in the ../examples/ directory and generates
# simplified markdown versions in src/examples/ that include:
# - Code blocks with syntax
# - Text explanations (from # comments in Literate.jl format)
# - Equations in LaTeX format
# - Structure and organization
#
# Output: 39+ markdown files in src/examples/category/*.md
#
# This script is automatically called by build_pdf_pandoc.sh during PDF generation.

using Pkg
# Only use base Julia functionality to avoid dependencies

function get_example_categories()
    basepth = joinpath(@__DIR__, "..", "examples")
    categories = String[]
    for item in readdir(basepth)
        itempath = joinpath(basepth, item)
        if isdir(itempath)
            push!(categories, item)
        end
    end
    sort!(categories)
    return categories
end

function get_example_files(category)
    basepth = joinpath(@__DIR__, "..", "examples", category)
    examples = String[]
    for file in readdir(basepth)
        if endswith(file, ".jl")
            push!(examples, first(splitext(file)))
        end
    end
    sort!(examples)
    return examples
end

function parse_tags(line)
    # Match the pattern <tags: ...> and extract the content
    m = match(r"<tags:\s*([^>]+)>", line)
    if !isnothing(m)
        tags = strip.(split(m.captures[1], ","))
        return tags
    end
    return nothing
end

"""
    convert_jl_to_markdown(input_path, output_path, category, exname)

Convert a .jl example file to markdown format for PDF.

This is a simplified conversion that doesn't execute code but preserves structure.
Follows Literate.jl conventions:
- Lines starting with "# " are markdown content
- Lines starting with "#" alone are paragraph breaks (become blank lines)
- Other lines are Julia code
"""
function convert_jl_to_markdown(input_path, output_path, category, exname)
    lines = readlines(input_path)
    
    open(output_path, "w") do out
        in_code_block = false
        found_title = false
        code_buffer = String[]
        
        # Helper function to flush code buffer
        function flush_code_buffer()
            if !isempty(code_buffer) && any(strip(l) != "" for l in code_buffer)
                println(out, "")
                println(out, "```julia")
                for buffered_line in code_buffer
                    println(out, buffered_line)
                end
                println(out, "```")
                empty!(code_buffer)
            else
                empty!(code_buffer)
            end
        end
        
        for (i, line) in enumerate(lines)
            # Skip lines with <tags:...> as they're internal
            if occursin(r"<tags:", line)
                continue
            end
            
            # Check line type
            if startswith(line, "# ")
                # This is markdown content in Literate format
                # Flush any pending code
                if in_code_block
                    flush_code_buffer()
                    in_code_block = false
                end
                
                markdown_line = line[3:end]  # Remove "# "
                println(out, markdown_line)
                
                # Check if this is the title (first # line)
                if !found_title && startswith(markdown_line, "#")
                    found_title = true
                end
            elseif line == "#" || strip(line) == "#"
                # This is a paragraph break in Literate format
                # Flush code if needed and add blank line
                if in_code_block
                    flush_code_buffer()
                    in_code_block = false
                end
                println(out, "")
            else
                # This is code (or possibly a regular comment within code)
                # Skip empty lines at the start if we haven't seen title
                if !found_title && strip(line) == ""
                    continue
                end
                
                # Add to code buffer
                if strip(line) != "" || in_code_block
                    in_code_block = true
                    push!(code_buffer, line)
                end
            end
        end
        
        # Flush any remaining code
        if in_code_block
            flush_code_buffer()
        end
        
        # Add footer with link to online version
        println(out, "")
        println(out, "---")
        println(out, "")
        println(out, "*Note: This is a simplified version for the PDF documentation. ")
        println(out, "For the full interactive example with code execution, plots, and detailed output, ")
        println(out, "please visit the [online documentation](https://sintefmath.github.io/JutulDarcy.jl/dev/examples/$category/$exname/).*")
    end
    
    return true
end

function category_title(cat)
    return titlecase(replace(cat, "_" => " "))
end

"""
    generate_all_examples()

Generate markdown files for all examples in all categories.

Processes all .jl files in ../examples/ and creates simplified markdown versions
in src/examples/ suitable for PDF documentation.

Returns the total number of examples generated.
"""
function generate_all_examples()
    println("Generating example markdown files for PDF documentation...")
    
    # Create output directory
    outdir = joinpath(@__DIR__, "src", "examples")
    mkpath(outdir)
    
    categories = get_example_categories()
    total_examples = 0
    
    for category in categories
        println("\nProcessing category: $category")
        
        # Create category output directory
        cat_outdir = joinpath(outdir, category)
        mkpath(cat_outdir)
        
        examples = get_example_files(category)
        
        for exname in examples
            input_path = joinpath(@__DIR__, "..", "examples", category, "$exname.jl")
            output_path = joinpath(cat_outdir, "$exname.md")
            
            try
                convert_jl_to_markdown(input_path, output_path, category, exname)
                println("  ✓ Generated: $exname.md")
                total_examples += 1
            catch e
                println("  ✗ Failed to generate $exname.md: $e")
            end
        end
    end
    
    println("\n" * "="^60)
    println("Successfully generated $total_examples example markdown files")
    println("="^60)
    
    return total_examples
end

# Run the generation when script is executed directly
if abspath(@__FILE__) == abspath(PROGRAM_FILE)
    generate_all_examples()
end
