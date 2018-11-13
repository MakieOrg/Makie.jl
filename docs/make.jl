using Documenter, Makie
using Markdown, Pkg, Random, FileIO
cd(@__DIR__)
include("../examples/library.jl")
include("documenter_extension.jl")
import AbstractPlotting: _help, to_string, to_func, to_type

pathroot = normpath(joinpath(dirname(pathof(Makie)), ".."))
docspath = joinpath(pathroot, "docs")
srcpath = joinpath(pathroot, "docs", "src")
srcmediapath = joinpath(pathroot, "docs", "media")
buildpath = joinpath(pathroot, "docs", "build")
mediapath = joinpath(pathroot, "docs", "build", "media")
expdbpath = joinpath(buildpath, "examples-database.html")
# TODO can we teach this to documenter somehow?
ispath(mediapath) || mkpath(mediapath)


function output_path(entry, ending; subdir = nothing)
    if subdir == nothing
        joinpath(mediapath, string(entry.unique_name, ending))
    else
        joinpath(mediapath, subdir, string(entry.unique_name, ending))
    end
end


function save_example(entry, x::Scene)
    path = output_path(entry, ".jpg")
    save(path, x)
    path
end

save_example(entry, x::String) = x # nothing to do

function save_example(entry, x::Makie.Stepper) #TODO: this breaks thumbnail generation
    # return a list of all file names
    path = [output_path(entry, "-$i.jpg"; subdir = string(entry.unique_name)) for i = 1:x.step - 1]
    return path
end
function save_example(example, events::RecordEvents) #TODO: this breaks thumbnail generation
    # the path is fixed at record time to be stored relative to the example
    epath = event_path(example, "")
    isfile(epath) || error("Can't find events for example. Please run `record_example_events()`")
    # the current path of RecordEvents is where we now actually want to store the video
    video_path = output_path(example, ".mp4")
    record(events.scene, video_path) do io
        replay_events(events.scene, epath) do
            recordframe!(io)
        end
    end
    return video_path
end

#pkg"add ModernGL MeshIO ImageMagick ImageFilter ImageTransformations GDAL"

AbstractPlotting.set_theme!(resolution = (500, 500))

# you can restart the build, if something failed, by just searching for the index you ended with, and putting it into start
findfirst(x-> x.title == "WorldClim visualization", database)

eval_examples(outputfile = output_path) do example, value
    AbstractPlotting.set_theme!(resolution = (500, 500))
    Random.seed!(42)
    path = save_example(example, value)
    if isa(value, Makie.Stepper)
        name = [string.("thumb-", example.unique_name, "-$i", ".jpg") for i = 1:value.step - 1]
    else
        name = string("thumb-", example.unique_name, ".jpg")
    end
    try
        generate_thumbnail.(path, joinpath.(dirname.(path), name))
    catch e
        @warn("generate_thumbnail failed with path $path, entry $(example.unique_name), and filename $name")
        Base.showerror(stderr, e)
        println(stderr)
        Base.show_backtrace(stderr, Base.catch_backtrace())
        println(stderr)
    end
end

# =============================================
# automatically generate an overview of the atomic functions, using a source md file
@info("Generating functions overview")
path = joinpath(srcpath, "functions-overview.md")
srcdocpath = joinpath(srcpath, "src-functions.md")
plotting_functions = (atomics..., contour, arrows, barplot, poly, band, slider, vbox)
open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    medialist = readdir(mediapath)
    isempty(medialist) && error("media folder is empty -- perhaps you forgot to generate the plots? :)")
    println(io, "# Atomic functions overview")
    src = read(srcdocpath, String)
    println(io, src)
    print(io, "\n")
    for func in plotting_functions
        fname = to_string(func)
        expdbpath = joinpath(buildpath, "examples-$fname.html")
        println(io, "## `$fname`\n")
        try
            println(io, "```@docs")
            println(io, "$fname")
            println(io, "```\n")
            help_attributes(io, func; extended = true)
            embed_thumbnail_link(io, func, buildpath, expdbpath)
        catch e
            println("ERROR: Didn't work with $fname\n")
            Base.showerror(stderr, e)
        end
        println(io, "\n")
    end
end

# =============================================
# automatically generate gallery based on looping through the database
# using pre-generated plots from generate_plots.jl
cd(docspath)
example_pages = nothing
example_list = String[]
to_string(x::Symbol) = string(x)

