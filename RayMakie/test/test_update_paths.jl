# Which PATH each kind of update takes, for meshes and for instances.
#
# `test_mesh_update_stress.jl` and `test_meshscatter_update_stress.jl` already
# cover that these updates run and keep their handles; this file covers the
# thing neither can see — whether an update rebuilt the acceleration structure
# or updated in place. That distinction is invisible in the image and is exactly
# where the cost is, so without it a change that turns every recolour into a
# BLAS rebuild passes the whole suite.
#
# `RayMakieState` counts rebuilds split by cause:
#   refit_eligible_rebuilds — only positions/normals were dirty, so a BLAS refit
#                             could have served it
#   topology_rebuilds       — faces or uv changed too, so a new BVH is required
# Both stay put when an update took the in-place path.
# No `using Lava`: none of this file names one, and loading it drags in the
# Vulkan loader — which is not there on every machine this suite runs on, so
# the whole file errored before its first test rather than running on the
# backend `runtests.jl` already found and activated.
using Test, Makie, RayMakie, Hikari, GeometryBasics, Raycore, Mantle
using GeometryBasics: Point3f, Vec2f, Vec3f, Rect3f, Sphere

robj_of(plt) = to_value(plt.attributes[:trace_renderobject])
make_screen(scene) = RayMakie.Screen(scene; samples = 1, max_depth = 1, hw_accel = false)
counters(state) = (state.refit_eligible_rebuilds, state.topology_rebuilds)
cube_mesh() = GeometryBasics.normal_mesh(Rect3f(Vec3f(-1), Vec3f(2)))

# A scene ready to be poked, with its state handle.
function trace_fixture(plotf)
    scene = Scene(size = (48, 48))
    cam3d!(scene)
    plt = plotf(scene)
    screen = make_screen(scene)
    RayMakie.init_scene!(screen, scene)
    return scene, plt, screen, screen.scene_states[1]
end

# ---------------------------------------------------------------------------
# Meshes
# ---------------------------------------------------------------------------

@testset "mesh — recolour updates in place" begin
    scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube_mesh(); color = :red))
    before = counters(st)
    inst_before = Raycore.n_instances(st.hikari_scene.accel)

    for c in (:blue, :green, :yellow)
        plt.color = c
        RayMakie.poll_all_plots(screen, scene)
    end

    @test counters(st) == before                                        # no rebuild at all
    @test Raycore.n_instances(st.hikari_scene.accel) == inst_before
    close(screen)
end

@testset "mesh — material swap updates in place" begin
    scene, plt, screen, st = trace_fixture(
        s -> mesh!(s, cube_mesh(); material = Hikari.Diffuse(color = Hikari.RGBSpectrum(0.5f0)))
    )
    before = counters(st)
    handle_before = robj_of(plt).handle

    plt.material = Hikari.Diffuse(color = Hikari.RGBSpectrum(0.1f0, 0.9f0, 0.1f0, 1.0f0))
    RayMakie.poll_all_plots(screen, scene)

    @test counters(st) == before
    @test robj_of(plt).handle === handle_before
    close(screen)
end

@testset "mesh — Glass preset uses Principled nested updates" begin
    scene, plt, screen, st = trace_fixture(
        s -> mesh!(s, cube_mesh(); material = Hikari.Glass(base_color = (0.8, 0.9, 1.0)))
    )
    handle = robj_of(plt).handle
    before = counters(st)
    stored() = (Raycore.@allowscalar st.hikari_scene.media_interfaces[handle.interface]).material
    key = stored()
    try
        @test plt.material[] isa Hikari.Principled
        plt.material.base_color = (0.2, 0.6, 0.8)
        plt.material.roughness = 0.25
        plt.material.ior = 1.6
        RayMakie.poll_all_plots(screen, scene)
        @test plt.material[].base_color == (0.2, 0.6, 0.8)
        @test plt.material[].roughness == 0.25
        @test plt.material[].ior == 1.6
        @test plt.material[].transmission_weight == 1
        @test stored() == key
        @test robj_of(plt).handle === handle
        @test counters(st) == before
    finally
        close(screen)
    end
end

