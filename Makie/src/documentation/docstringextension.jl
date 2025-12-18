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
