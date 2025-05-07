function handle_color_getter!(uniform_dict)
    vertex_color = uniform_dict[:vertex_color]
    if vertex_color isa AbstractArray{<:Real}
        uniform_dict[:vertex_color_getter] = """
            vec4 get_vertex_color(){
                vec2 norm = get_uniform_colorrange();
                float cmin = norm.x;
                float cmax = norm.y;
                float value = vertex_color;
                if (value <= cmax && value >= cmin) {
                    // in value range, continue!
                } else if (value < cmin) {
                    return get_lowclip_color();
                } else if (value > cmax) {
                    return get_highclip_color();
                } else {
                    // isnan is broken (of course) -.-
                    // so if outside value range and not smaller/bigger min/max we assume NaN
                    return get_nan_color();
                }
                float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
                // 1/0 corresponds to the corner of the colormap, so to properly interpolate
                // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
                float stepsize = 1.0 / float(textureSize(uniform_colormap, 0));
                i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
                return texture(uniform_colormap, vec2(i01, 0.0));
            }
        """
    end
    return
end

using Makie: to_spritemarker


"""
    NoDataTextureAtlas(texture_atlas_size)

Optimization to just send the texture atlas one time to JS and then look it up from there in wglmakie.js,
instead of uploading this texture 10x in every plot.
"""
struct NoDataTextureAtlas <: ShaderAbstractions.AbstractSampler{Float16, 2}
    dims::NTuple{2, Int}
end
Base.size(x::NoDataTextureAtlas) = x.dims
Base.show(io::IO, ::NoDataTextureAtlas) = print(io, "NoDataTextureAtlas()")

function serialize_three(fta::NoDataTextureAtlas)
    tex = Dict(
        :type => "Sampler", :data => "texture_atlas",
        :size => [fta.dims...], :three_format => three_format(Float16),
        :three_type => three_type(Float16),
        :minFilter => three_filter(:linear),
        :magFilter => three_filter(:linear),
        :wrapS => "RepeatWrapping",
        :anisotropy => 16f0
    )
    tex[:wrapT] = "RepeatWrapping"
    return tex
end
