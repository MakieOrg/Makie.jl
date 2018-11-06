import Makie

struct CellEntry
    author::String
    title::String
    unique_name::Symbol
    tags::Set{String}
    file::String
    file_range::UnitRange{Int}
    toplevel::String # e.g. using statements
    source::String # the actual source
    groupid::Int
end

function Base.merge(x::Vector{CellEntry})
    e1 = first(x)
    CellEntry(
        e1.author,
        e1.title,
        e1.unique_name,
        unique(map(x-> x.tags, x)),
        e1.file,
        e1.file_range,
        join(map(x-> x.toplevel, x), "\n"),
        join(map(x-> x.source, x), "\n"),
        NO_GROUP
    )
end
isgroup(x::CellEntry) = x.groupid != NO_GROUP

# overload Base.show to show output of CellEntry
function Base.show(io::IO, ::MIME"text/plain", entry::CellEntry)
    println(io, "```")
    println(io, entry.source)
    println(io, "```")
end

function Base.show(io::IO, ::MIME"text/plain", entries::Array{CellEntry,1})
    for entry in entries
        println(io, "```")
        println(io, entry.source)
        println(io, "```")
        println(io, "\n\n")
    end
end

function Base.show(io::IO, ::MIME"text/markdown", entry::CellEntry)
    println(io, "```")
    println(io, entry.source)
    println(io, "```")
end

# ==========================================================
# Print source code given database index

function _print_source(io::IO, idx::Int; style = nothing, example_counter = NaN)
    if isnan(example_counter)
        println(io, style == nothing ? "```" :
            style == "source" ? "```" :
            style == "julia" ? "```julia" :
            style == "eval" ? "```@eval" :
            style == "example" ? "```@example" : "" )
        # println(io, isempty(database[idx].toplevel) ? "using Makie, AbstractPlotting, GeometryTypes" : "$(database[idx].toplevel)")
        print(io, isempty(database[idx].toplevel) ? "" : "$(database[idx].toplevel)\n")
        for line in split(database[idx].source, "\n")
            line = replace(line, "@resolution" => "resolution = (500, 500)")
            println(io, line)
        end
        println(io, "```")
    else
        println(io, style == nothing ? "```" :
            style == "source" ? "```" :
            style == "julia" ? "```julia" :
            style == "eval" ? "```@eval" :
            style == "example" ? "```@example $(example_counter)" : "" )
        # println(io, isempty(database[idx].toplevel) ? "using Makie, AbstractPlotting, GeometryTypes" : "$(database[idx].toplevel)")
        print(io, isempty(database[idx].toplevel) ? "" : "$(database[idx].toplevel)\n")
        for line in split(database[idx].source, "\n")
            line = replace(line, "@resolution" => "resolution = (500, 500)")
            println(io, line)
        end
        println(io, "```")
    end
end

"""
    print_source(io::IO, idx::Int; style = nothing, example_counter = NaN)

Print source code of database (hard coded internally) at given index `idx`.
`style` options are:
* nothing -> default, prints a quoted code block
* "source" -> same behaviour as default
* "julia" -> prints a julia code block (i.e. ```julia)
* "example" -> prints an example code block (i.e. ```example)

`example_counter` can optionally print an example number (useful for Documenter example blocks), e.g.:
* ```example 1
* ```example 2
* some explanation text
* ```example 2 # continuation of the same example - more code to be evaluated
"""
function print_source(io::IO, idx::Int; style = nothing, example_counter = NaN)
    io = IOBuffer()
    _print_source(io, idx; style = style, example_counter = example_counter)
    Base.Markdown.parse(String(take!(io)))
end

print_source(idx; kw_args...) = print_source(stdout, idx; kw_args...) #defaults to STDOUT


"""
    find_indices(input_tags...; title = nothing, author = nothing, match = all)

Returns the indices for the entries in examples database that match the input
search pattern.

`input_tags` are plot tags to be searched for. `title` and `author` are optional
and are used to filter the search results by title and author.
`match` specifies a matching function, e.g. any/all which gets applied to the input tags.
"""
function find_indices(input_tags::NTuple{N, String}; title = nothing, author = nothing, match::Function = all) where N # --> return an array of cell entries
    indices = findall(database) do entry
        tags_found = match(tags -> tags in entry.tags, input_tags)
        # find author, if nothing input is given, then don't filter
        author_found = (author == nothing) || (entry.author == string(author))
        # find title, if nothing input is given, then don't filter
        title_found = (title == nothing) || (entry.title == string(title))
        # boolean to return the result
        tags_found && author_found && title_found
    end
    if isempty(indices)
        @warn("no examples found matching the search criteria $(input_tags), title = $(repr(title)), author = $(repr(author))")
        indices
    else
        indices
    end
