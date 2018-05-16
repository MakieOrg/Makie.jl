function default_theme(scene)
    light = Vec3f0[Vec3f0(1.0,1.0,1.0), Vec3f0(0.1,0.1,0.1), Vec3f0(0.9,0.9,0.9), Vec3f0(20,20,20)]
    Theme(
        color = :blue,
        linewidth = 1,
        visible = true,
        light = light,
        transformation = nothing,
        model = nothing,
        alpha = 1.0,
        #drawover = false,
    )
end

function calculate_values!(scene::SceneLike, attributes, args)
    if haskey(attributes, :colormap) && value(attributes[:colormap]) != nothing
        delete!(attributes, :color) # color is overwritten by colormap
        replace_nothing!(attributes, :colorrange) do
            map(to_node(args[3])) do arg
                Vec2f0(extrema(arg))
            end
        end
    else
        delete!(attributes, :colormap)
        delete!(attributes, :colorrange)
    end
    replace_nothing!(attributes, :model) do
        replace_nothing!(attributes, :transformation) do
            Transformation(scene)
        end
        value(attributes[:transformation]).model
    end
end

function calculate_values!(scene::SceneLike, ::Type{Scatter}, attributes, args)
    calculate_values!(scene, attributes, args)
    replace_nothing!(attributes, :marker_offset) do
        # default to middle
        map(x-> Vec2f0((x .* (-0.5f0))), attributes[:markersize])
    end
end

function default_theme(scene, ::Type{Scatter})
    Theme(;
        default_theme(scene)...,
        marker = Circle,
        markersize = 0.1,
        strokecolor = RGBA(0, 0, 0, 0),
        strokewidth = 0.0,
        glowcolor = RGBA(0, 0, 0, 0),
        glowwidth = 0.0,
        rotations = Billboard(),
        intensity = nothing,
        colormap = nothing,
        colorrange = nothing,
        marker_offset = nothing,
        fxaa = false
    )
end


function default_theme(scene, ::Type{Meshscatter})
    Theme(;
        default_theme(scene)...,
        marker = Sphere(Point3f0(0), 0.1f0),
        markersize = 0.1,
        rotations = Vec4f0(0, 0, 0, 1),
        intensity = nothing,
        colormap = nothing,
        colorrange = nothing,
        fxaa = true
    )
end

function default_theme(scene, ::Type{<: Union{Lines, Linesegments}})
    Theme(;
        default_theme(scene)...,
        linewidth = 1.0,
        linestyle = nothing,
        fxaa = false
    )
end


function default_theme(scene, ::Type{Text})
    Theme(;
        default_theme(scene)...,
        color = :black,
        strokecolor = (:black, 0.0),
        strokewidth = 0,
        font = theme(scene, :font),
        align = (:left, :bottom),
        rotation = 0.0,
        textsize = 20,
        position = Point2f0(0),
    )
end

Theme(;kw_args...) = Dict(kw_args)
struct Heatmap end

function default_theme(scene, ::Type{Heatmap})
    Theme(;
        #default_theme(scene)...,
        #colormap = theme(scene, :colormap),
        colorrange = nothing,
        linewidth = 0.0,
        levels = 1,
        fxaa = true,
        interpolate = false
    )
end


function default_theme(scene, ::Type{Image})
    Theme(;
        default_theme(scene)...,
        colormap = [RGBAf0(0,0,0,1), RGBAf0(1,1,1,1)],
        fxaa = false,
    )
end
function default_theme(scene, ::Type{Surface})
    Theme(;
        default_theme(scene)...,
        colormap = scene.theme[:colormap],
        image = nothing,
        fxaa = true,
    )
end


function default_theme(scene, ::Type{Mesh})
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        interpolate = false,
        shading = true
    )
end


function default_theme(scene, ::Type{Volume})
    Theme(;
        default_theme(scene)...,
        fxaa = true,
        isovalue = 0.6,
        algorithm = :iso,
        absorption = 1f0,
        isovalue = 0.5f0,
        isorange = 0.01f0,
        colormap = theme(scene, :colormap),
        colorrange = Vec2f0(0, 1)
    )
end

# Basic Recipe themes

function default_theme(scene, ::Type{Contour})
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = nothing,
        levels = 5,
        linewidth = 1.0,
        fillrange = false,
    )
end
