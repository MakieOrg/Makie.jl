using AbstractPlotting
using AbstractPlotting.MakieLayout
using Observables
using Test

function cleanaxes()
    scene, layout = layoutscene()
    ax = layout[1, 1] = LAxis(scene)
    axbox = pixelarea(ax.scene)[]
    lim = ax.limits[]
    e = events(ax.scene)
    return ax, axbox, lim, e
end

@testset "zoom LAxis" begin
    ax, axbox, lim, e = cleanaxes()
    # Put the mouse in the center
    e.mouseposition[] = Tuple(axbox.origin + axbox.widths/2)
    # zoom in
    e.scroll[] = (0.0, -1.0)
    newlim = ax.limits[]
    @test newlim.widths ≈ 0.9 * lim.widths
    @test newlim.origin ≈ lim.origin + (lim.widths - newlim.widths)/2
    # zoom out restores original position
    e.scroll[] = (0.0, 1.0)
    newlim = ax.limits[]
    @test newlim.widths ≈ lim.widths
    @test all(abs.(newlim.origin - lim.origin) .< 1e-7*lim.widths)
    ax.limits[] = lim
    # Put mouse in corner
    e.mouseposition[] = Tuple(axbox.origin)
    # zoom in
    e.scroll[] = (0.0, -1.0)
    newlim = ax.limits[]
    @test newlim.widths ≈ 0.9 * lim.widths
    @test all(abs.(newlim.origin - lim.origin) .< 1e-7*lim.widths)
    # zoom out
    e.scroll[] = (0.0, 1.0)
    newlim = ax.limits[]
    @test newlim.widths ≈ lim.widths
    @test all(abs.(newlim.origin - lim.origin) .< 1e-7*lim.widths)
    ax.limits[] = lim

    # Zoom only x or y
    for (lockname, idx, zoomkey) in ((:xzoomlock, 1, :yzoomkey), (:yzoomlock, 2, :xzoomkey))
        ax, axbox, lim, e = cleanaxes()
        lock = getproperty(ax, lockname)
        @test !lock[]
        lock[] = true
        e.mouseposition[] = Tuple(axbox.origin + axbox.widths/2)
        e.scroll[] = (0.0, -1.0)
        newlim = ax.limits[]
        @test newlim.widths[idx] == lim.widths[idx]
        @test newlim.widths[3-idx] ≈ 0.9 * lim.widths[3-idx]
        @test newlim.origin[idx] == lim.origin[idx]
        @test newlim.origin[3-idx] ≈ lim.origin[3-idx] + (lim.widths[3-idx] - newlim.widths[3-idx])/2
        e.scroll[] = (0.0, 1.0)
        newlim = ax.limits[]
        @test newlim.widths ≈ lim.widths
        @test all(abs.(newlim.origin - lim.origin) .< 1e-7*lim.widths)
        ax.limits[] = lim
        lock[] = false
        # Simulate pressing the keys
        key = getproperty(ax, zoomkey)[]
        buttons = getfield(e, AbstractPlotting.button_key(key))[]
        @test isempty(buttons)
        push!(buttons, key)
        e.scroll[] = (0.0, -1.0)
        newlim = ax.limits[]
        @test newlim.widths[idx] == lim.widths[idx]
        @test newlim.widths[3-idx] ≈ 0.9 * lim.widths[3-idx]
        @test newlim.origin[idx] == lim.origin[idx]
        @test newlim.origin[3-idx] ≈ lim.origin[3-idx] + (lim.widths[3-idx] - newlim.widths[3-idx])/2
        e.scroll[] = (0.0, 1.0)
        newlim = ax.limits[]
        @test newlim.widths ≈ lim.widths
        @test all(abs.(newlim.origin - lim.origin) .< 1e-7*lim.widths)
    end


end

