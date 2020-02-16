#=
A lot of visualization forms in GLVisualize are realised in the form of instanced
particles. This is because they can be handled very efficiently by OpenGL.
There are quite a few different ways to feed instances with different attributes.
The main constructor for particles is a tuple of (Primitive, Position), whereas
position can come in all forms and shapes. You can leave away the primitive.
In that case, GLVisualize will fill in some default that is anticipated to make
the most sense for the datatype.
=#

#3D primitives
const Primitives3D = Union{AbstractGeometry{3}, AbstractMesh}
#2D primitives AKA sprites, since they are shapes mapped onto a 2D rectangle
const Sprites = Union{AbstractGeometry{2}, Shape, Char, Type}
const AllPrimitives = Union{AbstractGeometry, Shape, Char, AbstractMesh}

using AbstractPlotting: RectanglePacker

"""
We plot simple Geometric primitives as particles with length one.
At some point, this should all be appended to the same particle system to increase
performance.
"""
function _default(
        geometry::TOrSignal{G}, s::Style, data::Dict
    ) where G <: GeometryPrimitive{2}
    data[:offset] = Vec2f0(0)
    _default((geometry, const_lift(x-> Point2f0[minimum(x)], geometry)), s, data)
end

"""
Vectors of floats are treated as barplots, so they get a HyperRectangle as
default primitive.
"""
function _default(main::VectorTypes{T}, s::Style, data::Dict) where T <: AbstractFloat
    _default((centered(HyperRectangle{2, Float32}), main), s, data)
end
"""
Matrices of floats are represented as 3D barplots with cubes as primitive
"""
function _default(main::MatTypes{T}, s::Style, data::Dict) where T <: AbstractFloat
    _default((AABB(Vec3f0(-0.5,-0.5,0), Vec3f0(1.0)), main), s, data)
end
"""
Vectors of n-dimensional points get ndimensional rectangles as default
primitives. (Particles)
"""
function _default(main::VectorTypes{P}, s::Style, data::Dict) where P <: Point
    N = length(P)
    @gen_defaults! data begin
        scale = N == 2 ? Vec2f0(30) : Vec3f0(0.03) # for 2D points we assume they're in pixels
    end
    _default((centered(HyperRectangle{N, Float32}), main), s, data)
end

"""
3D matrices of vectors are 3D vector field with a pyramid (arrow) like default
primitive.
"""
function _default(main::ArrayTypes{T, 3}, s::Style, data::Dict) where T<:Vec
    _default((Pyramid(Point3f0(0, 0, -0.5), 1f0, 1f0), main), s, data)
end
"""
2D matrices of vectors are 2D vector field with a an unicode arrow as the default
primitive.
"""
function _default(main::ArrayTypes{T, 2}, s::Style, data::Dict) where T<:Vec
    _default(('⬆', main), s, data)
end

"""
Vectors with `Vec` as element type are treated as vectors of rotations.
The position is assumed to be implicitely on the grid the vector defines (1D,2D,3D grid)
"""
function _default(
        main::Tuple{P, ArrayTypes{T, N}}, s::Style, data::Dict
    ) where {P <: AllPrimitives, T <: Vec, N}
    primitive, rotation_s = main
    rotation_v = to_value(rotation_s)
    @gen_defaults! data begin
        color_norm = const_lift(extrema2f0, rotation_s)
        ranges = ntuple(i->LinRange(0f0, 1f0, size(rotation_v, i)), N)
    end
    grid = Grid(rotation_v, ranges)

    if N == 1
        scalevec = Vec2f0(step(grid.dims[1]), 1)
    elseif N == 2
        scalevec = Vec2f0(step(grid.dims[1]), step(grid.dims[2]))
    else
        scalevec = Vec3f0(ntuple(i->step(grid.dims[i]), 3)).*Vec3f0(0.4,0.4, 1/to_value(color_norm)[2]*4)
    end
    if P <: Char # we need to preserve proportion of the glyph
        scalevec = Vec2f0(glyph_scale!(primitive, scalevec[1]))
        @gen_defaults! data begin # for chars we need to make sure they're centered
            offset = -scalevec/2f0
        end
    end
    @gen_defaults! data begin
        rotation   = const_lift(vec, rotation_s)
        color_map  = default(Vector{RGBA})
        scale      = scalevec
        color      = nothing
    end
    _default((primitive, grid), s, data)
end

