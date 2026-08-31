# A figure displayed through a live session has to be serialized into its
# initial payload when `resize_to` is unset (the default): the browser cannot
# change the size then, and a static snapshot of the session — Pluto's or
# Jupyter's HTML export — only ever has that payload, with no Julia process
# left to answer a size round trip. With `resize_to` set the round trip stays.

function queued_scene_payloads(session, scene)
    uuid = WGLMakie.js_uuid(scene)
    payloads = Any[]
    for msg in session.message_queue, (_, obj) in msg.cache.objects
        obj isa Bonito.SerializedObservable || continue
        value = obj.value
        if value isa AbstractDict && get(value, "uuid", nothing) == uuid
            push!(payloads, value)
        end
    end
    return payloads
end

function display_into(session; screen_config...)
    fig, ax, pl = scatter(1:4)
    Makie.update_state_before_display!(fig)
    scene = Makie.get_scene(fig)
    screen = WGLMakie.Screen(; screen_config...)
    screen.scene = scene
    WGLMakie.render_with_init(screen, session, scene, fig)
    return scene
end

@testset "scene serialized into the initial payload" begin
    # A live-type session no browser ever connects to.
    session = Bonito.Session(Bonito.WebSocketConnection(); asset_server = Bonito.NoServer())
    try
        @testset "default resize_to" begin
            sub = Bonito.Session(session)
            scene = display_into(sub)
            @test length(queued_scene_payloads(sub, scene)) == 1
        end
        @testset "resize_to = :parent waits for the browser" begin
            sub = Bonito.Session(session)
            scene = display_into(sub; resize_to = :parent)
            @test isempty(queued_scene_payloads(sub, scene))
        end
        @testset "offline" begin
            offline = Bonito.Session(Bonito.NoConnection(); asset_server = Bonito.NoServer())
            scene = display_into(offline; resize_to = :parent)
            @test length(queued_scene_payloads(offline, scene)) == 1
            close(offline)
        end
    finally
        close(session)
    end
end
