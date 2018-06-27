AbsoluteRectangle(mini::Vec{N,T}, maxi::Vec{N,T}) where {N,T} = HyperRectangle{N,T}(mini, maxi-mini)

AABB(a) = AABB{Float32}(a)
function (B::Type{AABB{T}})(a::Pyramid) where T
    w,h = a.width/T(2), a.length
    m = Vec{3,T}(a.middle)
    B(m-Vec{3,T}(w,w,0), m+Vec{3,T}(w, w, h))
end
(B::Type{AABB{T}})(a::Cube) where {T} = B(origin(a), widths(a))
(B::Type{AABB{T}})(a::AbstractMesh) where {T} = B(vertices(a))
(B::Type{AABB{T}})(a::NativeMesh) where {T} = B(gpu_data(a.data[:vertices]))


function (B::Type{AABB{T}})(
        positions, scale, rotation,
        primitive::AABB{T}
    ) where T

    ti = TransformationIterator(positions, scale, rotation)
    B(ti, primitive)
end
function (B::Type{AABB{T}})(instances::Instances) where T
    ti = TransformationIterator(instances)
    B(ti, B(instances.primitive))
end

function transform(translation, scale, rotation, points)
    _max = Vec3f0(typemin(Float32))
    _min = Vec3f0(typemax(Float32))
    for p in points
        x = scale.*Vec3f0(p)
        rv = rotation*Vec4f0(x[1], x[2], x[3], 1f0)
        x = Vec3f0(rv[1], rv[2], rv[3])
        x = Vec3f0(translation)+x
        _min = min.(_min, x)
        _max = max.(_max, x)
    end
    AABB{Float32}(_min, _max-_min)
end

function (B::Type{AABB{T}})(
      ti::TransformationIterator, primitive::AABB{T}
    ) where T
    state = start(ti)
    if done(ti, state)
        return primitive
    end
    tsr::Tuple{Point3f0, Vec3f0, Mat4f0}, state = next(ti, state)
    points = decompose(Point3f0, primitive)::Vector{Point3f0}
    bb = transform(tsr[1], tsr[2], tsr[3], points)
    while !done(ti, state)
        tsr, state = next(ti, state)
        translatet_bb = transform(tsr[1], tsr[2], tsr[3], points)
        bb = union(bb, translatet_bb)
    end
    bb
end
