# Extending MakiE

There are 3 ways to extend MakiE:

1) By creating a new function e.g. like scatter
2) By overloading plot(...) for your own type
3) By adding a new primitive + shader

## Option 1

The first option is quite trivial and can be done in any plotting package and language:
just create a function that scripts together a Plot.

## Option 2

Option 2 is very similar to Plots.jl recipes.
Inside the function you can just use all of the plotting and drawing API to create
a rich visual representation of your type.
The signature that needs overloading is:

```julia
function plot(obj::MyType, kw_args::Dict)
    # use primitives and other recipes to create a new plot
    scatter(obj, kw_arg[:my_attribute])
    lines(...)
    polygon(...)
end
```

## Option 3

Option 3 is pretty unique and is a real extension of MakiE's functionality as it
adds a new primitive drawing type.
This interface will likely change a lot in the future, since it carries quite a lot of
technical debt from the design of GLAbstraction + GLVisualize, but this is how you can do it right now:

You will need to create defaults for the attributes of your new visual.
For a documentation on how to use this macro look at [`@default(func_expr)`](@ref).

```julia

my_attribute_convert(A::Array) = Texture(A)
my_attribute_convert(A::Texture) = A
my_attribute_convert(A) = error("A needs to be an array or Texture. Found: $(typeof(A))")

@default function my_drawing_type(scene, kw_args)
    my_attribute = my_attribute_convert(my_attribute)
    another_attribute = another_attribute::Float32 # always gets converted to Float32
end

function my_drawing_type(main_object::MyType, kw_args::Dict)
    # optionally expand keyword arguments. E.g. m = (1, :white) becomes markersize = 1, markercolor = :white
    kw_args = expand_kwargs(kw_args)
    scene = get_global_scene()
    kw_args = my_drawing_type(scene, kw_args) # fill in and convert attributes

    boundingbox = Signal(AABB(Vec3f0(0), Vec3f0(1))) # calculate a boundingbox from your data

    primitive = GL_TRIANGLES

    vsh = vert"""
        {{GLSL_VERSION}}
        in vec2 position;
        void main(){
            gl_Position = vec4(position, 0, 1.0);
        }
    """

    fsh = frag"""
        {{GLSL_VERSION}}
        out vec4 outColor;
        void main() {
            outColor = vec4(1.0, 1.0, 1.0, 1.0);
        }
    """
    program = LazyShader(vsh, fsh)
    robj = std_renderobject(shader_uniforms, program, boundingbox, primitive, nothing)
    # The attributes that you add to the scene should be all signals and all editable.
    # if an attribute is fixed, don't add it to the scene
    insert_scene!(scene, :scatter, viz, attributes)
    attributes
end

```
