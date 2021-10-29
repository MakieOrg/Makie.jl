using Makie
using Observables

function cleanaxes()
    fig = Figure()
    ax = Axis(fig[1, 1])
    axbox = pixelarea(ax.scene)[]
    lim = ax.finallimits[]
    e = events(ax.scene)
    return ax, axbox, lim, e
end

@testset "zoom Axis" begin
    ax, axbox, lim, e = cleanaxes()
    # Put the mouse in the center
    e.mouseposition[] = Tuple(axbox.origin + axbox.widths/2)
    # zoom in
    e.scroll[] = (0.0, -1.0)
    newlim = ax.finallimits[]
    @test newlim.widths ≈ 0.9 * lim.widths
    @test newlim.origin ≈ lim.origin + (lim.widths - newlim.widths)/2
    # zoom out restores original position
    e.scroll[] = (0.0, 1.0)
    newlim = ax.finallimits[]
    @test newlim.widths ≈ lim.widths
    @test all(abs.(newlim.origin - lim.origin) .< 1e-7*lim.widths)
    ax.finallimits[] = lim
    # Put mouse in corner
    e.mouseposition[] = Tuple(axbox.origin)
    # zoom in
    e.scroll[] = (0.0, -1.0)
    newlim = ax.finallimits[]
    @test newlim.widths ≈ 0.9 * lim.widths
    @test all(abs.(newlim.origin - lim.origin) .< 1e-7*lim.widths)
    # zoom out
    e.scroll[] = (0.0, 1.0)
    newlim = ax.finallimits[]
    @test newlim.widths ≈ lim.widths
    @test all(abs.(newlim.origin - lim.origin) .< 1e-7*lim.widths)
    ax.finallimits[] = lim

    # Zoom only x or y
    for (lockname, idx, zoomkey) in ((:xzoomlock, 1, :yzoomkey), (:yzoomlock, 2, :xzoomkey))
        ax, axbox, lim, e = cleanaxes()
        lock = getproperty(ax, lockname)
        @test !lock[]
        lock[] = true
        e.mouseposition[] = Tuple(axbox.origin + axbox.widths/2)
        e.scroll[] = (0.0, -1.0)
        newlim = ax.finallimits[]
        @test newlim.widths[idx] == lim.widths[idx]
        @test newlim.widths[3-idx] ≈ 0.9 * lim.widths[3-idx]
        @test newlim.origin[idx] == lim.origin[idx]
        @test newlim.origin[3-idx] ≈ lim.origin[3-idx] + (lim.widths[3-idx] - newlim.widths[3-idx])/2
        e.scroll[] = (0.0, 1.0)
        newlim = ax.finallimits[]
        @test newlim.widths ≈ lim.widths
        @test all(abs.(newlim.origin - lim.origin) .< 1e-7*lim.widths)
        ax.finallimits[] = lim
        lock[] = false
        # Simulate pressing the keys
        key = getproperty(ax, zoomkey)[]
        keypresses = getfield(e, Makie.button_key(key))[]
        @test isempty(keypresses)
        push!(keypresses, key)
        e.scroll[] = (0.0, -1.0)
        newlim = ax.finallimits[]
        @test newlim.widths[idx] == lim.widths[idx]
        @test newlim.widths[3-idx] ≈ 0.9 * lim.widths[3-idx]
        @test newlim.origin[idx] == lim.origin[idx]
        @test newlim.origin[3-idx] ≈ lim.origin[3-idx] + (lim.widths[3-idx] - newlim.widths[3-idx])/2
        e.scroll[] = (0.0, 1.0)
        newlim = ax.finallimits[]
        @test newlim.widths ≈ lim.widths
        @test all(abs.(newlim.origin - lim.origin) .< 1e-7*lim.widths)
    end

    # Rubber band selection
    fig = Figure()
    ax = Axis(fig[1, 1])
    plot!(ax, [10, 15, 20])
    axbox = pixelarea(ax.scene)[]
    lim = ax.finallimits[]
    e = events(ax.scene)

    e.mouseposition[] = Tuple(axbox.origin)
    e.mousebuttons[] = Set([Mouse.left])
    e.mousedrag[] = Mouse.down
    e.mouseposition[] = Tuple(axbox.origin + axbox.widths ./ Vec2(2, 3))
    e.mousedrag[] = Mouse.pressed
    e.mousebuttons[] = Set{typeof(Mouse.left)}()
    e.mousedrag[] = Mouse.up
    newlim = ax.finallimits[]
    @test newlim.origin ≈ lim.origin
    @test newlim.widths ≈ lim.widths ./ Vec2(2, 3)
    # Ctrl-click to restore
    key = Makie.Keyboard.left_control
    keypresses = e.keyboardbuttons[]
    @test isempty(keypresses)
    push!(keypresses, key)
    buttons = e.mousebuttons[]
    @test isempty(buttons)
    e.mousebuttons[] = Set([Mouse.left])
    empty!(e.mousebuttons[])
    empty!(keypresses)
    newlim = ax.finallimits[]
    @test all(lim.origin .>= newlim.origin) && all(lim.origin+lim.widths .<= newlim.origin+newlim.widths)
end

@testset "pan Axis" begin
    ax, axbox, lim, e = cleanaxes()
    e.mouseposition[] = Tuple(axbox.origin + axbox.widths/2)
    e.scroll[] = (0.0, -1.0)
    newlim = ax.finallimits[]
    e.mouseposition[] = Tuple(axbox.origin)
    panbtn = ax.panbutton[]
    e.mousebuttons[] = Set([panbtn])
    e.mousedrag[] = Mouse.down
    e.mouseposition[] = Tuple(axbox.origin + axbox.widths/10)
    e.mousedrag[] = Mouse.pressed
    e.mousebuttons[] = Set{typeof(panbtn)}()
    e.mousedrag[] = Mouse.up
    panlim = ax.finallimits[]
    @test panlim.widths == newlim.widths
    @test (5/4)*panlim.origin ≈ -newlim.origin
end
