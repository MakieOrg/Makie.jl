module MakieClusteringExt

import Makie as M
import Clustering as C

function M.convert_arguments(::Type{<:M.Dendrogram}, hcl::C.Hclust; useheight = false)
    nodes = M.hcl_nodes(hcl; useheight = useheight)
    return (nodes,)
end

end # module
