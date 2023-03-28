function used_functions(code)
    used_functions = Set{Symbol}()
    MacroTools.postwalk(code) do x
        if @capture(x, f_(xs__))
            push!(used_functions, Symbol(string(f)))
        end
        if @capture(x, f_(xs__) do; body__; end)
            push!(used_functions, Symbol(string(f)))
        end
        return x
    end
    return used_functions
end

const REGISTERED_TESTS = Set{String}()
const RECORDING_DIR = Base.RefValue{String}()
const SKIP_TITLES = Set{String}()
const SKIP_FUNCTIONS = Set{Symbol}()
const COUNTER = Ref(0)

"""
    @reference_test(name, code)

Records `code` and saves the result to `joinpath(ReferenceTests.RECORDING_DIR[], "recorded", name)`.
`RECORDING_DIR` gets set automatically, if tests included via `@include_reference_tests`.
"""
macro reference_test(name, code)
    title = string(name)
    funcs = used_functions(code)
    skip = (title in SKIP_TITLES) || any(x-> x in funcs, SKIP_FUNCTIONS)
    return quote
        @testset $(title) begin
            if $skip
                @test_broken false
            else
                if $title in $REGISTERED_TESTS
                    error("title must be unique. Duplicate title: $(title)")
                end
                println("running $(lpad(COUNTER[] += 1, 3)): $($title)")
                Makie.set_theme!(resolution=(500, 500))
                ReferenceTests.RNG.seed_rng!()
                result = let
                    $(esc(code))
                end
                @test save_result(joinpath(RECORDING_DIR[], $title), result)
                push!($REGISTERED_TESTS, $title)
            end
        end
    end
end

"""
    save_result(path, object)

Helper, to more easily save all kind of results from the test database
"""
function save_result(path::String, scene::Makie.FigureLike)
    isfile(path * ".png") && rm(path * ".png"; force=true)
    FileIO.save(path * ".png", scene)
    return true
end

function save_result(path::String, stream::VideoStream)
    isfile(path * ".mp4") && rm(path * ".mp4"; force=true)
    FileIO.save(path * ".mp4", stream)
    return true
end

function save_result(path::String, object)
    isfile(path) && rm(path; force=true)
    FileIO.save(path, object)
    return true
end

function mark_broken_tests(title_excludes = []; functions=[])
    empty!(SKIP_TITLES)
    empty!(SKIP_FUNCTIONS)
    union!(SKIP_TITLES, title_excludes)
    union!(SKIP_FUNCTIONS, functions)
end

macro include_reference_tests(path)
    toplevel_folder = dirname(string(__source__.file))
    return esc(quote
        using ReferenceTests: @reference_test
        name = splitext(basename($(path)))[1]
        include_path = isdir($path) ? $path : joinpath(@__DIR__, "tests", $path)
        recording_dir = joinpath($toplevel_folder, "recorded_reference_images", name)
        if isdir(recording_dir)
            rm(recording_dir; force=true, recursive=true)
        end
        ReferenceTests.RECORDING_DIR[] = joinpath(recording_dir, "recorded")
        mkpath(joinpath(recording_dir, "recorded"))
        @testset "$name" begin
            empty!(ReferenceTests.REGISTERED_TESTS)
            include(include_path)
        end
        recorded_files = collect(ReferenceTests.REGISTERED_TESTS)
        recording_dir = recording_dir
        empty!(ReferenceTests.REGISTERED_TESTS)
        ReferenceTests.COUNTER[] = 0
        (recorded_files, recording_dir)
    end)
end
