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

"""
Get the scene which layoutables need from their parent to plot stuff into
"""
get_topscene(f::Figure) = f.scene
function get_topscene(s::Scene)
    if !(s.camera_controls[] isa AbstractPlotting.PixelCamera)
        error("Can only use scenes with PixelCamera as topscene")
    end
    s
end