# A material of another kind, or a node set into one field of a shader, is another
# stored type. It takes a slot of its type and the mesh's interface is pointed at it;
# the geometry stays. `Hikari.update_material!` threw before ("push it as a new
# material"), so neither edit could reach the traced view.
@testset "mesh — a material of another type updates in place" begin
    scene, plt, screen, st = trace_fixture(
        s -> mesh!(s, cube_mesh(); material = Hikari.Principled(base_color = (0.8, 0.2, 0.1), roughness = 0.3))
    )
    before = counters(st)
    handle = robj_of(plt).handle
    stored() = (Raycore.@allowscalar st.hikari_scene.media_interfaces[handle.interface]).material
    keys = [stored()]
    mean_colour() = (img = colorbuffer(screen); sum(p -> Float64(p.r) + Float64(p.g) + Float64(p.b), img) / length(img))
    colours = [mean_colour()]

    plt.material.base_color = Hikari.TextureNodes.noise(Hikari.TextureNodes.xyz()).color
    RayMakie.poll_all_plots(screen, scene)
    push!(keys, stored()); push!(colours, mean_colour())
    plt.material = Hikari.Glass(ior = 1.5)
    RayMakie.poll_all_plots(screen, scene)
    push!(keys, stored()); push!(colours, mean_colour())

    # Glass returns the original constant Principled class; only the noisy graph
    # needs another stored type. The preset has no separate material path.
    @test keys[1].type_idx == keys[3].type_idx
    @test keys[2].type_idx != keys[1].type_idx
    @test counters(st) == before
    @test robj_of(plt).handle === handle
    @test allunique(colours)
    close(screen)
end

# Setting one field of a material stores again only the images of that field. A
# roughness moved by a slider recompiled the material and copied its base colour
# image to the GPU each time, a 4096² texture among them. The image the plot keeps
# a slot for is copied when its field is set, even to the same array changed in
# place, and only then.
@testset "mesh — a material field set alone moves no image" begin
    for material in (
            Hikari.Diffuse(color = Hikari.Texture(fill(Hikari.RGBSpectrum(0.2f0), 8, 8))),
            Hikari.Principled(base_color = Hikari.Texture(fill(Hikari.RGBSpectrum(0.2f0), 8, 8))),
        )
        field = material isa Hikari.Diffuse ? :color : :base_color
        scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube_mesh(); material))
        handle_before = robj_of(plt).handle
        gpu_image() = Array(
            Hikari.stored_array(
                st.hikari_scene.materials,
                Int.((robj_of(plt).owned[(field,)].slot, robj_of(plt).owned[(field,)].idx))
            )
        )
        @test all(==(Hikari.RGBSpectrum(0.2f0)), gpu_image())
        image = getfield(plt.material[], field)
        fill!(image.data, Hikari.RGBSpectrum(0.7f0))   # changed in place, not set

        plt.material.roughness = 0.6
        RayMakie.poll_all_plots(screen, scene)
        @test plt.material[].roughness == 0.6
        @test all(==(Hikari.RGBSpectrum(0.2f0)), gpu_image())
        @test robj_of(plt).handle === handle_before

        setproperty!(plt.material, field, image)       # set: copied into its slot
        RayMakie.poll_all_plots(screen, scene)
        @test all(==(Hikari.RGBSpectrum(0.7f0)), gpu_image())
        @test robj_of(plt).handle === handle_before
        close(screen)
    end
end

@testset "mesh — nested material fields upload only the assigned image" begin
    a = Hikari.Texture(fill(Hikari.RGBSpectrum(0.2f0), 8, 8))
    b = Hikari.Texture(fill(Hikari.RGBSpectrum(0.4f0), 8, 8))
    material = Hikari.Mix(Hikari.Diffuse(color = a), Hikari.Glossy(color = b); factor = 0.4)
    scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube_mesh(); material))
    handle = robj_of(plt).handle
    before = counters(st)
    slots = copy(robj_of(plt).owned)
    layout = st.hikari_scene.materials.layout
    images = length(st.hikari_scene.materials.texture_gpu_arrays)
    function gpu_image(path)
        h = robj_of(plt).owned[path]
        return Array(Hikari.stored_array(st.hikari_scene.materials, (Int(h.slot), Int(h.idx))))
    end
    try
        fill!(a.data, Hikari.RGBSpectrum(0.6f0))
        fill!(b.data, Hikari.RGBSpectrum(0.8f0))
        plt.material.a.roughness = 0.25
        RayMakie.poll_all_plots(screen, scene)
        @test plt.material[].a.roughness == 0.25
        @test all(==(Hikari.RGBSpectrum(0.2f0)), gpu_image((:a, :color)))
        @test all(==(Hikari.RGBSpectrum(0.4f0)), gpu_image((:b, :color)))

        @test to_value(plt.material.a.color) === a
        plt.material.a.color[] = a
        RayMakie.poll_all_plots(screen, scene)
        @test all(==(Hikari.RGBSpectrum(0.6f0)), gpu_image((:a, :color)))
        @test all(==(Hikari.RGBSpectrum(0.4f0)), gpu_image((:b, :color)))

        # Replacing a branch uploads its images, including arrays changed in place.
        plt.material.b = Hikari.Glossy(color = b, roughness = 0.3)
        RayMakie.poll_all_plots(screen, scene)
        @test all(==(Hikari.RGBSpectrum(0.8f0)), gpu_image((:b, :color)))
        @test counters(st) == before
        @test robj_of(plt).handle === handle
        @test robj_of(plt).owned == slots
        @test st.hikari_scene.materials.layout == layout
        @test length(st.hikari_scene.materials.texture_gpu_arrays) == images
    finally
        close(screen)
    end
