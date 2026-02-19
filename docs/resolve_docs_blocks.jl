#!/usr/bin/env julia
# Resolve @docs blocks in markdown files by extracting Julia docstrings.
#
# Usage: julia --project=. resolve_docs_blocks.jl <directory>
#
# Processes all .md files in the given directory **in-place**, replacing
#   ```@docs
#   SymbolName
#   ```
# with the actual docstring text formatted for Pandoc/LaTeX consumption.
#
# This script is called by build_pdf_pandoc.sh during PDF generation.

println("Loading packages for docstring resolution...")
using JutulDarcy
using Jutul

"""
    resolve_symbol(symbol_str)

Try to obtain the Julia object referred to by `symbol_str`.
Handles module-qualified names like `JutulDarcy.FluidVolume` and
sub-module paths like `JutulDarcy.CO2Properties.pvt_co2_RedlichKwong1949`.
"""
function resolve_symbol(symbol_str::AbstractString)
    symbol_str = strip(symbol_str)
    isempty(symbol_str) && return nothing
    try
        return Core.eval(Main, Meta.parse(symbol_str))
    catch
        return nothing
    end
end

"""
    get_docstring_md(symbol_str)

Return a Pandoc-friendly markdown block for one symbol.
"""
function get_docstring_md(symbol_str::AbstractString)
    sym_clean = strip(symbol_str)
    isempty(sym_clean) && return ""

    obj = resolve_symbol(sym_clean)
    if obj === nothing
        return "**`$sym_clean`**\n\n*Documentation not available.*\n\n---\n\n"
    end

    doc_text = try
        d = Base.Docs.doc(obj)
        text = string(d)
        startswith(text, "No documentation found") ? nothing : text
    catch
        nothing
    end

    result = "**`$sym_clean`**\n\n"
    if doc_text !== nothing
        # Clean Documenter.jl cross-references that Pandoc cannot resolve
        cleaned = doc_text
        cleaned = replace(cleaned, r"\[`([^`]*)`\]\(@ref[^)]*\)" => s"`\1`")
        cleaned = replace(cleaned, r"\[([^\]]*)\]\(@ref[^)]*\)"  => s"\1")
        cleaned = replace(cleaned, r"\[([^\]]*)\]\(@cite[^)]*\)" => s"\1")
        result *= cleaned * "\n\n"
    else
        result *= "*No docstring available.*\n\n"
    end
    result *= "---\n\n"
    return result
end

const DOCS_BLOCK_RE = r"```@docs\s*\n(.*?)```"s

"""
    resolve_docs_in_content(content)

Replace every ``` @docs ... ``` block in `content` with resolved docstrings.
"""
function resolve_docs_in_content(content::AbstractString)
    return replace(content, DOCS_BLOCK_RE => function(m)
        block = match(DOCS_BLOCK_RE, m).captures[1]
        symbols = filter(!isempty, strip.(split(block, "\n")))
        join(get_docstring_md.(symbols), "")
    end)
end

"""
    process_directory(dir)

Walk `dir`, resolve `@docs` blocks in every `.md` file **in-place**.
"""
function process_directory(dir::AbstractString)
    count = 0
    for (root, dirs, files) in walkdir(dir)
        for file in files
            endswith(file, ".md") || continue
            filepath = joinpath(root, file)
            content = read(filepath, String)
            if occursin(r"```@docs", content)
                resolved = resolve_docs_in_content(content)
                write(filepath, resolved)
                println("  Resolved: $(relpath(filepath, dir))")
                count += 1
            end
        end
    end
    println("Resolved @docs blocks in $count file(s).")
end

if length(ARGS) < 1
    println(stderr, "Usage: julia --project=. resolve_docs_blocks.jl <directory>")
    exit(1)
end

process_directory(ARGS[1])
