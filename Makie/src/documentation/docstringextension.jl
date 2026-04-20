################################################################################
#                              DocStringExtension                              #
################################################################################

############################################################
#                        Attributes                        #
############################################################

# This only exists for Axis3D/axis3d!() (aka OldAxis) now...

struct DocThemer <: DocStringExtensions.Abbreviation end

const ATTRIBUTES = DocThemer()

function DocStringExtensions.format(::DocThemer, buf, doc)
    binding = doc.data[:binding] |> Docs.resolve
    return help_attributes(buf, binding; extended = true)
end

############################################################
#                        Instances                         #
############################################################

# This allows you to add `$INSTANCES` in a docstring of an enum to splice in
# a table of the enum names and values

struct DocInstances <: DocStringExtensions.Abbreviation end

const INSTANCES = DocInstances()

function DocStringExtensions.format(::DocInstances, buf, doc)
    binding = Docs.resolve(doc.data[:binding])

    # @assert binding isa Enum "Binding $binding must be an `Enum`!"

    insts = instances(binding) # get the instances of the enum

    # initialize a vector of rows for the table
    rows = Vector{Vector{String}}(undef, length(insts) + 1)

    rows[1] = ["Instance", "Value"] # set the header

    # iterate through the instances and create a row for each
    for (i, inst) in enumerate(insts)
        rows[i + 1] = ["`$(inst)`", "`$(Int(inst))`"]
    end

    # print the Markdown table into the buffer
    return show(buf, Markdown.MD(Markdown.Table(rows, [:l, :l])))
end

################################################################################

# compat for old @recipe style

function help_attributes(io::IO, func::Function; extended = false)
    return help_attributes(io, to_plot_type(func); extended = extended)
end

"""
    print_rec(io::IO, dict, indent::Int = 1[; extended = false])

Traverses a dictionary `dict` and recursively print out its keys and values
in a nicely-indented format.

Use the optional `extended = true` keyword argument to see more details.
"""
function print_rec(io::IO, dict, indent::Int = 1; extended = false)
    for (k, v) in dict
        print(io, " "^(indent * 4), k)
        if isa(to_value(v), Makie.Attributes)
            print(io, ": ")
            println(io)
            print_rec(io, v.attributes, indent + 1; extended = extended)
        elseif isa(v, Observable)
            if extended
                print(io, ": ")
                println(io, isnothing(to_value(v)) ? "nothing" : to_value(v))
            else
                println(io)
            end
        else
            println(io, v)
        end
    end
    return
end
