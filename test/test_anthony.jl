# =========== temp

println(Base.Docs.doc(scatter))
println(Main.Docs.doc(Makie.convert_arguments, Tuple{Any, AbstractMatrix}))
println(Base.Docs.doc(Makie.convert_arguments, Tuple{Any, AbstractVector, AbstractVector, AbstractMatrix}))
println(Base.Docs.doc(Makie.convert_arguments, Tuple{Any, AbstractVector, AbstractVector, Function}))

const atomics = (
    heatmap,
    image,
    lines,
    linesegments,
    mesh,
    meshscatter,
    scatter,
    surface,
    text,
    Makie.volume
)


# =============================================
# Trying out heatmap plot from all_samples.jl
path = joinpath(@__DIR__, "..", "docs", "test")
scene = Scene(resolution = (500, 500))
scene = heatmap!(scene, rand(32, 32))
save("heatmap.png", scene)


path = joinpath(@__DIR__, "..", "docs", "test")
# save("heatmap.png", scene)
img = Makie.scene2image(scene)
save(path, img)


# =============================================
# Print code for when database search returns multiple results

# First find those damn entries!
entries = example_database(lines)
entries = find(x -> x.title == database_key, database)
entries = find(x -> x.tags == "scatter", database)
entries = find(x -> contains(collect(x.tags), "scatter"), database)

tgs = database[2].tags

contains(tgs, "scatter")

find(database) do entry
    # find tags
    tags_found = any(tag -> string(tag) in entry.tags, "scatter")
end

len_entries = length(entries)
println("len_entries = ", len_entries)

for i = 1:len_entries
    # println(x.title)
    # println(x.source)
    println("i = ", i)
    sprint() do io
        print_code(
            io, database, entries[1],
            scope_start = "",
            scope_end = "",
            indent = "",
            resolution = (entry)-> "resolution = (500, 500)",
            outputfile = (entry, ending)-> Pkg.dir("Makie", "docs", "media", string(entry.unique_name, ending))
        )
    end
end



sprint(print_code(STDOUT, database, entries[1],
scope_start = "",
scope_end = "",
indent = "",
resolution = (entry)-> "resolution = (500, 500)",
outputfile = (entry, ending)-> Pkg.dir("Makie", "docs", "media", string(entry.unique_name, ending))
))
