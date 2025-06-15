using GLMakie, GeometryBasics, RPRMakie, RadeonProRender
using Colors, FileIO
using Colors: N0f8
RPR = RadeonProRender
GLMakie.activate!(float = true, focus_on_show = false)
cat = load(GLMakie.assetpath("cat.obj"))

begin
    context = RPR.Context()

    matsys = RPR.MaterialSystem(context, 0)
    emissive = RPR.EmissiveMaterial(matsys)
    diffuse = RPR.DiffuseMaterial(matsys)

    fig = Figure(size = (1000, 1000))
    ax = LScene(fig[1, 1], show_axis = false)
    for i in 4:4:12
        n = i + 1
        y = LinRange(0, i, n)
        y2 = (y ./ 2) .- 2
        lines!(ax, fill((i - 5) ./ 2, n), y2, sin.(y) .+ 1, linewidth = 5)
    end
    mesh!(ax, Rect3f(Vec3f(-3, -3, -0.1), Vec3f(6, 6, 0.1)), color = :white)
    mesh!(ax, Sphere(Point3f(0, 0, 2), 0.1), material = emissive)
    display(fig)
end
# fetch(task)
begin
    context, task = RPRMakie.replace_scene_rpr!(ax.scene, context, matsys)
    emissive.color = Vec3f(4, 2, 2)
end

begin

    uber1.color = Vec4f(1, 1, 1, 1)
    uber1.diffuse_weight = Vec4f(0, 0, 0, 0)
    uber1.diffuse_roughness = Vec4f(1, 1, 1, 1)
    uber1.reflection_color = Vec4f(0.996078, 0.858824, 0.639216, 0)
    uber1.reflection_weight = Vec4f(1, 1, 1, 1)
    uber1.reflection_roughness = Vec4f(0, 0, 0, 0)
    uber1.reflection_anisotropy = Vec4f(0, 0, 0, 0)
    uber1.reflection_anisotropy_rotation = Vec4f(0, 0, 0, 0)
    uber1.reflection_ior = Vec4f(1.36, 1.36, 1.36, 1.36)
    uber1.refraction_color = Vec4f(0.996078, 0.858824, 0.639216, 0)
    uber1.refraction_weight = Vec4f(1, 1, 1, 1)
    uber1.refraction_roughness = Vec4f(0, 0, 0, 0)
    uber1.refraction_ior = Vec4f(1.36, 1.36, 1.36, 1.36)
    uber1.refraction_absorption_color = Vec4f(0.996078, 0.858824, 0.639216, 0)
    uber1.refraction_absorption_distance = Vec4f(0, 0, 0, 0)
    uber1.refraction_caustics = Vec4f(0)
    uber1.coating_color = Vec4f(1, 1, 1, 1)
    uber1.coating_weight = Vec4f(0, 0, 0, 0)
    uber1.coating_roughness = Vec4f(0, 0, 0, 0)
    uber1.coating_ior = Vec4f(3, 3, 3, 3)
    uber1.coating_metalness = Vec4f(0, 0, 0, 0)
    uber1.coating_transmission_color = Vec4f(1, 1, 1, 1)
    uber1.coating_thickness = Vec4f(0, 0, 0, 0)
    uber1.sheen = Vec4f(1, 1, 1, 1)
    uber1.sheen_tint = Vec4f(0, 0, 0, 0)
    uber1.sheen_weight = Vec4f(0, 0, 0, 0)
    uber1.emission_color = Vec4f(1, 1, 1, 1)
    uber1.emission_weight = Vec3f(0, 0, 0)
    uber1.transparency = Vec4f(0, 0, 0, 0)
    uber1.sss_scatter_color = Vec4f(0, 0, 0, 0)
    uber1.sss_scatter_distance = Vec4f(0, 0, 0, 0)
    uber1.sss_scatter_direction = Vec4f(0, 0, 0, 0)
    uber1.sss_weight = Vec4f(0, 0, 0, 0)
    uber1.backscatter_weight = Vec4f(0, 0, 0, 0)
    uber1.backscatter_color = Vec4f(1, 1, 1, 1)

    uber1.reflection_mode = UInt(RPR.RPR_UBER_MATERIAL_IOR_MODE_PBR)
    uber1.emission_mode = UInt(RPR.RPR_UBER_MATERIAL_EMISSION_MODE_SINGLESIDED)
    uber1.coating_mode = UInt(RPR.RPR_UBER_MATERIAL_IOR_MODE_PBR)
    uber1.sss_multiscatter = false
    uber1.refraction_thin_surface = false
