function fetchall(parent, kwargs)
    for k in keys(kwargs)
        getproperty(parent, k)[]
    end
    return
end

function set_deprecated_attributes(parent, dep_kwargs, kwargs)
    Makie.update!(parent; dep_kwargs...)
    fetchall(parent, kwargs)
    return
end

function test_deprecated_plot_attribute(plotfunc, args, msg, dep_kwargs, kwargs)
    # warn when deprecated kwargs are used
    @test_logs (:warn, msg) plotfunc(args...; dep_kwargs...)

    # don't warn when new kwargs are used
    f, a, p = plotfunc(args...; kwargs...)
    @test_logs fetchall(p, kwargs)

    # warn when deprecated attributes are resolved (after set)
    @test_logs (:warn, msg) set_deprecated_attributes(p, dep_kwargs, kwargs)
    return
end

function test_deprecated_block_attribute(blockfunc, args, msg, dep_kwargs, kwargs)
    f = Figure()
    @test_logs (:warn, msg) blockfunc(f[1, 1], args...; dep_kwargs...)

    f = Figure()
    b = blockfunc(f[1, 1], args...; kwargs...)
    @test_logs fetchall(b, kwargs)

    @test_logs (:warn, msg) set_deprecated_attributes(b, dep_kwargs, kwargs)
    return
end

@testset "Deprecated Attributes" begin
    test_deprecated_plot_attribute(
        scatter, (rand(10),),
        "`rotations` has been renamed to `rotation` for consistency in Makie v0.21.",
        (rotations = rand(10),), (rotation = rand(10),)
    )

    test_deprecated_plot_attribute(
        meshscatter, (rand(10),),
        "`rotations` has been renamed to `rotation` for consistency in Makie v0.21.",
        (rotations = rand(10),), (rotation = rand(10),)
    )

    test_deprecated_plot_attribute(
        text, (Point2f(0),),
        "`textsize` has been renamed to `fontsize` in Makie v0.19. Please change all occurrences of `textsize` to `fontsize` or revert back to an earlier version.",
        (textsize = 10, text = "test"), (fontsize = 8, text = "test")
    )

    test_deprecated_block_attribute(
        Colorbar, tuple(),
        "`limits` has been removed in favor of `colorrange` in Makie v0.25.",
        (limits = (1, 10),), (colorrange = (1, 2),)
    )

    for block in (Label, Button, Menu, Textbox)
        test_deprecated_block_attribute(
            block, tuple(),
            "`textsize` has been renamed to `fontsize` in Makie v0.19. Please change all occurrences of `textsize` to `fontsize` or revert back to an earlier version.",
            (textsize = 10,), (fontsize = 8,)
        )
    end

    test_deprecated_block_attribute(
        Legend, tuple([], []),
        "The background color of the legend. DEPRECATED - use `backgroundcolor` instead.",
        (bgcolor = :red,), (backgroundcolor = RGBf(1, 0.5, 0),)
    )
end