"""
arrays of floats with any geometry primitive, will be spaced out on a grid defined
by `ranges` and will use the floating points as the
height for the primitives (`scale_z`)
"""
function _default(
        main::Tuple{P, ArrayTypes{T,N}}, s::Style, data::Dict
    ) where {P<:AbstractGeometry, T<:AbstractFloat, N}
    primitive, heightfield_s = main
    heightfield = to_value(heightfield_s)
    @gen_defaults! data begin
        ranges = ntuple(i->LinRange(0f0, 1f0, size(heightfield, i)), N)
    end
    grid = Grid(heightfield, ranges)
    @gen_defaults! data begin
        scale = nothing
        scale_x::Float32 = step(grid.dims[1])
        scale_y::Float32 = N == 1 ? 1f0 : step(grid.dims[2])
        scale_z = const_lift(vec, heightfield_s)
        color = nothing
        color_map  = color == nothing ? default(Vector{RGBA}) : nothing
        color_norm = color == nothing ? const_lift(extrema2f0, heightfield_s) : nothing
    end
    _default((primitive, grid), s, data)
end

"""
arrays of floats with the sprite primitive type (2D geometry + picture like),
will be spaced out on a grid defined
by `ranges` and will use the floating points as the
z position for the primitives.
"""
function _default(
        main::Tuple{P, ArrayTypes{T,N}}, s::Style, data::Dict
    ) where {P <: Sprites, T <: AbstractFloat, N}
    primitive, heightfield_s = main
    heightfield = to_value(heightfield_s)
    @gen_defaults! data begin
        ranges = ntuple(i->LinRange(0f0, 1f0, size(heightfield, i)), N)
    end
    grid = Grid(heightfield, ranges)
    @gen_defaults! data begin
        position_z = const_lift(vec, heightfield_s)
        scale      = Vec2f0(step(grid.dims[1]), N>=2 ? step(grid.dims[2]) : 1f0)
        color_map  = default(Vector{RGBA})
        color      = nothing
        color_norm = const_lift(extrema2f0, heightfield_s)
    end
    _default((primitive, grid), s, data)
end

"""
Sprites primitives with a vector of floats are treated as something barplot like
"""
function _default(
        main::Tuple{P, VectorTypes{T}}, s::Style, data::Dict
    ) where {P <: AllPrimitives, T <: AbstractFloat}
    primitive, heightfield_s = main
    heightfield = to_value(heightfield_s)
    @gen_defaults! data begin
        ranges = range(0f0, stop = 1f0, length = length(heightfield))
    end
    grid = Grid(heightfield, ranges)
    delete!(data, :ranges)
    @gen_defaults! data begin
        scale = nothing
        scale_x::Float32 = step(grid.dims[1])
        scale_y = heightfield_s
        scale_z::Float32 = 1f0
    end
    _default((primitive, grid), s, data)
end




# There is currently no way to get the two following two signatures
# under one function, which is why we delegate to meshparticle
function _default(
        p::Tuple{TOrSignal{Pr}, VectorTypes{P}}, s::Style, data::Dict
    ) where {Pr <: Primitives3D, P <: Point}
    meshparticle(p, s, data)
end

function _default(
        p::Tuple{TOrSignal{Pr}, G}, s::Style, data::Dict
    ) where {Pr <: Primitives3D, G <: Tuple}
    @gen_defaults! data begin
        primitive = p[1]
        position         = nothing => TextureBuffer
        position_x       = p[2][1] => TextureBuffer
        position_y       = p[2][2] => TextureBuffer
        position_z       = length(p[2]) > 2 ? p[2][3] : 0f0 => TextureBuffer
        instances        = const_lift(length, position_x)
    end
    meshparticle(p, s, data)
end

function _default(
        p::Tuple{TOrSignal{Pr}, G}, s::Style, data::Dict
    ) where {Pr <: Primitives3D, G <: Grid}
    meshparticle(p, s, data)
end

# make conversion of mesh signals work. TODO move to GeometryTypes?
function Base.convert(::Type{T}, mesh::Node) where T<:GeometryTypes.HomogenousMesh
    lift(T, mesh)
end


function to_meshcolor(color::TOrSignal{Vector{T}}) where T <: Colorant
    TextureBuffer(color)
end

function to_meshcolor(color::TOrSignal{Matrix{T}}) where T <: Colorant
    Texture(color)
end
function to_meshcolor(color)
    color
end

function to_mesh(mesh::TOrSignal{<: GeometryPrimitive})
    gl_convert(const_lift(GLNormalMesh, mesh))
