cd(@__DIR__)
let io = open("precompile.csv", "w")
    ccall(:jl_dump_compiles, Cvoid, (Ptr{Cvoid},), io.handle)
    try
        include("runtests.jl")
    finally
        ccall(:jl_dump_compiles, Cvoid, (Ptr{Cvoid},), C_NULL)
        close(io)
    end
end
