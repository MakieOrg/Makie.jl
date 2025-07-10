using ReferenceTests
using ReferenceTests: RNG, loadasset, @reference_test
using ReferenceTests.GeometryBasics
using ReferenceTests.Statistics
using ReferenceTests.CategoricalArrays: categorical, levelcode
using ReferenceTests.LinearAlgebra
using ReferenceTests.FileIO
using ReferenceTests.Colors
using ReferenceTests.LaTeXStrings
using ReferenceTests.DelimitedFiles
using ReferenceTests.Test
using ReferenceTests.Colors: RGB, N0f8
using ReferenceTests.DelaunayTriangulation
using ReferenceTests.SparseArrays
using Makie: Record, volume

function click(events::Events, pos::VecTypes{2}, button::Mouse.Button = Mouse.left)
    events.mouseposition[] = pos
    events.mousebutton[] = Makie.MouseButtonEvent(button, Mouse.press)
    return events.mousebutton[] = Makie.MouseButtonEvent(button, Mouse.release)
end
click(events::Events, x, y, button::Mouse.Button = Mouse.left) = click(events, (x, y), button)

function send(events::Events, key::Keyboard.Button)
    events.keyboardbutton[] = Makie.KeyEvent(key, Keyboard.press)
    return events.keyboardbutton[] = Makie.KeyEvent(key, Keyboard.release)
end
function send(events::Events, pos::VecTypes{2}, key::Keyboard.Button)
    events.mouseposition[] = pos
    return send(events, key)
end
send(events::Events, x, y, key::Keyboard.Button) = click(events, (x, y), key)


@testset "categorical" begin
    include("categorical.jl")
end
@testset "dates" begin
    include("dates.jl")
end
@testset "unitful" begin
    include("unitful.jl")
end
@testset "dynamicquantities" begin
    include("dynamicquantities.jl")
end
@testset "specapi" begin
    include("specapi.jl")
end
@testset "primitives" begin
    include("primitives.jl")
end
@testset "text.jl" begin
    include("text.jl")
end
@testset "float32convert" begin
    include("float32_conversion.jl")
end
@testset "attributes.jl" begin
    include("attributes.jl")
end
@testset "examples2d.jl" begin
    include("examples2d.jl")
end
@testset "examples3d.jl" begin
    include("examples3d.jl")
end
@testset "short_tests.jl" begin
    include("short_tests.jl")
end
@testset "figures_and_makielayout.jl" begin
    include("figures_and_makielayout.jl")
end
@testset "updating_plots" begin
    include("updating.jl")
end
@testset "generic_components" begin
    include("generic_components.jl")
end
