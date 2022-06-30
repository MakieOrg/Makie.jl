function inherit(scene, attr::Symbol, default_value)
    if haskey(scene.theme, attr)
        lift(identity, scene.theme[attr])
    else
        inherit(scene.parent, attr, default_value)
    end
end

function inherit(::Nothing, attr::Symbol, default_value)
    default_value
end

inherit(scene, attr::NTuple{1, <: Symbol}, default_value) where N = inherit(scene, attr[begin], default_value)


function inherit(scene, attr::NTuple{N, <: Symbol}, default_value) where N
    current_dict = scene.theme
    for i in 1:(N-1)
        if haskey(current_dict, attr[i])
            current_dict = current_dict[attr[i]]
        else
            break
        end
    end

    if haskey(current_dict, attr[N])
        return lift(identity, current_dict[attr[N]])
    else
        return inherit(scene.parent, attr, default_value)
    end
end

function inherit(::Nothing, attr::NTuple{N, Symbol}, default_value::T) where {N, T}
    default_value
end

function default_attributes(::Type{LineAxis})
    Attributes(
        endpoints = (Point2f(0, 0), Point2f(100, 0)),
        trimspine = false,
        limits = (0f0, 100f0),
        flipped = false,
        flip_vertical_label = false,
        ticksize = 6f0,
        tickwidth = 1f0,
        tickcolor = RGBf(0, 0, 0),
        tickalign = 0f0,
        ticks = Makie.automatic,
        tickformat = Makie.automatic,
        ticklabelalign = (:center, :top),
        ticksvisible = true,
        ticklabelrotation = 0f0,
        ticklabelsize = 20f0,
        ticklabelcolor = RGBf(0, 0, 0),
        ticklabelsvisible = true,
        spinewidth = 1f0,
        label = "label",
        labelsize = 20f0,
        labelcolor = RGBf(0, 0, 0),
        labelvisible = true,
        ticklabelspace = Makie.automatic,
        ticklabelpad = 3f0,
        labelpadding = 5f0,
        reversed = false,
        minorticksvisible = true,
        minortickalign = 0f0,
        minorticksize = 4f0,
        minortickwidth = 1f0,
        minortickcolor = :black,
        minorticks = Makie.automatic,
        scale = identity,
    )
end


function attributenames(::Type{LegendEntry})
    (:label, :labelsize, :labelfont, :labelcolor, :labelhalign, :labelvalign,
        :patchsize, :patchstrokecolor, :patchstrokewidth, :patchcolor,
        :linepoints, :linewidth, :linecolor, :linestyle,
        :markerpoints, :markersize, :markerstrokewidth, :markercolor, :markerstrokecolor,
        :polypoints, :polystrokewidth, :polycolor, :polystrokecolor)
end

function extractattributes(attributes::Attributes, typ::Type)
    extracted = Attributes()
    for name in attributenames(typ)
        if haskey(attributes, name)
            extracted[name] = attributes[name]
        end
    end
    extracted
end

function extractattributes(leg::Legend, typ::Type)
    extracted = Attributes()
    for name in attributenames(typ)
        if hasproperty(leg, name)
            extracted[name] = getproperty(leg, name)
        end
    end
    extracted
end
