
abstract type Unit end
abstract type Composable{unit} end

struct DeviceUnit <: Unit end

mutable struct Context{Unit} <: Composable{Unit}
    children
    boundingbox
    transformation
end
function scale_trans(b)
    m = minimum(b)
    w = widths(b)
    T = eltype(w)
    # make code work also for N == 2
    w3 = ndims(w) > 2 ?  w[3] : one(T)
    m3 = ndims(m) > 2 ? m[3] : zero(T)
    Vec3f0(w[1], w[2], w3), Vec3f0(m[1], m[2], m3)
end
function translationmatrix(b)
    s,t = scale_trans(b)
    Mat4f0( # always return float32 matrix
        s[1], 0   , 0 , 0,
        0   , s[2], 0 , 0,
        0   , 0   , s[3], 0,
        t[1], t[2], t[3], 1,
    )
end
function inversetransformation(b)
    s,t = scale_trans(b)
    s = 1f0/s
    t = -t
    Mat4f0( # always return float32 matrix
        s[1], 0   , 0 , 0,
        0   , s[2], 0 , 0,
        0   , 0   , s[3], 0,
        t[1], t[2], t[3], 1,
    )
end
layout!(b, c) =  layout!(b, (c,))[1]
layout!(b, c, composable...) = layout!(b, (c,composable...))
function combine_s_t(scale_trans1, scale_trans2)
    s1,t1 = scale_trans1
    s2,t2 = scale_trans2
    s2 = 1f0./s2
    t2 = -t2
    s,t = s1.*s2, t1+t2
    Mat4f0( # always return float32 matrix
        s[1], 0   , 0 , 0,
        0   , s[2], 0 , 0,
        0   , 0   , s[3], 0,
        t[1], t[2], t[3], 1,
    )
end
function layout!(b, composables::Union{Tuple, Vector})
    st_target = const_lift(scale_trans, b)
    map(composables) do composable
        st_being = const_lift(scale_trans, boundingbox(composable))
        transform!(composable, map(combine_s_t, st_target, st_being))
        composable
    end
end

export layout!


Context() = Context{DeviceUnit}(Composable[], Node(AABB{Float32}(Vec3f0(0), Vec3f0(0))), Node(eye(Mat{4,4, Float32})))
Context(trans::Node{Mat{4,4, Float32}}) = Context{DeviceUnit}(Composable[], Node(AABB{Float32}(Vec3f0(0), Vec3f0(0))), trans)
function Context(a::Composable...; parent=Context())
    append!(parent, a)
    parent
end
boundingbox(c::Composable) = c.boundingbox
transformation(c::Composable) = c.transformation

function transform!(c::Composable, model)
    c.transformation = const_lift(*, model, transformation(c))
    for elem in c.children
        transform!(elem, c.transformation)
    end
    c
end
function transformation(c::Composable, model)
    c.transformation = const_lift(*, model, c.transformation)
    for elem in c.children
        transformation(elem, c.transformation)
    end
    c
end

convert!(::Type{unit}, x::Composable) where {unit <: Unit} = x # We don't do units just yet

function Base.append!(context::Context{unit}, x::Union{Vector{Composable}, NTuple{N, Composable}}) where {unit <: Unit, N}
    for elem in x
        push!(context, elem)
    end
    context
end

function Base.push!(context::Context{unit}, x::Composable) where unit <: Unit
    x = convert!(unit, x)
    context.boundingbox = const_lift(transformation(x), transformation(context), boundingbox(x), boundingbox(context)) do transa, transb, a,b
        a = transa*a
        b = transb*b
         # we need some zero element for an empty context
         # sadly union(zero(AABB), ...) doesn't work for this
        if a == AABB{Float32}(Vec3f0(0), Vec3f0(0))
            return b
        elseif b == AABB{Float32}(Vec3f0(0), Vec3f0(0))
            return a
        end
        union(a, b)
    end
    transformation(x, transformation(context))
    push!(context.children, x)
    context
end


export transformation
