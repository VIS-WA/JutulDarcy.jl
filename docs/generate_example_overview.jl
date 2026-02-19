#!/usr/bin/env julia

# Simple script to generate an example overview for the PDF
# This doesn't require any dependencies

function get_example_files()
    basepth = joinpath(@__DIR__, "..", "examples")
    examples = Dict{String, Vector{Tuple{String,String}}}()

    categories = ["introduction", "workflow", "data_assimilation", "geothermal",
                  "compositional", "discretization", "properties", "validation"]

    for category in categories
        catpath = joinpath(basepth, category)
        if isdir(catpath)
            examples[category] = Tuple{String,String}[]
            for file in readdir(catpath)
                if endswith(file, ".jl")
                    filename = first(splitext(file))
                    title = extract_title(joinpath(catpath, file), filename)
                    push!(examples[category], (filename, title))
                end
            end
            sort!(examples[category], by = first)
        end
    end

    return examples, categories
end

function extract_title(filepath, fallback)
    # Read the first Literate.jl markdown heading (# # Title)
    for line in eachline(filepath)
        if startswith(line, "# #")
            # Strip leading "# " (Literate comment) and "#" (markdown heading)
            title = strip(replace(line, r"^#\s*#+" => ""))
            if !isempty(title)
                return title
            end
        end
    end
    # Fallback: convert filename to a readable title
    return titlecase(replace(fallback, "_" => " "))
end

function category_title(cat)
    return titlecase(replace(cat, "_" => " "))
end

function write_example_overview()
    examples, categories = get_example_files()

    outdir = joinpath(@__DIR__, "src", "examples", "overview")
    mkpath(outdir)
    outpath = joinpath(outdir, "example_overview.md")

    open(outpath, "w") do io
        println(io, "# Example Overview\n")
        println(io, "JutulDarcy.jl comes with a number of examples that illustrate different features of the simulator.\n")
        println(io, "The examples are organized by category. Each example listed below has its own section with source code and explanations later in this document. For the full interactive examples with plots and outputs, please visit the online documentation at https://sintefmath.github.io/JutulDarcy.jl/\n")

        for category in categories
            if haskey(examples, category) && !isempty(examples[category])
                println(io, "## $(category_title(category))\n")

                # Add category descriptions
                if category == "introduction"
                    println(io, "Basic examples that illustrate fundamental features of JutulDarcy.jl.\n")
                elseif category == "workflow"
                    println(io, "Examples demonstrating complete workflows and advanced use cases.\n")
                elseif category == "data_assimilation"
                    println(io, "Examples of history matching, optimization, and sensitivity analysis.\n")
                elseif category == "geothermal"
                    println(io, "Geothermal reservoir simulation examples.\n")
                elseif category == "compositional"
                    println(io, "Compositional flow and multi-component examples.\n")
                elseif category == "discretization"
                    println(io, "Examples showing different discretization schemes.\n")
                elseif category == "properties"
                    println(io, "Examples focusing on fluid properties and relationships.\n")
                elseif category == "validation"
                    println(io, "Validation cases comparing with other simulators and benchmarks.\n")
                end

                for (filename, title) in examples[category]
                    println(io, "- **$title**")
                end
                println(io, "")
            end
        end
    end

    println("Generated example overview at: $outpath")
end

# Run the function
write_example_overview()
