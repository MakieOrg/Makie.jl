@Block AllBlocks (positions,) begin
    @attributes begin
        "Color for scatter plot"
        scatter_color = :blue
        "Color for line plot"
        line_color = :red
        linewidth = @inherit :linewidth 1
        linestyle = @inherit :linestyle nothing
        markersize = 2
    end
end

Makie.conversion_trait(::Type{AllBlocks}) = PointBased()

function Makie.initialize_block!(cr::AllBlocks)
    ax, p1 = heatmap(cr[2:3, 1], reshape(sin.(1:100), 10, 10))

    lines!(ax, Rect2f(1, 1, 9, 9), color = :black)

    ax3 = Axis3(cr[2, 2])
    p2 = scatter!(ax3, cr.positions; color = cr.scatter_color)
    po = PolarAxis(cr[3, 2])
    hidedecorations!(po, grid = false)
    p3 = lines!(po, cr.positions, color = cr.line_color)
    Legend(cr[1, 1:2], [p1, p2, p3], ["heatmap", "scatter", "lines"], nbanks = 5, tellheight = true)
    Colorbar(cr[2:3, 3], p1)

    gl = GridLayout(cr[0, 1:3])
    Menu(gl[1, 1], options = ["one", "two", "three"])
    Makie.Button(gl[1, 2], label = "Button")
    Makie.Checkbox(gl[1, 3])
    Box(gl[2, :], height = 20)
    sl = Makie.Slider(gl[3, 1])
    Label(gl[3, 2], map(v -> "$v", sl.value))
    Toggle(gl[3, 3])
    IntervalSlider(gl[4, 1])
    Textbox(gl[4, 2:3])

    return cr
end

@reference_test "Block Recipe + Primitive Block Updates" begin
    # Step 1 - complex recipe with all primitive blocks + some theming

    my_theme = Theme(linewidth = 6)
    fig, cr = with_theme(my_theme, linestyle = :dash) do
        AllBlocks(1:0.5:10, sin, markersize = 20, figure = (size = (800, 800),))
    end

    st = Makie.Stepper(fig)
    Makie.step!(st)
    # display(fig)

    # Step 2 - add a plot, block and change a complex recipe attribute

    lines!(cr[2:3, 1], Rect2f(2, 2, 7, 7), color = :white)
    cr.scatter_color = :green
    Box(cr[0, 1:3][:, 0], width = 20)

    Makie.step!(st)

    # Step 3 - update most child block attributes
    # This is more of a general block update test which mainly should just not error

    is_color(::Makie.Colorant) = true
    is_color(name::Symbol) = haskey(Makie.Colors.color_names, string(name)) || (name === :transparent)
    is_color(t::Tuple{Symbol, <:Real}) = is_color(t[1])
    is_color(x) = false

    skipped = Symbol[]
    N = 0
    for block in cr.blocks
        T = typeof(block)
        # println(T)

        for name in Makie.attribute_names(T)
            # attribute_names adds kwargs too...
            haskey(block.attributes, name) || continue
            attribute = block.attributes[name]
            attribute isa Makie.ComputePipeline.Computed || continue
            namestr = string(name)
            val = attribute[]

            # println("   .", name, " = ", repr(val))
            try
                N += 1
                if val isa Union{Makie.Keyboard.Button, Makie.Mouse.Button, Makie.BooleanOperator}
                    continue
                elseif match(r".*visible", namestr) !== nothing
                    Makie.update!(block, name => true)
                elseif block isa Legend && name in (:titleposition, :orientation)
                    # updates together
                    Makie.update!(block, orientation = :horizontal, titleposition = :left)
                elseif match(r".*valign", namestr) !== nothing
                    Makie.update!(block, name => ifelse(val === :bottom, :center, :bottom))
                elseif match(r".*align", namestr) !== nothing
                    if val === Makie.automatic
                        Makie.update!(block, name => (:center, :center))
                    elseif val isa Tuple
                        x = ifelse.(val[1] === :left, :center, :left)
                        y = ifelse.(val[2] === :top, :center, :top)
                        Makie.update!(block, name => (x, y))
                    elseif val isa Symbol
                        Makie.update!(block, name => ifelse(val === :left, :center, :left))
                    elseif val isa Real
                        Makie.update!(block, name => 0.6)
                    elseif name === :alignmode
                        continue
                    else
                        println("   .", name, " = ", val)
                    end
                elseif val in (:left, :right, :center)
                    Makie.update!(block, name => ifelse(val === :left, :right, :left))
                elseif val in (:center, :top, :bottom, :baseline)
                    Makie.update!(block, name => ifelse(val === :bottom, :top, :bottom))
                elseif name === :perspectiveness
                    Makie.update!(block, name => 0.7)
                elseif val isa Union{AbstractFloat, VecTypes{N, <:Real} where {N}}
                    Makie.update!(block, name => 1.3 .* val .+ 1)
                elseif val isa Bool
                    Makie.update!(block, name => !val)
                elseif val isa Union{Integer, VecTypes{N, <:Integer} where {N}}
                    Makie.update!(block, name => val .+ 1)
                elseif is_color(val) || match(r".*(color)", namestr) !== nothing
                    Makie.update!(block, name => RNG.rand(RGBf, 1)[1]) # TODO: Fix error on RNG.rand(RGBf)
                elseif val isa String
                    Makie.update!(block, name => "foo")
                elseif val in (:horizontal, :vertical)
                    Makie.update!(block, name => ifelse(val === :horizontal, :vertical, :horizontal))
                elseif val === identity
                    Makie.update!(block, name => log10)
                elseif val in (:regular, :bold, :italic)
                    Makie.update!(block, name => ifelse(val === :regular, :bold, :regular))
                elseif match(r".*(rotation|angle)", namestr) !== nothing
                    Makie.update!(block, name => pi / 3)
                elseif match(r".*style", namestr) !== nothing
                    isnothing(val) && continue # can't update this
                    Makie.update!(block, name => ifelse(val === :dash, :dot, :dash))
                elseif match(r".*ticklabelspace", namestr) !== nothing
                    Makie.update!(block, name => ifelse(val === Makie.automatic, :max_auto, Makie.automatic))
                elseif match(r".*colormap", namestr) !== nothing
                    Makie.update!(block, name => [:red, :green, :blue, :black])
                elseif match(r".*minorticks", namestr) !== nothing
                    Makie.update!(block, name => 1.5:6)
                elseif match(r".*ticks", namestr) !== nothing
                    Makie.update!(block, name => (1:2:6, string.(1:2:6)))
                else
                    # print skipped
                    # println("   .", name, " = ", repr(val))
                    push!(skipped, Symbol("$T.$name"))
                    continue
                end
            catch e
                # Failed to update (on push)
                printstyled("   .$name = $(repr(val))\n", color = :red)
                rethrow(e)
            end
            # Mark updates to same value
            # (this will trigger for Legend titleposition because it updates twice)
            # attribute[] === val && printstyled("   .$name = $val\n", color = :red)
        end
    end

    # includes a bunch of layoutobservables, Legend entry defaults, formatters,
    # dim_converts, ...
    # not counted: skipped hotkey updates, visible updates from true to true
    @test length(skipped) == 79 # out of 714

    Makie.step!(st)

    st
end