end

@testset "mesh — a scalar image field keeps its slot across unrelated edits" begin
    image = fill(0.25, 4, 4)
    material = Hikari.Principled(base_color = (0.8, 0.2, 0.1), roughness = image)
    scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube_mesh(); material))
    slot = robj_of(plt).owned[(:roughness,)]
    handle = robj_of(plt).handle
    before = counters(st)
    image_on_device() = Array(Hikari.stored_array(st.hikari_scene.materials, (Int(slot.slot), Int(slot.idx))))
    try
        fill!(image, 0.75)
        plt.material.base_color = (0.1, 0.8, 0.2)
        RayMakie.poll_all_plots(screen, scene)
        @test image_on_device() == fill(0.25f0, 4, 4)
        plt.material.roughness = image
        RayMakie.poll_all_plots(screen, scene)
        @test image_on_device() == fill(0.75f0, 4, 4)
        @test robj_of(plt).owned[(:roughness,)] === slot
        @test robj_of(plt).handle === handle
        @test counters(st) == before
    finally
        close(screen)
    end
end

@testset "mesh — nested scalar edits reuse compiled kernels and material slots" begin
    image = Hikari.Texture(fill(Hikari.RGBSpectrum(0.3f0), 4, 4))
    material = Hikari.Mix(Hikari.Principled(base_color = image, roughness = 0.3), Hikari.Glass(); factor = 0.4)
    scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube_mesh(); material))
    dev = Hikari.mantle_device(st.hikari_scene.materials.backend)
    handle = robj_of(plt).handle
    before = counters(st)
    try
        colorbuffer(screen)
        # Warm every update and render path before counting compilation.
        for i in 1:3
            plt.material.a.roughness = 0.2 + 0.01 * i
            RayMakie.poll_all_plots(screen, scene)
            colorbuffer(screen)
        end
        arrays, layout = length(st.hikari_scene.materials.texture_gpu_arrays), st.hikari_scene.materials.layout
        slot = robj_of(plt).owned[(:a, :base_color)]
        Mantle.resetkernelcompiles!(dev)
        for i in 1:12
            plt.material.a.roughness = 0.2 + 0.01 * i
            RayMakie.poll_all_plots(screen, scene)
            colorbuffer(screen)
        end
        @test Mantle.kernelcompiles(dev).misses == 0
        @test (length(st.hikari_scene.materials.texture_gpu_arrays), st.hikari_scene.materials.layout) == (arrays, layout)
        @test robj_of(plt).owned[(:a, :base_color)] === slot
        @test robj_of(plt).handle === handle
        @test counters(st) == before
    finally
        close(screen)
    end
end

@testset "mesh — transform updates in place" begin
    scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube_mesh(); color = :red))
    before = counters(st)

    for f in 1:5
        Makie.translate!(plt, 0.1f0 * f, 0.0f0, 0.0f0)
        RayMakie.poll_all_plots(screen, scene)
    end

    @test counters(st) == before
    close(screen)
end

# Deformation: same faces, moved vertices. This is the case a BLAS refit exists
# for, and it currently rebuilds — the counter says so rather than the test
# pretending otherwise. When the refit lands, `refit_eligible_rebuilds` should
# stop climbing and this assertion is what will catch it not doing so.
#
# The faces array must be a fresh object each frame: `ComputePipeline.is_same`
# treats an aliased array as CHANGED (in-place mutation between resolves is
# undetectable), so handing back the same faces vector marks topology dirty and
# the deformation is misclassified.
@testset "mesh — deformation is refit-eligible, not topology" begin
    src = cube_mesh()
    pts = GeometryBasics.coordinates(src)
    fcs = GeometryBasics.faces(src)
    # The base must carry the SAME attribute set as the frames that replace it.
    # Starting from `normal_mesh` (which has uv and normals) and deforming into a
    # bare `Mesh` drops both, and dropping an attribute changes the vertex layout
    # — that first frame is a genuine topology rebuild, not a misclassification.
    base = GeometryBasics.Mesh(copy(pts), copy(fcs))
    scene, plt, screen, st = trace_fixture(s -> mesh!(s, base; color = :red))
    before = counters(st)

    for f in 1:6
        moved = [Point3f(v[1], v[2] + 0.01f0 * f, v[3]) for v in pts]
        plt[1] = GeometryBasics.Mesh(moved, copy(fcs))
        RayMakie.poll_all_plots(screen, scene)
    end

    eligible, topology = counters(st) .- before
    @test eligible + topology == 6          # every frame did something
    @test topology == 0                     # none of it was a topology change
    @test eligible == 6
    close(screen)