end

function to_mesh(mesh::TOrSignal{<: HomogenousMesh})
    gl_convert(to_value(mesh))
end

function orthogonal(v::T) where T <: StaticVector{3}
    x, y, z = abs.(v)
    other = x < y ? (x < z ? unit(T, 1) : unit(T, 3)) : (y < z ? unit(T, 2) : unit(T, 3))
    return cross(v, other)
end

using AbstractPlotting
using AbstractPlotting: get_texture_atlas


vec2quaternion(rotation::StaticVector{4}) = rotation

function vec2quaternion(r::StaticVector{2})
    vec2quaternion(Vec3f0(r[1], r[2], 0))
end
function vec2quaternion(rotation::StaticVector{3})
    AbstractPlotting.rotation_between(Vec3f0(0, 0, 1), Vec3f0(rotation))
end

vec2quaternion(rotation::Vec4f0) = rotation
vec2quaternion(rotation::VectorTypes) = const_lift(x-> vec2quaternion.(x), rotation)
vec2quaternion(rotation::Node) = lift(vec2quaternion, rotation)
vec2quaternion(rotation::AbstractPlotting.Quaternion)= Vec4f0(rotation.data)
GLAbstraction.gl_convert(rotation::AbstractPlotting.Quaternion)= Vec4f0(rotation.data)
"""
This is the main function to assemble particles with a GLNormalMesh as a primitive
"""
function meshparticle(p, s, data)
    rot = get!(data, :rotation, Vec4f0(0, 0, 0, 1))
    rot = vec2quaternion(rot)
    delete!(data, :rotation)
    @gen_defaults! data begin
        primitive = p[1] => to_mesh
        position = p[2] => TextureBuffer
        position_x = nothing => TextureBuffer
        position_y = nothing => TextureBuffer
        position_z = nothing => TextureBuffer

        scale = Vec3f0(1) => TextureBuffer
        scale_x = nothing => TextureBuffer
        scale_y = nothing => TextureBuffer
        scale_z = nothing => TextureBuffer

        rotation = rot => TextureBuffer
        texturecoordinates = nothing
        shading = true
    end

    @gen_defaults! data begin
        color_map  = nothing => Texture
        color_norm = nothing
        intensity  = nothing
        color      = if color_map == nothing
            default(RGBA{Float32}, s)
        else
            nothing
        end => to_meshcolor

        instances = const_lift(length, position)
        shading = true
        shader = GLVisualizeShader(
            "util.vert", "particles.vert", "fragment_output.frag", "standard.frag",
            view = Dict(
                "position_calc" => position_calc(position, position_x, position_y, position_z, TextureBuffer),
                "light_calc" => light_calc(shading)
            )
        )
    end
    if AbstractPlotting.to_value(intensity) != nothing
        if AbstractPlotting.to_value(position) != nothing
            data[:intensity] = intensity_convert_tex(intensity, position)
            data[:len] = const_lift(length, position)
        else
            data[:intensity] = intensity_convert_tex(intensity, position_x)
            data[:len] = const_lift(length, position_x)
        end
    end
    data
end

to_pointsize(x::Number) = Float32(x)
to_pointsize(x) = Float32(x[1])

struct PointSizeRender
    size::Observable
end
(x::PointSizeRender)() = glPointSize(to_pointsize(x.size[]))
"""
This is the most primitive particle system, which uses simple points as primitives.
This is supposed to be the fastest way of displaying particles!
"""
function _default(position::VectorTypes{T}, s::style"speed", data::Dict) where T <: Point
    @gen_defaults! data begin
        vertex       = position => GLBuffer
        color_map    = nothing  => Texture
        color        = (color_map == nothing ? default(RGBA{Float32}, s) : nothing) => GLBuffer
        color_norm   = nothing
        scale        = 2f0
        shader       = GLVisualizeShader("fragment_output.frag", "dots.vert", "dots.frag")
        gl_primitive = GL_POINTS
    end
    data[:prerender] = PointSizeRender(data[:scale])
    data
end

"""
returns the Shape for the distancefield algorithm
"""
primitive_shape(::Char) = DISTANCEFIELD
primitive_shape(x::X) where {X} = primitive_shape(X)
primitive_shape(::Type{T}) where {T <: Circle} = CIRCLE
primitive_shape(::Type{T}) where {T <: SimpleRectangle} = RECTANGLE
primitive_shape(::Type{T}) where {T <: HyperRectangle{2}} = RECTANGLE
primitive_shape(x::Shape) = x

