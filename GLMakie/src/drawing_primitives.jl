using Makie: transform_func_obs, apply_transform
using Makie: attribute_per_char, FastPixel, el32convert, Pixel
using Makie: convert_arguments
using Makie: apply_transform_and_f32_conversion, f32_conversion_obs

Makie.el32convert(x::GLAbstraction.Texture) = x

function Base.insert!(screen::Screen, scene::Scene, @nospecialize(x::Plot))
    # Note: Calling pollevents() here will allow `on(events(scene)...)` to take
    #       action while a plot is getting created. If the plot is deleted at
    #       that point the robj will get orphaned.
    ShaderAbstractions.switch_context!(screen.glscreen)
    add_scene!(screen, scene)
    # poll inside functions to make wait on compile less prominent
    if isempty(x.plots) # if no plots inserted, this truly is an atomic
        draw_atomic(screen, scene, x)
    else
        foreach(x.plots) do x
            # poll inside functions to make wait on compile less prominent
            insert!(screen, scene, x)
        end
    end
end