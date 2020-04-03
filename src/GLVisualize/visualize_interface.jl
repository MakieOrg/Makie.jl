function default(@nospecialize(main), @nospecialize(s), @nospecialize(data))
    data = _default(main, s, copy(data))
    @gen_defaults! data begin # make sure every object has these!
        model = Mat4f0(I)
        preferred_camera = :perspective
        is_transparent_pass = Cint(false)
        ambient = Vec3f0(0.55)
        diffuse = Vec3f0(0.4)
        specular = Vec3f0(0.2)
        shininess = 32f0
    end
end

"""
Creates a default visualization for any value.
The defaults can be customized via the key word arguments and the style parameter.
The style can change the the look completely (e.g points displayed as lines, or particles),
while the key word arguments just alter the parameters of one visualization.
Always returns a context, which can be displayed on a window via view(::Context, [display]).
"""
visualize(@nospecialize(main), s::Symbol=:default; kw_args...) = visualize(main, Style{s}(), Dict{Symbol, Any}(kw_args))
visualize(@nospecialize(main), s::Style, data::Dict) = assemble_shader(default(main, s, data))
