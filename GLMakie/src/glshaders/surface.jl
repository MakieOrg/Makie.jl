
function position_calc(x...)
    _position_calc(Iterators.filter(x->!isa(x, Nothing), x)...)
end

function normal_calc(x::Bool, invert_normals::Bool = false)
    i = invert_normals ? "-" : ""
    if x
        return "$(i)getnormal(position, position_x, position_y, position_z, index2D);"
    else
        return "vec3(0, 0, $(i)1);"
    end
end

function light_calc(x::Bool)
    if x
        """
        vec3 L      = normalize(o_lightdir);
        vec3 N      = normalize(o_normal);
        vec3 light1 = blinnphong(N, o_camdir, L, color.rgb);
        vec3 light2 = blinnphong(N, o_camdir, -L, color.rgb);
        color       = vec4(ambient * color.rgb + light1 + backlight * light2, color.a);
        """
    else
        ""
    end
end

function _position_calc(
        position_x::MatTypes{T}, position_y::MatTypes{T}, position_z::MatTypes{T}, target::Type{Texture}
    ) where T<:AbstractFloat
    """
    int index1D = index + offseti.x + offseti.y * dims.x + (index/(dims.x-1));
    ivec2 index2D = ind2sub(dims, index1D);
    vec2 index01 = vec2(index2D) / (vec2(dims)-1.0);
    pos = vec3(
        texelFetch(position_x, index2D, 0).x,
        texelFetch(position_y, index2D, 0).x,
        texelFetch(position_z, index2D, 0).x
    );
    """
end

function _position_calc(
        position_x::VectorTypes{T}, position_y::VectorTypes{T}, position_z::MatTypes{T},
        target::Type{Texture}
    ) where T<:AbstractFloat
    """
    int index1D = index + offseti.x + offseti.y * dims.x + (index/(dims.x-1));
    ivec2 index2D = ind2sub(dims, index1D);
    vec2 index01 = vec2(index2D) / (vec2(dims)-1.0);
    pos = vec3(
        texelFetch(position_x, index2D.x, 0).x,
        texelFetch(position_y, index2D.y, 0).x,
        texelFetch(position_z, index2D, 0).x
    );
    """
end

function _position_calc(
        position_xyz::VectorTypes{T}, target::Type{TextureBuffer}
    ) where T <: StaticVector
    "pos = texelFetch(position, index).xyz;"
end

function _position_calc(
        position_xyz::VectorTypes{T}, target::Type{GLBuffer}
    ) where T <: StaticVector
    len = length(T)
    filler = join(ntuple(x->0, 3-len), ", ")
    needs_comma = len != 3 ? ", " : ""
    "pos = vec3(position $needs_comma $filler);"
end

function _position_calc(
        grid::Grid{2}, position_z::MatTypes{T}, target::Type{Texture}
    ) where T<:AbstractFloat
    """
    int index1D = index + offseti.x + offseti.y * dims.x + (index/(dims.x-1));
    ivec2 index2D = ind2sub(dims, index1D);
    vec2 index01 = vec2(index2D) / (vec2(dims)-1.0);
    float height = texture(position_z, index01).x;
    pos = vec3(grid_pos(position, index01), height);
    """
end

@nospecialize
# surface(::Matrix, ::Matrix, ::Matrix)
function draw_surface(screen, main::Tuple{MatTypes{T}, MatTypes{T}, MatTypes{T}}, data::Dict) where T <: AbstractFloat
    @gen_defaults! data begin
        position_x = main[1] => (Texture, "x position, must be a `Matrix{Float}`")
        position_y = main[2] => (Texture, "y position, must be a `Matrix{Float}`")
        position_z = main[3] => (Texture, "z position, must be a `Matrix{Float}`")
        scale = Vec3f(0) => "scale must be 0, for a surfacemesh"
    end
    return draw_surface(screen, position_z, data)
end

# surface(Vector or Range, Vector or Range, ::Matrix)
function draw_surface(screen, main::Tuple{VectorTypes{T}, VectorTypes{T}, MatTypes{T}}, data::Dict) where T <: AbstractFloat
    @gen_defaults! data begin
        position_x = main[1] => (Texture, "x position, must be a `Vector{Float}`")
        position_y = main[2] => (Texture, "y position, must be a `Vector{Float}`")
        position_z = main[3] => (Texture, "z position, must be a `Matrix{Float}`")
        scale = Vec3f(0) => "scale must be 0, for a surfacemesh"
    end
    return draw_surface(screen, position_z, data)
end

function draw_surface(screen, main, data::Dict)
    primitive = triangle_mesh(Rect2(0f0,0f0,1f0,1f0))
    to_opengl_mesh!(data, primitive)
    @gen_defaults! data begin
        scale = nothing
        position = nothing
        position_x = nothing => Texture
        position_y = nothing => Texture
        position_z = nothing => Texture
        image = nothing => Texture
        shading = true
        normal = shading
        invert_normals = false
        backlight = 0f0
    end
    @gen_defaults! data begin
        color = nothing => Texture
        color_map = nothing => Texture
        color_norm = nothing
        fetch_pixel = false
        matcap = nothing => Texture

        nan_color = RGBAf(1, 0, 0, 1)
        highclip = RGBAf(0, 0, 0, 0)
        lowclip = RGBAf(0, 0, 0, 0)

        uv_scale = Vec2f(1)
        instances = const_lift(x->(size(x,1)-1) * (size(x,2)-1), main) => "number of planes used to render the surface"
        transparency = false
        shader = GLVisualizeShader(
            screen,
            "fragment_output.frag", "util.vert", "surface.vert",
            "mesh.frag",
            view = Dict(
                "position_calc" => position_calc(position, position_x, position_y, position_z, Texture),
                "normal_calc" => normal_calc(normal, to_value(invert_normals)),
                "light_calc" => light_calc(shading),
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
    end
    return assemble_shader(data)
end
@specialize