end

to_tag(x::Union{Symbol, String}) = string(x)
to_tag(x::Function) = AbstractPlotting.to_string(x)

find_indices(tags...; kw_args...) = find_indices(to_tag.(tags); kw_args...)


"""
    example_database(input_tags...; title = nothing, author = nothing, match_all = true)

Returns the entries in examples database that match the input search pattern.

`input_tags` are plot tags to be searched for. `title` and `author` are optional
and are used to filter the search results by title and author.
`match_all` specifies if the result has to match all input tags, or just any.
"""
function example_database(tags::NTuple{N, String}; kw_args...) where N # --> return an array of cell entries
    indices = find_indices(tags; kw_args...)
    if !isempty(indices)
        database[indices]
    end
end
function example_database(input_tags::Union{Symbol, String}...; kw_args...) # --> return an array of cell entries
    example_database(string.(input_tags); kw_args...)
end

example_database(input::Function; kw_args...) = example_database((to_string(input),); kw_args...)
example_database(a::Function, rest::Function...; kw_args...) = example_database(to_string.((a, rest...,)); kw_args...)

database = CellEntry[]
tags_list = []
globaly_shared_code = String[]
const NO_GROUP = 0
unique_names = Set(Symbol[])
function unique_name!(name, unique_names = unique_names)
    funcname = Symbol(replace(lowercase(string(name)), r"[ #$!@#$%^&*()+]" => '_'))
    i = 1
    while isdefined(Makie, funcname) || (funcname in unique_names)
        funcname = Symbol("$(funcname)_$i")
        i += 1
    end
    push!(unique_names, funcname)
    funcname
end

function CellEntry(author, title, tags, file, file_range, toplevel, source, groupid = NO_GROUP)
    uname = unique_name!(title)
    CellEntry(string(author), title, uname, tags, file, file_range, toplevel, source, groupid)
end


"""
Prints the source of an entry in the database at `idx`.
This puts entries of a group into one local scope
"""
function print_code(
        io, entry;
        scope_start = "begin\n",
        scope_end = "end\n",
        indent = " "^4,
        replace_nframes = false,
        resolution = (entry)-> "resolution = (500, 500)",
        outputfile = (entry, ending)-> "./docs/media/" * string(entry.unique_name, ending)
    )
    println(io, "using Makie")
    println(io, entry.toplevel)
    print(io, scope_start)
    for line in split(entry.source, "\n")
        line = replace(line, "@resolution" => resolution(entry))
        filematch = match(r"(@replace_with_a_path)(\(.+?\))?" , line)
        if filematch != nothing
            ending = filematch.captures[2]
            replacement = outputfile(entry, ending == nothing ? "" : "."*ending[2:end-1])
            line = replace(
                line,
                r"(@replace_with_a_path)(\(.+?\))?" => string('"', escape_string(replacement), '"')
            )
        end
        if replace_nframes
            line = replace(line, r"(record\(.*)N(.*\) do .*)" => s"\1 10 \2")
        end
        println(io, indent, line)
    end
    print(io, scope_end)
    return
end

extract_tags(expr::Vector) = Set(String.(expr))
function extract_tags(expr)
    if !any(x-> isa(x, String) || isa(x, Symbol), expr.args) || expr.head != :vect
        error("Tags need to be an array of strings/variables. Found: $(expr)")
    end
    Set(String.(expr.args))
end

function findspace(line)
    space_len = 0
    c_s = iterate(line)
    c_s === nothing && return 0
    c, s = c_s
    while c == ' '
        space_len += 1
        c_s = iterate(line, s)
        c_s === nothing && break
        c, s = c_s
    end
    space_len -= 1
    space_len
end

function printline(line, toplevel, source, start_indent)
    # if space_len not defined yet, find it!
    if start_indent == -1 && length(line) > 4
        start_indent = findspace(line)
    end
    if start_indent != -1 && length(line) >= start_indent && all(x-> x == ' ', line[1:start_indent])
        # remove all spaces of first indent
        line = line[(start_indent+1):end]
    end
    if occursin(r"using|import", line)
        println(toplevel, line)
    else
        println(source, line)
    end
    start_indent
end