"""
Extracts the scale from a primitive.
"""
primitive_scale(prim::GeometryPrimitive) = Vec2f0(widths(prim))
primitive_scale(::Union{Shape, Char}) = Vec2f0(40)
primitive_scale(c) = Vec2f0(0.1)

"""
Extracts the offset from a primitive.
"""
primitive_offset(x, scale::Nothing) = Vec2f0(0) # default offset
primitive_offset(x, scale) = const_lift(/, scale, -2f0)  # default offset


"""
Extracts the uv offset and width from a primitive.
"""
primitive_uv_offset_width(c::Char) = glyph_uv_width!(c)
primitive_uv_offset_width(x) = Vec4f0(0,0,1,1)

"""
Gets the texture atlas if primitive is a char.
"""
primitive_distancefield(x) = nothing
primitive_distancefield(::Char) = get_texture!(get_texture_atlas())
primitive_distancefield(::Node{Char}) = get_texture!(get_texture_atlas())

function _default(
        p::Tuple{TOrSignal{Matrix{C}}, VectorTypes{P}}, s::Style, data::Dict
    ) where {C <: Colorant, P <: Point}
    data[:image] = p[1] # we don't want this to be overwritten by user
    @gen_defaults! data begin
        scale = lift(x-> Vec2f0(size(x)), p[1])
        shape = RECTANGLE
        offset = Vec2f0(0)
    end
    sprites(p, s, data)
end
function _default(
        p::Tuple{TOrSignal{Matrix{C}}, VectorTypes{P}}, s::Style, data::Dict
    ) where {C <: AbstractFloat, P <: Point}
    data[:distancefield] = p[1] # we don't want this to be overwritten by user
    @gen_defaults! data begin
        scale = lift(x-> Vec2f0(size(x)), p[1])
        shape = RECTANGLE
        offset = Vec2f0(0)
    end
    sprites(p, s, data)
end

function _default(
        p::Tuple{VectorTypes{Matrix{C}}, VectorTypes{P}}, s::Style, data::Dict
    ) where {C <: Colorant, P <: Point}
    images = to_value(p[1])
    isempty(images) && error("Can not display empty vector of images as primitive")
    sizes = map(size, images)
    if !all(x-> x == sizes[1], sizes) # if differently sized
        # create texture atlas
        maxdims = sum(map(Vec{2, Int}, sizes))
        rectangles = map(x->SimpleRectangle(0, 0, x...), sizes)
        rpack = RectanglePacker(SimpleRectangle(0, 0, maxdims...))
        uv_coordinates = [push!(rpack, rect).area for rect in rectangles]
        max_xy = maximum(maximum.(uv_coordinates))
        texture_atlas = Texture(C, (max_xy...,))
        for (area, img) in zip(uv_coordinates, images)
            texture_atlas[area] = img #transfer to texture atlas
        end
        data[:uv_offset_width] = map(uv_coordinates) do uv
            m = max_xy .- 1
            mini = reverse((minimum(uv)) ./ m)
            maxi = reverse((maximum(uv) .- 1) ./ m)
            return Vec4f0(mini..., maxi...)
        end
        images = texture_atlas
    end
    data[:image] = images # we don't want this to be overwritten by user
    @gen_defaults! data begin
        shape = RECTANGLE
        offset = Vec2f0(0)
    end
    sprites(p, s, data)
end

# There is currently no way to get the two following two signatures
# under one function, which is why we delegate to sprites
_default(p::Tuple{TOrSignal{Pr}, VectorTypes{P}}, s::Style, data::Dict) where {Pr <: Sprites, P<:Point} =
    sprites(p,s,data)

_default(p::Tuple{TOrSignal{Pr}, G}, s::Style, data::Dict) where {Pr <: Sprites, G<:Grid} =
    sprites(p,s,data)

function _default(
            p::Tuple{TOrSignal{Pr}, G}, s::Style, data::Dict
        ) where {Pr <: Sprites, G <: Tuple}
    @gen_defaults! data begin
        shape      = const_lift(primitive_shape, p[1])
        position   = nothing => GLBuffer
        position_x = p[2][1] => GLBuffer
        position_y = p[2][2] => GLBuffer
        position_z = length(p[2]) > 2 ? p[2][3] : 0f0 => GLBuffer
    end
    sprites(p, s, data)
end


function correct_scale(char, scale)
    Vec2f0(glyph_scale!(char, scale))
