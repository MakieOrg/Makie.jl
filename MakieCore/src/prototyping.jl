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
- shared_attributes could register:
    - `on_update(() -> push!(child.updated, :parent), parent)`
    - `on_update(() -> resolve_updates!(parent), child, :parent)`

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
            end
        end
    else
        throw(AttributeNameError(key))
    end
end

# run all the updates that need to run
function resolve_updates!(plot::Plot)
    isempty(plot.attributes.updated) && return

    if :parent in plot.attributes.updated
        delete!(plot.attributes.updated, :parent)
        resolve_updates!(parent(plot))
    end
    
    isempty(plot.attributes.updated) && return

    for task in plot.attributes.tasks
        if any(name -> name in plot.attributes.updated, task.inputs)
            task(plot.attributes)
        end
    end

    empty!(plot.attributes.updated)

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

# register on-any-change update (for propagating parent updates)
function on_update(f::Function, attr::UpdatableAttributes)
    push!(attr.tasks, UpdateFunction(Symbol[], f))
    # maybe run task to initialize possible outputs
    return
end



# Sketching usage
function shared_attributes(parent, TargetType; renamed...)
    valid_outputs = attribute_names(TargetType)
    valid_inputs = apply_renaming(parent.attributes, renamed)
    attr = UpdatableAttributes()
    # make parent notify child that updates are queued (maybe do in plot!(parent_plot)?)
    on_update(() -> push!(attr.updated, :parent), parent)

    # map parent update to child update
    # One Function with a check loop better than many without?
    on_update(parent, valid_inputs...) do args...
        for (src_name, trg_name, value) in zip(valid_inputs, valid_outputs, args)
            if src_name in parent.changed
                setproperty!(attr, trg_name, value)
            end
        end
    end
end

function plot!(parent::MyPlot)
    attr = shared_attributes(parent, Scatter, color = :markercolor)
    
    # not just pass along
    on_update(parent, :converted) do pos
        attr.position = calc_pos(pos)
    end

    scatter!(parent, attr)
end

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