end

@testset "mesh — resize (vertex and face count change) is a topology rebuild" begin
    cube = cube_mesh()
    sphere = GeometryBasics.normal_mesh(GeometryBasics.Tesselation(Sphere(Point3f(0), 1.0f0), 16))
    @test length(GeometryBasics.faces(cube)) != length(GeometryBasics.faces(sphere))

    scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube; color = :red))
    before = counters(st)

    for f in 1:4
        plt[1] = isodd(f) ? sphere : cube
        RayMakie.poll_all_plots(screen, scene)
    end

    eligible, topology = counters(st) .- before
    @test topology == 4                     # a new BVH is genuinely required
    @test eligible == 0
    # The mesh survived the resize: still one instance, still traceable.
    @test Raycore.n_instances(st.hikari_scene.accel) >= 1
    @test robj_of(plt) !== nothing
    close(screen)
end

# ---------------------------------------------------------------------------
# Instances (meshscatter)
# ---------------------------------------------------------------------------

@testset "instances — recolour updates in place" begin
    pos = [Point3f(i, 0, 0) for i in 1:6]
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(s, pos; marker = cube_mesh(), markersize = 0.3f0, color = :red)
    )
    handles_before = robj_of(plt).handles

    plt.color = :blue
    RayMakie.poll_all_plots(screen, scene)

    # Same handles means no delete + re-push of the instance batch.
    @test robj_of(plt).handles === handles_before
    close(screen)
end

@testset "instances — material swap updates in place" begin
    pos = [Point3f(i, 0, 0) for i in 1:6]
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(
            s, pos; marker = cube_mesh(), markersize = 0.3f0,
            material = Hikari.Diffuse(color = Hikari.RGBSpectrum(0.5f0))
        )
    )
    handles_before = robj_of(plt).handles

    plt.material = Hikari.Diffuse(color = Hikari.RGBSpectrum(0.9f0, 0.1f0, 0.1f0, 1.0f0))
    RayMakie.poll_all_plots(screen, scene)

    @test robj_of(plt).handles === handles_before
    # The handle check alone passed for a build where `material =` never reached
    # the image at all: `extract_meshscatter_materials` merged the cycler's
    # palette colour over the template, so every instance rendered teal both
    # before and after the swap. Assert the material that is actually stored.
    # meshscatter stores Kd as a `TexHandle` (tagged: kind + inline payload),
    # not as the `Texture` the mesh path uses, so the accessor differs —
    # `const_spectrum`, not `constant_value`.
    mats = robj_of(plt).materials
    @test !isempty(mats)
    @test all(
        m -> Hikari.const_spectrum(Hikari.TexHandle(m.color)) ==
            Hikari.RGBSpectrum(0.9f0, 0.1f0, 0.1f0, 1.0f0), mats
    )
    close(screen)
end

# `material =` with no user-set colour must be used as given. `color` is a
# cycled attribute, so Makie writes `:cycled` into it when unset and a
# `!== nothing` test mistakes that for an explicit colour — which is how the
# palette colour came to overwrite the material on every meshscatter.
@testset "instances — an unset colour does not overwrite the material" begin
    pos = [Point3f(i, 0, 0) for i in 1:4]
    red = Hikari.RGBSpectrum(0.8f0, 0.2f0, 0.2f0, 1.0f0)
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(
            s, pos; marker = cube_mesh(), markersize = 0.3f0,
            material = Hikari.Diffuse(color = red)
        )
    )

    mats = robj_of(plt).materials
    @test length(mats) == length(pos)
    @test all(m -> Hikari.const_spectrum(Hikari.TexHandle(m.color)) == red, mats)
    close(screen)
end

