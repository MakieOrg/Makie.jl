function init(parent::SceneLike)
    for space in (:data, :transformed, :pixel, :relative, :clip) # TODO: use spaces() once it has :transformed
        bb.fast_bbox[space] = LazyObservable(_ -> calculate_fast_bbox(parent, space), Rect3f())
        bb.fast_bbox[space] = LazyObservable(_ -> calculate_full_bbox(parent, space), Rect3f())
    end
    # TODO: attach notifiers:
    # Plot:
    # - all have onany(plot.converted)
    # - :transformed, ... on(transform_func)
    # - :pixel, ... on(camera.projectionview)
    # Scene:
    # - on(plot.bbox) per space for every child
    return
end

boundingbox(obj::SceneLike; space = :data, mode = :full) = boundingbox(obj, space, mode)
function boundingbox(obj::SceneLike, space = :data, mode = :full)
    if mode == :fast
        return obj.fast_bbox[space][]
    elseif mode == :full
        return obj.full_bbox[space][]
    else
        throw(ArgumentError("Mode $mode not recognized."))
    end
end

data_limits(obj::SceneLike) = boundingbox(obj, :data, :fast)

# TODO: maybe also:
# boundingbox(obj::SceneLike; space = :data, mode = :full) = boundingbox(obj, space, mode)
# function boundingbox(obj::SceneLike, space = :data, mode = :full)
#     # use obj.cache[:marker_bbox] or something like this?
# end

function calculate_fast_bbox(plot::Combined, space::Symbol)
    # TODO: what exactly do we do with this?
    # - :data bbox from plot, other from :data bbox (this would generally make bbox less tight)
    # - bbox from transformed plot data (more expensive)
    # - should we include marker bboxes if they are simple to include (e.g. linear transform in 2D?)
    # - use only max marker bbox to reduce cost?

end

function calculate_full_bbox(plot::Combined, space::Symbol)
    # TODO
    # include everything we reasonably can:
    # - transform data
    # - with markers, transform data to markerspace, add marker bbox, transform to target
end