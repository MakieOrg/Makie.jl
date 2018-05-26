
# Recipe/default values/themes need:

 * themes are only psydo global, in the sense that you can have a different theme per scene, but when creating a new scene without a theme, it needs to come from somewhere
 * default theme needs to be extendeable by Recipe packages
 * default values need to make their way into "global" theme
 * changing values in global theme need to be linked to everything plotted that didn't overwrite default values
 * there should be a documentation of every attribute in a theme/recipes
 * there needs to be function, that fills in default values into partial attribute lists (e.g. complete the kw_args that got passed to plot(...))
 * the default completion functions need to be composable, to share common attributes
 * there needs to be a transparent and overloadable conversion of attributes to a type understood by a backend

# final endpoint all recipes/plot functions call
# All plots get constructed lazily, so they are not complete until they get here.
# This means a plot contains only the kw_args + args until it gets here:
# might be renamed, to make it less prone to conflict with plot!
# might get a root scene/display passed as first argument
function plot!(plot_object::Plot)
    expand_shortnames!(plot_object) # removes short forms and expands them to long form
    # fills in all the missing attributes with default values taken from theme
    # Themes will be stored in root scene of plot_object - I'm still debating this though
    # and maybe want to do these things more explicitely by passing the root scene to plot! here
    complete_defaults!(plot_object)

    # estimates a boundingbox from pure data
    # If a camera was explicitely added by the user, that camera will just be used and this is a no-op
    # if not, a boundingbox estimate will need to come from just the data or from user defined limits
    # this is needed since e.g. attributes can contain units which are dependentant on a camera/limits to be present!
    cam, bb = add_camera_from_bb_or_plot!(plot_object)

    # create an axis if plot indicates that it needs an axis via the attributes in plot_objects
    # this axis will get linked by default to the camera and if no limits are passed as attributes
    # limits will fallback to the estimated boundingbox
    # if already has an axis, no axis will get added. This way you can also link axes.
    add_axis_from_cam_or_plot!(plot_object, cam, bb)

    # pretty much the same as with the axis
    add_labels_from_plot(plot_object)

    # Now that we have a camera, axis + labels, we can calculate an exact boundingbox
    bb = real_boundingbox(plot_object)

    # which we can use to correctly center the plot
    center_camera!(plot_object, cam, bb)
    plot_object
end
