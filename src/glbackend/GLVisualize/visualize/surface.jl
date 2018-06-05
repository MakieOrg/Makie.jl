
function surfboundingbox(position_x, position_y, position_z)
    arr = const_lift(StructOfArrays, Point3f0, position_x, position_y, position_z)
    map(AABB{Float32}, arr)
end
function surfboundingbox(grid, position_z)
    arr = const_lift(GridZRepeat, grid, position_z)
    map(AABB{Float32}, arr)
end

function _default(main::Tuple{MatTypes{T}, MatTypes{T}, MatTypes{T}}, s::Style{:surface}, data::Dict) where T <: AbstractFloat
    @gen_defaults! data begin
        position_x = main[1] => (Texture, "x position, must be an `Matrix{Float}`")
        position_y = main[2] => (Texture, "y position, must be an `Matrix{Float}`")
        position_z = main[3] => (Texture, "z position, must be an `Matrix{Float}`")
        scale = Vec3f0(0) => "scale must be 0, for a surfacemesh"
    end
    surface(position_z, s, data)
end

function _default(main::MatTypes{T}, s::Style{:surface}, data::Dict) where T <: AbstractFloat
    @gen_defaults! data begin
        ranges = ((-1f0, 1f0), (-1f0,1f0)) => "x, and y position given as `(start, endvalue)` or any `Range`"
    end
    delete!(data, :ranges) # no need to have them in the OpenGL data
    _default((Grid(value(main), value(ranges)), main), s, data)
end

function _default(main::Tuple{G, MatTypes{T}}, s::Style{:surface}, data::Dict) where {G <: Grid{2}, T <: AbstractFloat}
    xrange = main[1].dims[1];yrange = main[1].dims[2]
    xscale = (maximum(xrange) - minimum(xrange)) / (length(xrange)-1)
    yscale = (maximum(yrange) - minimum(yrange)) / (length(yrange)-1)
    @gen_defaults! data begin
        position    = main[1] =>" Position given as a `Grid{2}`.
        Can be constructed e.g. `Grid(linspace(0,2,N1), linspace(0,3, N2))`"
        position_z  = main[2] => (Texture, "height offset for the surface, must be `Matrix{Float}`")
        scale       = Vec3f0(xscale, yscale, 1) => "scale of the grid planes forming the surface. Can be made smaller, to let the grid show"
    end
    surface(position_z, s, data)
end
_extrema(x::AABB) = Vec2f0(minimum(x)[3], maximum(x)[3])
nothing_or_vec(x) = x
nothing_or_vec(x::Array) = vec(x)

function normal_calc(x::Bool)
    if x
        "getnormal(position_z, linear_index(dims, index1D));"
    else
        "vec3(0, 0, 1);"
    end
end
function light_calc(x::Bool)
    if x
        """
        vec3 L      = normalize(o_lightdir);
        vec3 N      = normalize(o_normal);
        vec3 light1 = blinnphong(N, o_vertex, L, color.rgb);
        vec3 light2 = blinnphong(N, o_vertex, -L, color.rgb);
        color       = vec4(light1 + light2 * 0.4, color.a);
        """
    else
        ""
    end
end

function surface(main, s::Style{:surface}, data::Dict)
    @gen_defaults! data begin
        primitive::GLMesh2D = SimpleRectangle(0f0,0f0,1f0,1f0)
        scale       = nothing
        position    = nothing
        position_x  = nothing => Texture
        position_y  = nothing => Texture
        position_z  = nothing => Texture
        wireframe   = false
        glow_color       = RGBA{Float32}(0,0,0,0) => GLBuffer
        stroke_color     = RGBA{Float32}(0,0,0,1) => GLBuffer
        stroke_width     = wireframe ? 0.03f0 : 0f0
        glow_width       = 0f0
        uv_offset_width  = Vec4f0(0) => GLBuffer
        shape            = RECTANGLE
        wireframe        = false
        image            = nothing => Texture
        distancefield    = nothing => Texture
        shading          = true
        normal           = shading
    end
    @gen_defaults! data begin
        color      = (wireframe ? RGBA{Float32}(0,0,0,0) : nothing) => (Texture,
            "must be single color value, must be nothing for color_map")
        color_map  = (!wireframe && color == nothing ? default(Vector{RGBA}, s) : nothing) => (Texture,
        "must be `Vector{Color}`, `color` must be nothing")
        color_norm = (!wireframe && color_map != nothing ? const_lift(_extrema, boundingbox) : nothing) => begin
            "normalizes the heightvalues before looking up color in `color_map`."
        end
        instances  = const_lift(x->(size(x,1)-1) * (size(x,2)-1), main) => "number of planes used to render the surface"
        shader     = GLVisualizeShader(
            "fragment_output.frag", "util.vert", "surface.vert",
            value(wireframe) ? "distance_shape.frag" : "standard.frag",
            view = Dict(
                "position_calc" => position_calc(position, position_x, position_y, position_z, Texture),
                "normal_calc" => normal_calc(normal),
                "light_calc" => light_calc(shading),
            )
        )
    end