end


begin
    uber2.color = Vec4f(0.501961f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.diffuse_weight = Vec4f(1.0f0, 1.0f0, 1.0f0, 1.0f0)
    uber2.diffuse_roughness = Vec4f(0.5f0, 0.5f0, 0.5f0, 0.5f0)
    uber2.reflection_color = Vec4f(0.490196f0, 0.490196f0, 0.490196f0, 0.0f0)
    uber2.reflection_weight = Vec4f(0.99f0, 0.99f0, 0.99f0, 0.99f0)
    uber2.reflection_roughness = Vec4f(0.008f0, 0.008f0, 0.008f0, 0.008f0)
    uber2.reflection_anisotropy = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.reflection_anisotropy_rotation = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.reflection_mode = 1
    uber2.reflection_ior = Vec4f(1.46f0, 1.46f0, 1.46f0, 1.46f0)
    uber2.refraction_color = Vec4f(1.0f0, 1.0f0, 1.0f0, 1.0f0)
    uber2.refraction_weight = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.refraction_roughness = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.refraction_ior = Vec4f(1.5f0, 1.5f0, 1.5f0, 1.5f0)
    uber2.refraction_thin_surface = Vec4f(0)
    uber2.refraction_absorption_color = Vec4f(1.0f0, 1.0f0, 1.0f0, 0.0f0)
    uber2.refraction_absorption_distance = Vec4f(1.0f0, 1.0f0, 1.0f0, 0.0f0)
    uber2.refraction_caustics = 1
    uber2.coating_color = Vec4f(0.490196f0, 0.490196f0, 0.490196f0, 0.0f0)
    uber2.coating_weight = Vec4f(1.0f0, 1.0f0, 1.0f0, 1.0f0)
    uber2.coating_roughness = Vec4f(0.008f0, 0.008f0, 0.008f0, 0.008f0)
    uber2.coating_mode = 1
    uber2.coating_ior = Vec4f(1.46f0, 1.46f0, 1.46f0, 1.46f0)
    uber2.coating_metalness = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.coating_transmission_color = Vec4f(0.0f0, 0.0f0, 0.0f0, 1.0f0)
    uber2.coating_thickness = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.sheen = Vec4f(1.0f0, 1.0f0, 1.0f0, 1.0f0)
    uber2.sheen_tint = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.sheen_weight = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.emission_color = Vec4f(1.0f0, 1.0f0, 1.0f0, 1.0f0)
    uber2.emission_weight = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.emission_mode = 1
    uber2.transparency = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.sss_scatter_color = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.sss_scatter_distance = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.sss_scatter_direction = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.sss_weight = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.sss_multiscatter = false
    uber2.backscatter_weight = Vec4f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    uber2.backscatter_color = Vec4f(0.501961f0, 0.0f0, 0.0f0, 0.0f0)
end

begin
    uber3.color = Vec4(0.752941, 0.596078, 0.443137, 0.0)
    uber3.diffuse_weight = Vec4(1.0, 1.0, 1.0, 1.0)
    uber3.diffuse_roughness = Vec4(0.5, 0.5, 0.5, 0.5)
    uber3.reflection_color = Vec4(0.666667, 0.490196, 0.313726, 0.0)
    uber3.reflection_weight = Vec4(1.0, 1.0, 1.0, 1.0)
    uber3.reflection_roughness = Vec4(0.3, 0.3, 0.3, 0.3)
    uber3.reflection_anisotropy = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.reflection_anisotropy_rotation = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.reflection_mode = 2
    uber3.reflection_ior = Vec4(1.0, 1.0, 1.0, 1.0)
    uber3.refraction_color = Vec4(1.0, 1.0, 1.0, 1.0)
    uber3.refraction_weight = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.refraction_roughness = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.refraction_ior = Vec4(1.5, 1.5, 1.5, 1.5)
    uber3.refraction_thin_surface = 0
    uber3.refraction_absorption_color = Vec4(1.0, 1.0, 1.0, 0.0)
    uber3.refraction_absorption_distance = Vec4(1.0, 1.0, 1.0, 0.0)
    uber3.refraction_caustics = 1
    uber3.coating_color = Vec4(0.752941, 0.596078, 0.443137, 0.0)
    uber3.coating_weight = Vec4(1.0, 1.0, 1.0, 1.0)
    uber3.coating_roughness = Vec4(0.42, 0.42, 0.42, 0.42)
    uber3.coating_mode = 1
    uber3.coating_ior = Vec4(1.7, 1.7, 1.7, 1.7)
    uber3.coating_metalness = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.coating_transmission_color = Vec4(0.0, 0.0, 0.0, 1.0)
    uber3.coating_thickness = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.sheen = Vec4(1.0, 1.0, 1.0, 1.0)
    uber3.sheen_tint = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.sheen_weight = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.emission_color = Vec4(1.0, 1.0, 1.0, 1.0)
    uber3.emission_weight = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.emission_mode = 1
    uber3.transparency = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.sss_scatter_color = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.sss_scatter_distance = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.sss_scatter_direction = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.sss_weight = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.sss_multiscatter = 0
    uber3.backscatter_weight = Vec4(0.0, 0.0, 0.0, 0.0)
    uber3.backscatter_color = Vec4(0.752941, 0.596078, 0.443137, 0.0)
end


begin
    uber4.color = Vec4f(1.0, 1.0, 1.0, 1.0)
    uber4.diffuse_weight = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.diffuse_roughness = Vec4f(1.0, 1.0, 1.0, 1.0)
    uber4.reflection_color = Vec4f(0.501961, 0.501961, 0.501961, 0.0)
    uber4.reflection_weight = Vec4f(1.0, 1.0, 1.0, 1.0)
    uber4.reflection_roughness = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.reflection_anisotropy = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.reflection_anisotropy_rotation = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.reflection_mode = 1
    uber4.reflection_ior = Vec4f(1.33, 1.33, 1.33, 1.33)
    uber4.refraction_color = Vec4f(0.501961, 0.898039, 0.996078, 0.0)
    uber4.refraction_weight = Vec4f(1.0, 1.0, 1.0, 1.0)
    uber4.refraction_roughness = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.refraction_ior = Vec4f(1.33, 1.33, 1.33, 1.33)
    uber4.refraction_thin_surface = 0
    uber4.refraction_absorption_color = Vec4f(0.501961, 0.898039, 0.996078, 0.0)
    uber4.refraction_absorption_distance = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.refraction_caustics = 0
    uber4.coating_color = Vec4f(1.0, 1.0, 1.0, 1.0)
    uber4.coating_weight = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.coating_roughness = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.coating_mode = 1
    uber4.coating_ior = Vec4f(3.0, 3.0, 3.0, 3.0)
    uber4.coating_metalness = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.coating_transmission_color = Vec4f(1.0, 1.0, 1.0, 1.0)
    uber4.coating_thickness = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.sheen = Vec4f(1.0, 1.0, 1.0, 1.0)
    uber4.sheen_tint = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.sheen_weight = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.emission_color = Vec4f(1.0, 1.0, 1.0, 1.0)
    uber4.emission_weight = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.emission_mode = 1
    uber4.transparency = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.sss_scatter_color = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.sss_scatter_distance = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.sss_scatter_direction = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.sss_weight = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.sss_multiscatter = 0
    uber4.backscatter_weight = Vec4f(0.0, 0.0, 0.0, 0.0)
    uber4.backscatter_color = Vec4f(1.0, 1.0, 1.0, 1.0)
end
