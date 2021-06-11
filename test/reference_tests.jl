using ReferenceTests
using ReferenceTests: @cell, nice_title

function database_filtered!(title_excludes = [], nice_title_excludes = []; functions=[])
    database = ReferenceTests.load_database()
    return filter(database) do (name, entry)
        !(entry.title in title_excludes) &&
        !(nice_title(entry) in nice_title_excludes) &&
        !any(x-> x in entry.used_functions, functions)
    end
end

@testset "reference tests" begin
    @testset "cairomakie" begin
        include("cairomakie.jl")
    end
    @testset "wglmakie" begin
        include("wglmakie.jl")
    end
    @testset "glmakie" begin
        include("glmakie.jl")
    end
end
