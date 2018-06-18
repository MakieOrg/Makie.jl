include("../examples/library.jl")
cd(@__DIR__)

open("global_form.jl", "w") do io
    sort!(database, by = (x)-> x.groupid)
    i = start(database)
    while length(database) >= i
        i = print_code(io, database, i, scope_start = "let\n")
    end
end
include("global_form.jl")
