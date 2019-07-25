################################################################################
#                              DocStringExtension                              #
################################################################################

struct DocThemer <: DocStringExtensions.Abbreviation end

const ATTRIBUTES = DocThemer()

function DocStringExtensions.format(::DocThemer, buf, doc)
	local binding = doc.data[:binding] |> Docs.resolve
	help_attributes(buf, binding; extended=true)
end
