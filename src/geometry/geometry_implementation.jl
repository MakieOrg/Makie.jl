# Minimal GeometryBasic implementation to test compile times
# include("points.jl")
# include("vec.jl")
# include("mat.jl")

using GeometryBasics
include("quaternions.jl")

# type aliases for convenience
const Point1 = Point{1,Float64}
const Point2 = Point{2,Float64}
const Point3 = Point{3,Float64}
const Point1f = Point{1,Float32}
const Point2f = Point{2,Float32}
const Point3f = Point{3,Float32}

const Vec1f = Vec{1,Float32}
const Vec2f = Vec{2,Float32}
const Vec3f = Vec{3,Float32}
const Vec4f = Vec{4,Float32}

const Mat3f = Mat3{Float32}
const Mat4f = Mat4{Float32}

include("projection.jl")
