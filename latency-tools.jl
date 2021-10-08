#
ctnodes = typeof(tinf)[]
SnoopCompileCore.InferenceTimingNode[]

function checkchildren!(out, node)
       for child in node.children
           m = Method(child)
           if m.module === ColorTypes
               push!(out, child)
           else
               checkchildren!(out, child)
           end
       end
       return out
   end
checkchildren!(ctnodes, tinf);
sort!(ctnodes; by=inclusive)
