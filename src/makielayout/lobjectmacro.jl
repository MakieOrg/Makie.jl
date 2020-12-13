macro Layoutable(name::Symbol, fields::Expr = Expr(:block))

   structdef = quote
        mutable struct $name
            parent::Union{Figure, Scene}
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
    
    quote
        $structdef

        function _parentscene(x::$name)
            if x.parent isa Figure
                x.parent.scene
            else
                x.parent
            end
        end
    end
end

