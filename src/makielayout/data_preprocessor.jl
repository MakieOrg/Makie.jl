mutable struct LinearTransform{T}
    scale::T
    offset::T
end

LinearTransform{Float64}() = LinearTransform(1.0, 0.0)
LinearTransform{T}() where {T <: Vec} = LinearTransform(T(1), T(0))

(t::LinearTransform)(x) = @. t.scale * x + t.offset
Base.inv(t::LinearTransform) = LinearTransform(1.0 ./ t.scale, - t.offset ./ t.scale)

struct AutoScaling{N, T}
    transforms::NTuple{N, LinearTransform{T}}
    updater::Observable{Nothing}

    # We want:
    # 1. 1 / threshold < width / abs_maximum < threshold
    # 2. -threshold < minimum < maximum < threshold
    # if either is false, rescale minimum and maximum to -target, target

    threshold::Vec{N, T}
    target::Vec{N, T}
end

function AutoScaling(dims::Int, threshold = 1e6, target = 1e3)
    return AutoScaling(
        ntuple(_ -> LinearTransform{Float64}(), dims),
        Observable(nothing), 
        Vec{dims, Float64}(threshold),
        Vec{dims, Float64}(target)
    )
end

function update_limits!(auto::AutoScaling{2}, limits::Rect2{Float64})
    @info "Autolimits update"
    _min = minimum(limits)
    _max = maximum(limits)
    @info "Limits: $_min, $_max"

    requires_update = false

    for dim in 1:2
        x0 = auto.transforms[dim](_min[dim])
        x1 = auto.transforms[dim](_max[dim])

        check1 = 1.0 / auto.threshold[dim] < x1 - x0 < auto.threshold[dim]
        check2 = -auto.threshold[dim] < x0
        check3 = x1 < auto.threshold[dim]
        @info "[$dim] $x0, $x1, $(x1-x0) $check1 $check2 $check3"

        if !(check1 && check2 && check3)
            T = auto.transforms[dim]
            T.scale  = 2 * auto.target[dim] ./ (_max[dim] .- _min[dim]) 
            T.offset = auto.target[dim] - T.scale .* _max[dim]
            @info "Tranform $T"
            requires_update = true
        end
    end

    if requires_update
        notify(auto.updater)
    end

    return requires_update
end

function apply_inv_autoscale(auto::AutoScaling{2}, limits::Rect2)
    x, y = minimum(limits)
    w, h = widths(limits)
    Tx, Ty = inv.(auto.transforms)
    return Rect2{Float64}(Tx(x), Ty(y), Tx.scale * w, Ty.scale * h)
end

function apply_inv_autoscale(auto::AutoScaling{2}, limits::Rect)
    x, y, z = minimum(limits)
    w, h, d = widths(limits)
    Tx, Ty = inv.(auto.transforms)
    return Rect3{Float64}(Vec3(Tx(x), Ty(y), z), Vec3(Tx.scale * w, Ty.scale * h, d))
end

function apply_autoscale(auto::AutoScaling{2}, limits::Rect2)
    x, y = minimum(limits)
    w, h = widths(limits)
    Tx, Ty = auto.transforms
    return Rect2{Float64}(Tx(x), Ty(y), Tx.scale * w, Ty.scale * h)
end

function map_autoscale(auto::AutoScaling{2}, args::Tuple{<: Vector{T}}) where {T <: VecTypes}
    return (map(auto.updater) do _
        output = map(args[1]) do p
            T(auto.transforms[1](p[1]), auto.transforms[2].(p[2]))
        end
        return output
    end, )
end

function map_autoscale(auto::AutoScaling{2}, args::Tuple{<: Vector, <: Vector})
    return (
        map(auto.updater) do _ 
            x = auto.transforms[1].(args[1])
            @info "transformed: $x"
            return x
        end,
        map(auto.updater) do _ 
            x = auto.transforms[2].(args[2])
            @info "transformed: $x"
            return x
        end
    )
end

function map_autoscale(auto::AutoScaling{2}, args::Tuple{<: Rect2})
    return (map(auto.updater) do _
        x, y = minimum(args[1])
        w, h = widths(args[1])
        Tx, Ty = auto.transforms
        return Rect2{Float64}(Tx(x), Ty(y), Tx.scale * w, Ty.scale * h)
    end,)
end

function map_autoscale(auto::AutoScaling{2}, args::Tuple{Observable{<: Rect2}})
    return (map(auto.updater, args...) do _, rect
        x, y = minimum(rect)
        w, h = widths(rect)
        Tx, Ty = auto.transforms
        return Rect2{Float64}(Tx(x), Ty(y), Tx.scale * w, Ty.scale * h)
    end,)
end

# can't be bothered
function map_autoscale(auto::AutoScaling{2}, args)
    @info "Skipped $(typeof(args))"
    return args
end

# ...