"""
We could just use the AST of the macro, but since we're interested to also capture
comments and formatting for e.g. docs, we need to extract the source directly
from the file!
"""
function extract_source(file, file_range)
    source = IOBuffer()
    toplevel = IOBuffer()
    open(file) do io
        start_indent = -1
        for (i, line) in enumerate(eachline(io))
            i < minimum(file_range) && continue
            # allow to parse past maximum(file_range) until next end
            if i > maximum(file_range) && occursin("end", line)
                if length(line) > start_indent && line[start_indent] == ' '
                    # if end is on start indention level,
                    # this isn't the macro end and needs to be part of source
                    println(source, "end")
                end
                break
            else
                start_indent = printline(line, toplevel, source, start_indent)
            end
        end
    end
    String(take!(toplevel)), String(take!(source))
end


is_cell(x::Expr) = x.head == :macrocall && x.args[1] == Symbol("@cell")
is_cell(x) = false

is_group(x::Expr) = x.head == :macrocall && x.args[1] == Symbol("@group")
is_group(x) = false

is_linenumber(x) = false
is_linenumber(x::LineNumberNode) = true

find_lastline(arg::Any) = 0
function find_lastline(arg::Expr)
    find_lastline(arg.args)
end
function find_lastline(args::Vector)
    isempty(args) && return 0
    idx = findlast(is_linenumber, args)
    line_number = if idx == nothing
        0
    else
        args[idx].line
    end
    max(mapreduce(find_lastline, max, args), line_number)
end
function find_startend(args::Vector)
    firstline = args[findfirst(is_linenumber, args)]
    first_linenumber = firstline.line
    last_linenumber = find_lastline(args)
    string(firstline.file), first_linenumber:last_linenumber
end

remove_toplevel(x) = x
remove_toplevel(x::Vector) = (x .= remove_toplevel.(x))
function remove_toplevel(x::Expr)
    if x.head == :toplevel
        return Expr(:block, x.args...)
    elseif x.head == :block
        x.args .= remove_toplevel.(x.args)
    end
    x
end
function flatten2block(args::Vector)
    res = Expr(:block)
    for elem in args
        if elem.head == :block
            append!(res.args, elem.args)
        elseif is_linenumber(elem) # ignore
        else
            push!(res.args, elem)
        end
    end
    res
end


function extract_cell(cell, author, parent_tags, setup, pfile, lastline, groupid = NO_GROUP)
    filter!(x-> !is_linenumber(x), cell.args)
    if !(length(cell.args) in (2, 4, 5))
        error(
            "You need to supply 1 3 or 4 arguments to `@cell`. E.g.:
                `@cell \"Title\" [\"tags\"] begin ... end`
            or
                `@cell \"Author\" \"Title\" [\"tags\"] begin ... end`
            or
                `@cell plot(...)`

            Found: $(join(cell.args[2:end], " "))"
        )
    end
    author, title, ctags, cblock = if length(cell.args) == 4
        (author, cell.args[2:end]...)
    elseif length(cell.args) == 5
        cell.args[2:end]
    elseif length(cell.args) == 2
        "No Author", "Test", [], cell.args[2]
    end

    if !isa(title, String)
        error("Title need to be a string. Found: $(title) with type: $(typeof(title))")
    end

    toplevel = ""; file = pfile; startend = lastline:lastline;
    if Meta.isexpr(cblock, :block)
        file, startend = find_startend(cblock.args)
        toplevel, source = extract_source(file, startend)
    else
        source = string(cblock) # single cell e.g. @cell scatter(...)
    end
    CellEntry(
        author, title, parent_tags ∪ extract_tags(ctags),
        file, startend, toplevel, source, groupid
    )
end