@testset "instances — moving positions keeps the batch" begin
    pos = Observable([Point3f(i, 0, 0) for i in 1:6])
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(s, pos; marker = cube_mesh(), markersize = 0.3f0, color = :red)
    )
    handles_before = robj_of(plt).handles

    for f in 1:5
        pos[] = [Point3f(i, 0.1f0 * f, 0) for i in 1:6]
        RayMakie.poll_all_plots(screen, scene)
    end

    # Instance transforms refit; the batch is not rebuilt while the count holds.
    @test robj_of(plt).handles === handles_before
    close(screen)
end

@testset "instances — resize rebuilds the batch and stays consistent" begin
    pos = Observable([Point3f(i, 0, 0) for i in 1:6])
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(s, pos; marker = cube_mesh(), markersize = 0.3f0, color = :red)
    )

    for n in (12, 3, 9)
        pos[] = [Point3f(i, 0, 0) for i in 1:n]
        RayMakie.poll_all_plots(screen, scene)
        # The instance count must actually follow, not just avoid throwing —
        # a stale batch keeps the previous count and renders the wrong scene.
        @test Raycore.n_instances(st.hikari_scene.accel) == n
        @test robj_of(plt) !== nothing
    end
    close(screen)
end

@testset "instances — marker mesh resize rebuilds, plot stays valid" begin
    pos = [Point3f(i, 0, 0) for i in 1:4]
    marker = Observable{Any}(cube_mesh())
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(s, pos; marker = marker, markersize = 0.3f0, color = :red)
    )

    marker[] = GeometryBasics.normal_mesh(GeometryBasics.Tesselation(Sphere(Point3f(0), 1.0f0), 12))
    RayMakie.poll_all_plots(screen, scene)

    @test robj_of(plt) !== nothing
    @test Raycore.n_instances(st.hikari_scene.accel) == length(pos)
    close(screen)
end

@testset "mesh — native roughness pairs retain image slots" begin
    u = fill(0.2f0, 8, 8)
    v = fill(0.4f0, 8, 8)
    material = Hikari.Conductor(roughness = (u, v), reflectance = (0.3, 0.5, 0.7))
    scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube_mesh(); material))
    handle = robj_of(plt).handle
    slots = copy(robj_of(plt).owned)
    layout = st.hikari_scene.materials.layout
    arrays = length(st.hikari_scene.materials.texture_gpu_arrays)
    before = counters(st)
    function image(path)
        h = robj_of(plt).owned[path]
        return Array(Hikari.stored_array(st.hikari_scene.materials, (Int(h.slot), Int(h.idx))))
    end
    try
        @test haskey(slots, (:roughness, 1)) && haskey(slots, (:roughness, 2))
        fill!(u, 0.6f0)
        fill!(v, 0.8f0)
        plt.material.reflectance = (0.2, 0.4, 0.6)
        RayMakie.poll_all_plots(screen, scene)
        @test all(==(0.2f0), image((:roughness, 1)))
        @test all(==(0.4f0), image((:roughness, 2)))
        plt.material.roughness = (u, v)
        RayMakie.poll_all_plots(screen, scene)
        @test all(==(0.6f0), image((:roughness, 1)))
        @test all(==(0.8f0), image((:roughness, 2)))
        @test robj_of(plt).owned == slots
        @test robj_of(plt).handle === handle
        @test counters(st) == before
        @test st.hikari_scene.materials.layout == layout
        @test length(st.hikari_scene.materials.texture_gpu_arrays) == arrays
    finally
        close(screen)
    end
end

@testset "raster material parameters use canonical native fields" begin
    for model in (Hikari.Conductor, Hikari.CoatedDiffuse)
        material = model(roughness = (0.1f0, 0.3f0))
        @test RayMakie.raster_material(material).a[2] ≈ Hikari.roughness_to_α(0.2f0)
        @test RayMakie.raster_material(model(roughness = (0.1f0, 0.3f0), remap_roughness = false)).a[2] ≈ 0.2f0
    end
    @test first(RayMakie.glass_alpha_ior(Hikari.Dielectric(roughness = (0.1f0, 0.3f0)))) ≈ Hikari.roughness_to_α(0.2f0)
    material = Hikari.CoatedConductor(
        interface_roughness = (0.1f0, 0.3f0),
        conductor_roughness = (0.2f0, 0.4f0), reflectance = (0.3, 0.5, 0.7)
    )
    raster = RayMakie.raster_material(material)
    @test raster.a[2] ≈ Hikari.roughness_to_α(0.2f0)
    @test raster.b[4] ≈ Hikari.roughness_to_α(0.3f0)
    @test RayMakie.raster_material(Hikari.with_field(material, :reflectance, (0.1, 0.2, 0.3))).c != raster.c
end