for func in (plotting_functions..., :interaction)
    fname = to_string(func)
    @info("Generating examples gallery for $fname")
    path = joinpath(srcpath, "examples-$fname.md")
    indices = find_indices(func)
    open(path, "w") do io
        println(io, "# `$fname`")
        examples2source(fname, scope_start = "", scope_end = "", indent = "") do entry, source
            # print bibliographic stuff
            println(io, "## $(entry.title)")
            print(io, "Tags: ")
            tags = sort(collect(entry.tags))
            for j = 1:length(tags) - 1; print(io, "`$(tags[j])`, "); end
            println(io, "`$(tags[end])`.\n")
            uname = string(entry.unique_name)
            src_lines = entry.file_range
            println(io, """
                ```julia
                $source
                ```
                """
            )
            embed_plot(io, uname, mediapath, buildpath; src_lines = src_lines)
        end
    end
    push!(example_list, "examples-$fname.md")
end
example_list

# =============================================
# automatically generate an overview of the plot attributes (keyword arguments), using a source md file
@info("Generating attributes page")
include("../src/plot_attr_desc.jl")
path = joinpath(srcpath, "plot-attributes.md")
srcdocpath = joinpath(srcpath, "src-plot-attributes.md")
open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    println(io, "# Plot attributes")
    src = read(srcdocpath, String)
    println(io, src)
    print(io, "\n")
    println(io, "## List of attributes")
    print_table(io, plot_attr_desc)
end

# =============================================
# automatically generate an overview of the axis attributes, using a source md file
@info("Generating axis page")
path = joinpath(srcpath, "axis.md")
srcdocpath = joinpath(srcpath, "src-axis.md")
include("../src/Axis2D_attr_desc.jl")
include("../src/Axis3D_attr_desc.jl")

open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    src = read(srcdocpath, String)
    println(io, src)
    print(io)
    # Axis2D section
    println(io, "## `Axis2D`")
    println(io, "### `Axis2D` attributes groups")
    print_table(io, Axis2D_attr_desc)
    print(io)
    for (k, v) in Axis2D_attr_groups
        println(io, "#### `:$k`\n")
        print_table(io, v)
        println(io)
    end
    # Axis3D section
    println(io, "## `Axis3D`")
    println(io, "### `Axis3D` attributes groups")
    print_table(io, Axis3D_attr_desc)
    print(io)
    for (k, v) in Axis3D_attr_groups
        println(io, "#### `:$k`\n")
        print_table(io, v)
        println(io)
    end
end

# automatically generate an overview of the function signatures, using a source md file
@info("Generating signatures page")
path = joinpath(srcpath, "signatures.md")
srcdocpath = joinpath(srcpath, "src-signatures.md")
open(path, "w") do io
    !ispath(srcdocpath) && error("source document doesn't exist!")
    println(io, "# Plot function signatures")
    src = read(srcdocpath, String)
    println(io, src)
    print(io, "\n")
    println(io, "```@docs")
    println(io, "convert_arguments")
    println(io, "```\n")

    println(io, "See [Plot attributes](@ref) for the available plot attributes.")
end

# build docs with Documenter
@info("Running `makedocs` with Documenter.")
makedocs(
    modules = [Makie, AbstractPlotting],
    doctest = false, clean = false,
    format = :html,
    sitename = "Makie.jl",
    html_prettyurls = false,
    pages = Any[
        "Home" => "index.md",
        "Basics" => [
            "basic-tutorials.md",
            "help_functions.md",
            "functions-overview.md",
            "signatures.md",
            "plot-attributes.md",
            # "extending.md",
            "axis.md",
            "interaction.md",
            "output.md",
            # "layout.md"
        ],
        # atomics_pages,
        "Examples" => [
            "index-examples.md",
            example_list...
        ],
        "Developer Documentation" => [
            "why-makie.md",
        #     "devdocs.md",
        ],
    ]
)
using Conda, Documenter
# deploy
ENV["DOCUMENTER_DEBUG"] = "true"
if !haskey(ENV, "DOCUMENTER_KEY")
    # Workaround for when deploying locally and silly Windows truncating the env variable
    # on the CI these should be set!
    ENV["TRAVIS_BRANCH"] = "latest"
    ENV["TRAVIS_PULL_REQUEST"] = "false"
    ENV["TRAVIS_REPO_SLUG"] = "github.com/JuliaPlots/Makie.jl.git"
    ENV["TRAVIS_TAG"] = "v1.0.0"
    ENV["TRAVIS_OS_NAME"] = ""
    ENV["TRAVIS_JULIA_VERSION"] = ""
    ENV["PATH"] = string(ENV["PATH"], Sys.iswindows() ? ";" : ":", Conda.SCRIPTDIR)
    ENV["DOCUMENTER_KEY"] = open(x->String(read(x)), joinpath(homedir(), "documenter.key"))
end



#run(`pip install --upgrade pip`)

deploydocs(
    deps = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-cinder"),
    repo = "github.com/JuliaPlots/Makie.jl.git",
    devbranch = "master",
    target = "build",
    make = nothing
)
