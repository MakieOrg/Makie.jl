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
    scatter!(ax3, Rect3f(0, 0, 0, 10, 10, 10))
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
    Toggle(gl[3, 3], toggleduration = 0.01)
    IntervalSlider(gl[4, 1])
    Textbox(gl[4, 2:3])

    return cr
end


BLOCK_UPDATES = let
    block_types = [
        Axis, Axis3, PolarAxis,
        Legend, Colorbar, Menu, Makie.Button, Makie.Checkbox,
        Box, Makie.Slider, Label, Toggle, IntervalSlider, Textbox,
    ]
    settings = Dict()
    skipped = Symbol[]
    exclude = [
        # kwargs
        Axis => :palette, PolarAxis => :palette, Legend => :entrygroups, Menu => :default,
        # deprecated
        Legend => :bgcolor,
        # not settable
        Colorbar => :colormap,
        # avoid
        Axis3 => :zoommode, Toggle => :toggleduration,
    ]
    N = 0
    scene = Scene()

    is_color(::Makie.Colorant) = true
    is_color(name::Symbol) = haskey(Makie.Colors.color_names, string(name)) || (name === :transparent)
    is_color(t::Tuple{Symbol, <:Real}) = is_color(t[1])
    is_color(x) = false

    for T in block_types
        # println(T)
        attr = Dict{Symbol, Any}()

        for (name, maybe_obs) in Makie.default_attribute_values(T, scene)
            if Pair(T, name) in exclude
                # @info "Skip $T => $name"
                continue
            end
            namestr = string(name)
            val = to_value(maybe_obs)

            # println("   .", name, " = ", repr(val))
            try
                N += 1
                if val isa Union{Makie.Keyboard.Button, Makie.Mouse.Button, Makie.BooleanOperator}
                    continue
                elseif match(r".*visible", namestr) !== nothing
                    attr[name] = true
                elseif T == Legend && name in (:titleposition, :orientation)
                    # updates together
                    attr[:orientation] = :horizontal
                    attr[:titleposition] = :left
                elseif match(r".*valign", namestr) !== nothing
                    attr[name] = ifelse(val === :bottom, :center, :bottom)
                elseif match(r".*align", namestr) !== nothing
                    if val === Makie.automatic
                        attr[name] = (:center, :center)
                    elseif val isa Tuple
                        x = ifelse.(val[1] === :left, :center, :left)
                        y = ifelse.(val[2] === :top, :center, :top)
                        attr[name] = (x, y)
                    elseif val isa Symbol
                        attr[name] = ifelse(val === :left, :center, :left)
                    elseif val isa Real
                        attr[name] = 0.6
                    elseif name === :alignmode
                        continue
                    else
                        println("   .", name, " = ", val)
                    end
                elseif val in (:left, :right, :center)
                    attr[name] = ifelse(val === :left, :right, :left)
                elseif val in (:center, :top, :bottom, :baseline)
                    attr[name] = ifelse(val === :bottom, :top, :bottom)
                elseif name === :perspectiveness
                    attr[name] = 0.7
                elseif val isa Union{AbstractFloat, VecTypes{N, <:Real} where {N}}
                    attr[name] = 1.3 .* val .+ 1
                elseif val isa Bool
                    attr[name] = !val
                elseif val isa Union{Integer, VecTypes{N, <:Integer} where {N}}
                    attr[name] = val .+ 1
                elseif val isa String
                    attr[name] = "foo"
                elseif val in (:horizontal, :vertical)
                    attr[name] = ifelse(val === :horizontal, :vertical, :horizontal)
                elseif val === identity
                    attr[name] = log10
                elseif val in (:regular, :bold, :italic)
                    attr[name] = ifelse(val === :regular, :bold, :regular)
                elseif match(r".*(rotation|angle)", namestr) !== nothing
                    attr[name] = pi / 3
                elseif match(r".*style", namestr) !== nothing
                    isnothing(val) && continue # can't update this
                    attr[name] = ifelse(val === :dash, :dot, :dash)
                elseif match(r".*ticklabelspace", namestr) !== nothing
                    attr[name] = ifelse(val === Makie.automatic, 20, Makie.automatic)
                elseif match(r".*colormap", namestr) !== nothing
                    attr[name] = [:red, :green, :blue, :black]
                elseif match(r".*colorrange", namestr) !== nothing
                    attr[name] = (0.2, 0.8)
                elseif is_color(val) || match(r".*(color)", namestr) !== nothing
                    # TODO: Fix error on RNG.rand(RGBf)
                    attr[name] = RNG.rand(RGBf, 1)[1]
                elseif match(r".*minorticks", namestr) !== nothing
                    attr[name] = 1.5:6
                elseif match(r".*ticks", namestr) !== nothing
                    attr[name] = (1:2:6, string.(1:2:6))
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

        settings[T] = attr
    end

    # includes a bunch of layoutobservables, Legend entry defaults, formatters,
    # dim_converts, ...
    # not counted: skipped hotkey updates, visible updates from true to true
    @test length(skipped) == 93 # out of 719

    settings
