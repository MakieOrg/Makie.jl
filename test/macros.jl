# This file is mainly meant to test that macros work in external modules.
# We do this by creating an external module and running all testsets within it. 
module __TestModuleForExternalRecipesAndBlocks 
using Test
import Makie as _MKE # so that we can't get away with literal `Makie.*`, even if it might usually work.

@testset "Makie macros in external module" begin
    @test_nowarn begin
        _MKE.@recipe(MyTestPlot1234567890) do scene
            _MKE.Attributes(color = :red,)
        end
    end

    @test_nowarn begin
        _MKE.@Block __MySliderGrid begin
            @forwarded_layout
            sliders::Vector{_MKE.Slider}
            valuelabels::Vector{_MKE.Label}
            labels::Vector{_MKE.Label}
            @attributes begin
                "The horizontal alignment of the block in its suggested bounding box."
                halign = :center
                "The vertical alignment of the block in its suggested bounding box."
                valign = :center
                "The width setting of the block."
                width = _MKE.Auto()
                "The height setting of the block."
                height = _MKE.Auto()
                "Controls if the parent layout can adjust to this block's width"
                tellwidth::Bool = true
                "Controls if the parent layout can adjust to this block's height"
                tellheight::Bool = true
                "The align mode of the block in its parent GridLayout."
                alignmode = _MKE.Inside()
                "The width of the value label column. If `automatic`, the width is determined by sampling a few values from the slider ranges and picking the largest label size found."
                value_column_width = _MKE.automatic
            end
        end
    end
end

end