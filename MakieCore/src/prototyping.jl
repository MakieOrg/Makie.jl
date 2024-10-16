#=
Thoughts on Attribute passthrough & recipes:
- `shared_attributes` wants `on_update(val -> child.name = val, parent, name)`
- recipes want the same, but with multiple inputs, outputs and calculations
- some recipes want scene data (projectionview, viewport)
Maybes:
- recipes may want caching/intermediate results
- uses Attributes, not plot objects

Backends:
- `backend_value = ...; on_update(val -> backend_value = convert(val), primitive, name)`
- and sometimes multiple inputs -> one or multiple outputs

Passthrough - Backend interop:
- parent update needs to be visible from primitives so backend knows something has/will change
- shared_attributes could:
    - register `on_update(() -> resolve_updates!(parent), child, :parent)`
    - ~~register `on_update(() -> push!(child.updated, :parent), parent)`~~ this wouldn't run at setproperty-time
    - parent needs to notify children immediately
        - child could have multiple parent (e.g. recipe parent + parent scene) ... maybe?

General:
- some things should be getable only (converted, boundingbox, calculated_colors, ...?)
- recipe parent should not run convert_attribute etc
    - calculated colors maybe should run if the result is reusable? what's the normal case?
- some attributes should not trigger updates themselves (label, xautolimits, ...)
    - can auto generate this from UpdateFunction inputs
=#

struct UpdateFunction
    inputs::Vector{Symbol} # input attributes for this callback (for checking & args construction)
    update::Function
end

struct UpdatableAttributes
    data::Dict{Symbol, Any}        # Attributes, plot args
    updated::Set{Symbol}           # keys of changed data
    tasks::Vector{UpdateFunction}  # run these on update if necessary

    # maybe?
    protected::Set{Symbol} # can't set this key
    skipped::Set{Symbol}   # no update triggered for this key
    
    # for notifying children of parent updates and resolving parent updates
    outdated_parents::Set{UpdatableAttributes}
    child_updates::Vector{Function}
end

function (task::PlotUpdateTask)(attr::UpdateFunction)
    task.update(get.(Ref(attr), task.inputs))
    return
end

# set value + register change
# probably mirrored for setindex!, etc
function Base.setproperty!(attr::UpdatableAttributes, key::Symbol, value)
    if haskey(attr, key)
        if key in attr.protected
            error("$key Attribute is read only.")
        else
            attr.data[key] = value
            if !(key in attr.skipped)
                push!(attr.updated, key)
                foreach(f -> f(), attr.child_updates)
            end
        end
    else
        throw(AttributeNameError(key))
    end
end

# run all the updates that need to run
function resolve_updates!(attr::UpdatableAttributes)
    isempty(attr.updated) && return

    if !isempty(attr.outdated_parents)
        resolve_updates!.(attr.outdated_parents)
        empty!(attr.outdated_parents)
    end
    
    isempty(attr) && return

    for task in attr.tasks
        if any(name -> name in attr.updated, task.inputs)
            task(attr)
        end
    end

    empty!(attr.updated)

    return
end

# register new attribute
function add_attribute!(attr::UpdatableAttributes, name::Symbol, value, protected = false)
    attr.data[name] = value
    protected && push!(attr.protected, name)
    push!(attr.skipped, name) # maybe re-resolve?
    return
end

# register new update task
function on_update(f::Function, attr::UpdatableAttributes, inputs::Symbol...)
    callback = UpdateFunction(inputs, f)
    push!(attr.tasks, callback)
    @assert issubset(Set(inputs), keys(attr.data)) # or check later at init?
    setdiff!(attr.skipped, Set(inputs))
    # maybe run task to initialize possible outputs
    return
end


################################################################################
# Sketching usage
################################################################################

# Attribute passthrough, recipes
function shared_attributes(parent, TargetType; renamed...)
    valid_outputs = attribute_names(TargetType)
    valid_inputs = apply_renaming(parent.attributes, renamed)
    attr = UpdatableAttributes()

    # make parent notify child that updates are queued (maybe do in plot!(parent_plot)?)
    # on_update(() -> push!(attr.updated, :parent), parent.attributes)
    # This doesn't work because it wouldn't run immediately. This needs to be 
    # separate from normal updates
    push!(parent.attributes.children, () -> push!(attr.outdated_parents, parent.attributes))
    push!(attr.parents, parent.attributes)

    # map parent update to child update
    # One Function with a check loop better than many without?
    on_update(parent.attributes, valid_inputs...) do args...
        for (src_name, trg_name, value) in zip(valid_inputs, valid_outputs, args)
            if src_name in parent.attributes.changed
                setproperty!(attr, trg_name, value)
            end
        end
    end

    return attr
end

function plot!(parent::MyPlot)
    attr = shared_attributes(parent, Scatter, color = :markercolor)
    
    # not just pass along
    on_update(parent, :converted) do pos
        attr.position = calc_pos(pos)
    end

    scatter!(parent, attr)

    # Could we have "second parent"?
    attr2 = shared_attributes(parent, Text)
    on_update(parent_scene(parent), :lookat, :eyeposition, :upvector) do args...
        attr2.text = camera_data_string(args...)
    end
    text!(parent, attr)
end

# Backend

function backend_draw_primitive(primitive)
    backend_data = Dict{Symbol, Any}()

    # update backend data with convert_attribute(plot.attribute)
    for key in union(attribute_names(primitive), simple_converts)
        backend_data[key] = convert_attribute(args..., primitive[key])
        on_update(v -> backend[data] = convert_attribute(args..., v), primitive, key)
    end

    # attributes that need calculations
    on_update(primtive, inputs...) do args...
        backend_data[:calculated_thing] = calculation(args)
    end
end

function rendertask()
    while running
        if any(plot -> !isempty(plot.attributes.updated), registered_plot)
            foreach(resolve_updates!, registered_plot)
            # render...
        end
    end
end