end

@reference_test "Block Recipe + Primitive Block Updates" begin
    # Step 1 - complex recipe with all primitive blocks + some theming

    my_theme = Theme(linewidth = 6)
    fig, cr = with_theme(my_theme, linestyle = :dash) do
        AllBlocks(1:0.5:10, sin, markersize = 20, figure = (size = (800, 800),))
    end

    st = Makie.Stepper(fig)
    Makie.step!(st)

    # Step 2 - add a plot, block and change a complex recipe attribute

    lines!(cr[2:3, 1], Rect2f(2, 2, 7, 7), color = :white)
    cr.scatter_color = :green
    Box(cr[0, 1:3][:, 0], width = 20)

    Makie.step!(st)

    # Step 3 - update most child block attributes
    # This is more of a general block update test which mainly should just not error

    for block in cr.blocks
        attr = BLOCK_UPDATES[typeof(block)]
        Makie.update!(block, attr)
    end

    # limits don't react to changes in x/yscale
    xlims!(cr.blocks[1], 0.2, 20.0)
    ylims!(cr.blocks[1], 0.2, 20.0)

    xlims!(cr.blocks[2], -2, 12)
    ylims!(cr.blocks[2], -2, 12)
    zlims!(cr.blocks[2], -2, 12)

    # why is the layout not fully updated without this?
    tbox = cr.blocks[14]
    notify(tbox.tellheight)

    # wait for Toggle to finish
    colorbuffer(fig)
    sleep(0.5)

    Makie.step!(st)

    st
end

# Same as the last step of the test above but without any updates and without
# Block recipes
@reference_test "Block Recipe Reference figure" begin
    my_theme = Theme(linewidth = 6)
    fig = with_theme(my_theme, linestyle = :dash) do

        fig = Figure(size = (800, 800))
        ax = Axis(fig[2:3, 1]; BLOCK_UPDATES[Axis]...)
        p1 = heatmap!(ax, reshape(sin.(1:100), 10, 10))
        lines!(ax, Rect2f(1, 1, 9, 9), color = :black)

        ax3 = Axis3(fig[2, 2]; BLOCK_UPDATES[Axis3]...)
        p2 = scatter!(ax3, 1:0.5:10, sin; color = :green)
        scatter!(ax3, Rect3f(0, 0, 0, 10, 10, 10); color = :green)
        po = PolarAxis(fig[3, 2]; BLOCK_UPDATES[PolarAxis]...)
        # hidedecorations!(po, grid = false)
        p3 = lines!(po, 1:0.5:10, sin, color = :red)
        Legend(
            fig[1, 1:2], [p1, p2, p3], ["heatmap", "scatter", "lines"], nbanks = 5,
            tellheight = true; BLOCK_UPDATES[Legend]...
        )
        Colorbar(fig[2:3, 3], p1; BLOCK_UPDATES[Colorbar]...)

        gl = GridLayout(fig[0, 1:3])
        Menu(gl[1, 1], options = ["one", "two", "three"]; BLOCK_UPDATES[Menu]...)
        Makie.Button(gl[1, 2], label = "Button"; BLOCK_UPDATES[Makie.Button]...)
        Makie.Checkbox(gl[1, 3]; BLOCK_UPDATES[Makie.Checkbox]...)
        Box(gl[2, :], height = 20; BLOCK_UPDATES[Box]...)
        sl = Makie.Slider(gl[3, 1]; BLOCK_UPDATES[Makie.Slider]...)
        Label(gl[3, 2]; BLOCK_UPDATES[Label]...)
        Toggle(gl[3, 3], toggleduration = 0.01; BLOCK_UPDATES[Toggle]...)
        IntervalSlider(gl[4, 1]; BLOCK_UPDATES[IntervalSlider]...)
        Textbox(gl[4, 2:3]; BLOCK_UPDATES[Textbox]...)

        lines!(fig[2:3, 1], Rect2f(2, 2, 7, 7), color = :white)
        Box(fig[0, 1:3][:, 0], width = 20; BLOCK_UPDATES[Box]...)

        xlims!(ax, 0.2, 20.0)
        ylims!(ax, 0.2, 20.0)

        xlims!(ax3, -2, 12)
        ylims!(ax3, -2, 12)
        zlims!(ax3, -2, 12)

        fig
    end
end
