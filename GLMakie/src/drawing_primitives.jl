using Makie: transform_func_obs, apply_transform
using Makie: attribute_per_char, FastPixel, el32convert, Pixel
using Makie: convert_arguments
using Makie: apply_transform_and_f32_conversion, f32_conversion_obs

Makie.el32convert(x::GLAbstraction.Texture) = x

function Base.insert!(screen::Screen, scene::Scene, @nospecialize(x::Plot))
    gl_switch_context!(screen.glscreen)
    add_scene!(screen, scene)
    # poll inside functions to make wait on compile less prominent
    if isempty(x.plots) # if no plots inserted, this truly is an atomic
        draw_atomic(screen, scene, x)
    elseif x isa Text
        draw_atomic(screen, scene, x)
        insert!(screen, scene, x.plots[1])
    else
        foreach(x.plots) do x
            insert!(screen, scene, x)
        end
    end
end