"""
    @block(Author, tags, block)

    Usage:

    ```example
    @block SimonDanisch ["2D"] begin
        # shared setup code
        using Makie, GeometryTypes, Colors

        # a cell with additional tags. The tags will get merged with tags from outer block
        @cell "Sample 1" ["heatmap"] begin
            scene = Scene()
            hm = heatmap(rand(32, 32))
            center!(scene)
            io = VideoStream(scene, @file) # creates a tmpfile for this
            for _ in 1:30
                hm[:heatmap] = rand(32, 32)
                recordframe!(io, 1//24) # record at 24 frames per second
            end
            io # last returned value will get inlined
        end

        @cell "Sample 2" ["image", "subscene", "scatter"] begin
            ...
        end
    end
    ```
"""
macro block(author, tags, block)
    if block.head != :block
        error("third argument needs to be a `begin ... end` block. Found: $block")
    end
    if !isa(author, Symbol)
        error("Author need to be a string. Found: $(author) with type: $(typeof(author))")
    end

    args = block.args
    pfile, pstartend = find_startend(args)
    # psource = extract_source(pfile, pstartend, x-> !occursin("@cell", x))

    parent_tags = extract_tags(tags)
    cells = args[findall(is_cell, args)]
    noncells = args[findall(x-> !is_cell(x), args)]
    setup = join(globaly_shared_code, "\n")

    for cell in cells
        cell_entry = extract_cell(cell, author, parent_tags, setup, pfile, 1)
        push!(database, cell_entry)
        # push a list of all tags to tags_list
        push!(tags_list, collect(String, cell_entry.tags)...)
    end

    groups = args[findall(is_group, args)]
    lastidx = length(database)
    for (groupid, group) in enumerate(groups)
        cellist = group.args[2].args
        groupid += (lastidx - 1)
        for cell in cellist
            if is_cell(cell)
                cell_entry = extract_cell(cell, author, parent_tags, setup, groupid)
                push!(database, cell_entry)
            end
        end
    end
end

# Cell macro
macro cell(author, title, tags, block)
    # implementation in block, this only marks
end
macro cell(title, tags, block)
end
macro cell(block)
end

# Group macro
macro group(block_of_grouped_cells)
    # only for marking
end
# Group macro
macro resolution()
    # only for marking
    nothing
end

const output_fallback = joinpath(mktempdir(), "test.")
macro replace_with_a_path(ending = :mp4)
    # only for marking
    string(output_fallback, ending)
end

"""
Walks through every example matching `tags`, and calls `f` on the example.
Merges groups of examples into one example entry.
"""
function enumerate_examples(f, tags...; start = 1, exclude_tags = nothing)
    num_excluded = 0
    sort!(database, by = (x)-> x.groupid)
    group_tmp = CellEntry[]
    last_id = NO_GROUP
    for i in start:length(database)
        entry = database[i]
        all(x-> string(x) in entry.tags, tags) || continue
        if exclude_tags != nothing && !isempty(exclude_tags)
            if any(x-> string(x) in entry.tags, Set(exclude_tags))
                @info("exclude_tag encountered, skipping example \"$(entry.title)\"")
                num_excluded += 1
                continue
            end
        end
        if last_id != NO_GROUP && (entry.groupid != last_id)
            last_id = entry.groupid # if already NO_GROUP, we set it to NO_GROUP
            if !isempty(group_tmp)
                f(merge(group_tmp))
                empty!(group_tmp)
            end
        elseif last_id != NO_GROUP && last_id == entry.groupid
            push!(group_tmp, entry)
        else
            f(entry)
        end
    end
    @info("Number of examples actually skipped: $num_excluded")
    return
end



example2source(entry; kw_args...) = sprint(io-> print_code(io, entry; kw_args...))

"""
Walks through all examples matching tags and calls `f(entry, source)`, with
source being the source of the example as a string
"""
function examples2source(f, tags...; start = 1, kw_args...)
    enumerate_examples(tags..., start = start) do entry
        f(entry, example2source(entry; kw_args...))
    end
end

const module_cache = Module[]

function eval_example(entry; kw_args...)
    source = example2source(entry; kw_args..., scope_start = "", scope_end = "")
    uname = entry.unique_name
    tmpmod = Module(gensym(uname))
    # modules created via Module get gc'ed, so we need to store a global reference
    push!(module_cache, tmpmod)
    result = nothing
    try
        result = include_string(tmpmod, source, string(uname))
    catch e
        Base.showerror(stderr, e)
        println(stderr)
        println(stderr, "failed to evaluate the example:")
        println(stderr, "```julia")
        println(stderr, source)
        println(stderr, "```")
        println(stderr, "stacktrace:")
        Base.show_backtrace(stderr, Base.catch_backtrace())
        println(stderr)
    end
    result
end

"""
Walks through examples and evaluates them. Returns the evaluated value and calls
`f(entry, value)`.
"""
function eval_examples(f, tags...; start = 1, exclude_tags = nothing, kw_args...)
    enumerate_examples(tags...; start = start, exclude_tags = exclude_tags) do entry
        result = eval_example(entry; kw_args...)
        try
            f(entry, result)
        catch e
            @warn("Calling failed with example: $(entry.title)")
            Base.showerror(stderr, e)
            Base.show_backtrace(stderr, Base.backtrace())
            rethrow(e)
        end
    end
end