end
function correct_scale(char, scale::AbstractVector)
    Vec2f0(glyph_scale!.(char, scale))
end
"""
Main assemble functions for sprite particles.
Sprites are anything like distance fields, images and simple geometries
"""
function sprites(p, s, data)
    rot = get!(data, :rotation, Vec4f0(0, 0, 0, 1))
    rot = vec2quaternion(rot)
    delete!(data, :rotation)

    @gen_defaults! data begin
        shape       = const_lift(x-> Int32(primitive_shape(x)), p[1])
        position    = p[2]    => GLBuffer
        position_x  = nothing => GLBuffer
        position_y  = nothing => GLBuffer
        position_z  = nothing => GLBuffer

        scale       = const_lift(primitive_scale, p[1]) => GLBuffer
        scale_x     = nothing => GLBuffer
        scale_y     = nothing => GLBuffer
        scale_z     = nothing => GLBuffer

        rotation    = rot => GLBuffer
        image       = nothing => Texture
    end
    # TODO don't make this dependant on some shady type dispatch
    if isa(to_value(p[1]), Char) && !isa(to_value(scale), Union{StaticVector, AbstractVector{<: StaticVector}}) # correct dimensions
        data[:scale] = const_lift(correct_scale, p[1], scale)
    end

    @gen_defaults! data begin
        offset          = primitive_offset(p[1], scale) => GLBuffer
        intensity       = nothing => GLBuffer
        color_map       = nothing => Texture
        color_norm      = nothing
        color           = (color_map == nothing ? default(RGBA, s) : nothing) => GLBuffer

        glow_color      = RGBA{Float32}(0,0,0,0) => GLBuffer
        stroke_color    = RGBA{Float32}(0,0,0,0) => GLBuffer
        stroke_width    = 0f0
        glow_width      = 0f0
        uv_offset_width = const_lift(primitive_uv_offset_width, p[1]) => GLBuffer

        distancefield   = primitive_distancefield(p[1]) => Texture
        indices         = const_lift(length, p[2]) => to_index_buffer
        # rotation and billboard don't go along
        billboard        = rotation == Vec4f0(0,0,0,1) => "if `billboard` == true, particles will always face camera"
        preferred_camera = :orthographic_pixel
        fxaa             = false
        shader           = GLVisualizeShader(
            "fragment_output.frag", "util.vert", "sprites.geom",
            "sprites.vert", "distance_shape.frag",
            view = Dict("position_calc"=>position_calc(position, position_x, position_y, position_z, GLBuffer))
        )
        gl_primitive = GL_POINTS
    end
    # Exception for intensity, to make it possible to handle intensity with a
    # different length compared to position. Intensities will be interpolated in that case
    if position != nothing
        data[:intensity] = intensity_convert(intensity, position)
        data[:len] = const_lift(length, position)
    else
        data[:intensity] = intensity_convert(intensity, position_x)
        data[:len] = const_lift(length, position_x)
    end
    data
end


"""
Transforms text into a particle system of sprites, by inferring the
texture coordinates in the texture atlas, widths and positions of the characters.
"""
function _default(main::Tuple{TOrSignal{S}, P}, s::Style, data::Dict) where {S <: AbstractString, P}
    data[:position] = main[2]
    _default(main[1], s, data)
end



function _default(main::TOrSignal{S}, s::Style, data::Dict) where S <: AbstractString
    @gen_defaults! data begin
        relative_scale  = 4 #
        start_position  = Point2f0(0)
        atlas           = get_texture_atlas()
        distancefield   = get_texture!(atlas)
        stroke_width    = 0f0
        glow_width      = 0f0
        font            = to_font("default")
        scale_primitive = true
        position        = const_lift(calc_position, main, start_position, relative_scale, font, atlas)
        offset          = const_lift(calc_offset, main, relative_scale, font, atlas)
        prerender       = () -> begin
            glDisable(GL_DEPTH_TEST)
            glDepthMask(GL_TRUE)
            glDisable(GL_CULL_FACE)
            enabletransparency()
        end
        uv_offset_width = const_lift(main) do str
            Vec4f0[glyph_uv_width!(atlas, c, font) for c = str]
        end
        scale = const_lift(main, relative_scale) do str, s
            Vec2f0[glyph_scale!(atlas, c, font, s) for c = str]
        end
    end
    delete!(data, :font)
    _default((DISTANCEFIELD, position), s, data)
end
