struct CellEntry
    author::String
    title::String
    tags::Set{String}
    file::String
    file_range::UnitRange{Int}
    source::String
    setup::String
end

database = CellEntry[]
globaly_shared_code = String[]

function extract_tags(expr)
    if !any(x-> isa(x, String) || isa(x, Symbol), expr.args) || expr.head != :vect
        error("Tags need to be an array of strings/variables. Found: $(expr)")
    end
    Set(String.(expr.args))
end

function extract_source(file, file_range, filterfun = x-> true)
    source = IOBuffer()
    open(file) do io
        for (i, line) in enumerate(eachline(io))
            if i in file_range
                if length(line) >= 8 && all(x-> x == ' ', line[1:8])
                    line = line[9:end]
                end
                if filterfun(line)
                    println(source, line)
                end
            end
        end
    end
    String(take!(source))
end


is_cell(x::Expr) = x.head == :macrocall && x.args[1] == Symbol("@cell")
is_cell(x) = false

function find_startend(args::Vector)
    firstidx = findfirst(Base.is_linenumber, args)
    lastidx = findlast(Base.is_linenumber, args)
    lf, le = args[firstidx], args[lastidx]
    string(lf.args[2]), (lf.args[1]):(le.args[1])
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
        elseif Base.is_linenumber(elem) # ignore
        else
            push!(res.args, elem)
        end
    end
    res
end

function extract_cell(cell, author, parent_tags, setup)
    if !(length(cell.args) in (4, 5))
        error(
            "You need to supply 3 or 4 arguments to `@cell`. E.g.:
                `@cell \"Title\" [\"tags\"] begin ... end`
            or
                `@cell \"Author\" \"Title\" [\"tags\"] begin ... end`

            Found: $(join(cell.args[2:end], " "))"
        )
    end

    author, title, ctags, cblock = if length(cell.args) == 4
        (author, cell.args[2:end]...)
    else
        cell.args[2:end]
    end

    if !isa(title, String)
        error("Title need to be a string. Found: $(title) with type: $(typeof(title))")
    end

    file, startend = find_startend(cblock.args)
    source = extract_source(file, startend)

    CellEntry(
        author, title, parent_tags ∪ extract_tags(ctags),
        file, startend, source, setup
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
    # psource = extract_source(pfile, pstartend, x-> !contains(x, "@cell"))

    parent_tags = extract_tags(tags)
    cells = args[find(is_cell, args)]
    noncells = args[find(x-> !is_cell(x), args)]
    setup = join(globaly_shared_code, "\n")

    for cell in cells
        cell_entry = extract_cell(cell, author, parent_tags, setup)
        push!(database, cell_entry)
    end
end

# Macro is only for marking, so no implementation here
macro cell(title, tags, block)

end

# Macro is only for marking, so no implementation here
macro globaly_shared(block)
    if block.head != :block
        error("Please use a block, e.g. `@globaly_shared begin ... end`. Found: $block")
    end
    file, file_range = find_startend(block.args)
    source = extract_source(file, file_range)
    push!(globaly_shared_code, source)
    nothing
end
