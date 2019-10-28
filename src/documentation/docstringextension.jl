################################################################################
#                              DocStringExtension                              #
################################################################################

############################################################
#                        Attributes                        #
############################################################

struct DocThemer <: DocStringExtensions.Abbreviation end

const ATTRIBUTES = DocThemer()

function DocStringExtensions.format(::DocThemer, buf, doc)
	local binding = doc.data[:binding] |> Docs.resolve
	help_attributes(buf, binding; extended=true)
end

############################################################
#                        Instances                         #
############################################################

struct DocInstances <: DocStringExtensions.Abbreviation end

const INSTANCES = DocInstances()

function DocStringExtensions.format(::DocInstances, buf, doc)
	local binding = doc.data[:binding] |> Docs.resolve

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
	show(buf, Markdown.MD(Markdown.Table(rows, [:l, :l])))
end

# """
# A lolly instead of a lol!
#
# $(INSTANCES)
# """
# @enum Lolly Pop Bang Snap Crackle Jerk
#
# @doc Lolly
# A lolly instead of a lol!
#
# Instance Value
# –––––––– –––––
# Pop      0
# Bang     1
# Snap     2
# Crackle  3
# Jerk     4
