abstract type Layoutable end

macro Layoutable(name::Symbol, fields::Expr = Expr(:block))

   structdef = quote
        mutable struct $name <: Layoutable
            parent::Union{Figure, Scene, Nothing}
            layoutobservables::LayoutObservables
            attributes::Attributes
            elements::Dict{Symbol, Any}
        end
    end

    if !(fields.head == :block)
        error("Fields need to be within a begin end block")
    end

    # append user defined fields to struct definition
    # linenumbernode block, struct block, fields block
    append!(structdef.args[2].args[3].args, fields.args)
    
    structdef
end

get_scene(f::Figure) = f.scene
get_scene(s::Scene) = s