end


function position_calc(x...)
    _position_calc(Iterators.filter(x->!isa(x, Void), x)...)
end
function glsllinspace(position::Grid, gi, index)
    "position.ref[$gi] + ($index - position.offset[$gi]) * position._step[$gi]"
end
function glsllinspace(grid::Grid{1}, gi, index)
    "position.ref + ($index - position.offset) * position._step"
end
function grid_pos(grid::Grid{1})
    "$(glsllinspace(grid, 0, "index"))"
end
function grid_pos(grid::Grid{2})
    "vec2($(glsllinspace(grid, 0, "index2D.x")), $(glsllinspace(grid, 1, "index2D.y")))"
end
function grid_pos(grid::Grid{3})
    "vec3(
        $(glsllinspace(grid, 0, "index2D.x")),
        $(glsllinspace(grid, 1, "index2D.y")),
        $(glsllinspace(grid, 2, "index2D.z"))
    )"
end


function _position_calc(
        grid::Grid{2}, position_z::MatTypes{T}, target::Type{Texture}
    ) where T<:AbstractFloat
    """

    int index1D = index + offseti.x + offseti.y * position.dims.x + (index/(position.dims.x-1));
    ivec2 index2D = ind2sub(position.dims, index1D);
    float height = texelFetch(position_z, index2D, 0).x;
    pos = vec3($(grid_pos(grid)), height);
    """
end

function _position_calc(
        position_x::MatTypes{T}, position_y::MatTypes{T}, position_z::MatTypes{T}, target::Type{Texture}
    ) where T<:AbstractFloat
"""
    int index1D = index + offseti.x + offseti.y * dims.x + (index/(dims.x-1));
    ivec2 index2D = ind2sub(dims, index1D);
    pos = vec3(
        texelFetch(position_x, index2D, 0).x,
        texelFetch(position_y, index2D, 0).x,
        texelFetch(position_z, index2D, 0).x
    );
"""
end

function _position_calc(
        position_x::VecTypes{T}, position_y::T, position_z::T, target::Type{TextureBuffer}
    ) where T <: AbstractFloat
    "pos = vec3(texelFetch(position_x, index).x, position_y, position_z);"
end
function _position_calc(
        position_x::VecTypes{T}, position_y::T, position_z::T, target::Type{GLBuffer}
    ) where T <: AbstractFloat
    "pos = vec3(position_x, position_y, position_z);"
end
function _position_calc(
        position_xyz::VecTypes{T}, target::Type{TextureBuffer}
    ) where T <: StaticVector
    "pos = texelFetch(position, index).xyz;"
end
function _position_calc(
        position_xyz::VecTypes{T}, target::Type{GLBuffer}
    ) where T <: StaticVector
    len = length(T)
    filler = join(ntuple(x->0, 3-len), ", ")
    needs_comma = len != 3 ? ", " : ""
    "pos = vec3(position $needs_comma $filler);"
end
function _position_calc(
        position_x::VecTypes{T}, position_y::VecTypes{T}, position_z::VecTypes{T},
        target::Type{TextureBuffer}
    ) where T<:AbstractFloat
    "pos = vec3(
        texelFetch(position_x, index).x,
        texelFetch(position_y, index).x,
        texelFetch(position_z, index).x
    );"
end
function _position_calc(
        position_x::VecTypes{T}, position_y::VecTypes{T}, position_z::VecTypes{T},
        target::Type{GLBuffer}
    ) where T<:AbstractFloat
    "pos = vec3(
        position_x,
        position_y,
        position_z
    );"
end
function _position_calc(
        position::Grid{1}, target
    )
    "
    pos = vec3($(grid_pos(position)), 0, 0);
    "
end
function _position_calc(
        position::Grid{2}, target
    )
    "
    ivec2 index2D = ind2sub(position.dims, index);
    pos = vec3($(grid_pos(position)), 0);
    "
end
function _position_calc(
        position::Grid{2}, ::VecTypes{T}, target::Type{GLBuffer}
    ) where T
    "
    ivec2 index2D = ind2sub(position.dims, index);
    pos = vec3($(grid_pos(position)), position_z);
    "
end
function _position_calc(
        position::Grid{3}, target
    )
    "
    ivec3 index2D = ind2sub(position.dims, index);
    pos = $(grid_pos(position));
    "
end
