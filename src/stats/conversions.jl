struct SampleBased <: ConversionTrait end

function convert_arguments(::SampleBased, args::NTuple{N,AbstractVector{<:Number}}) where {N}
    return args
end

function convert_arguments(P::SampleBased, positions::Vararg{AbstractVector})
    return convert_arguments(P, positions)
end

function convert_arguments(::SampleBased, positions::NTuple{N,AbstractVector}) where {N}
    x = first(positions)
    if any(n-> length(x) != length(n), positions)
        error("all vector need to be same length. Found: $(length.(positions))")
    end
    labels = categoric_labels.(positions)
    xyrange = categoric_range.(labels)
    newpos = map(positions, labels) do pos,lab
        el32convert(categoric_position.(pos, Ref(lab)))
    end
    PlotSpec(newpos...; tickranges = xyrange, ticklabels = labels)
end