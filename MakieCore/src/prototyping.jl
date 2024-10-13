################################################################################
### Version 1
################################################################################


#=
We need:
- `inputs` for user Attributes/data
- `outputs` for converted/processed Attributes/data
- `changed` to track what the user has updated (*1, *4)
- `updates` for tracking functions that do the calculations (*2, *3)
=#
mutable struct Plot{PlotFunc, T} <: ScenePlot{PlotFunc}
    inputs::Dict{Symbol, Any}       # args + Attributes?
    outputs::Dict{Symbol, Any}      # results of update functions
    changed::Set{Symbol}            # what has the user changed?
    updates::Vector{PlotUpdateTask} # sorted
    
    parent::Union{AbstractScene,Plot}
    transformation::Union{Nothing, Transformable}
    plots::Vector{Plot}

    function Plot{Typ,T}(
                kw::Dict{Symbol,Any}, kw_obs::Observable{Vector{Pair{Symbol,Any}}},
                args::Vector{Any}, converted::Vector{Observable},
            ) where {Typ,T}
        return new{Typ,T}(nothing, kw, kw_obs, args, converted, Attributes(), Plot[], deregister_callbacks)
    end
end


#=
(*2) What should the update "Functions" look like?
- To decide whether a function needs to run we need to know its `inputs`
- To avoid side effect we may not want to pass the plot object itself
    - use `outputs` to describe define what the function affects
    - user `update` function becomes ~ `foo!(outputs, inputs)`
    - inputs and outputs may need order for this (if inputs not Dict-like)
- if updates can chain we need to know outputs to register them (*1)
=#
struct PlotUpdateTask
    inputs::Vector{Symbol} # ordered for update call
    outputs::Vector{Symbol} # ordered for update call
    update::Function # Any for structs?
end

function (task::PlotUpdateTask)(plot::Plot)
    task.update(get.(Ref(plot), task.outputs), get.(Ref(plot), task.inputs))
    return
end


# setproperty can notify us of updates by adding them to `plot.changed`
function Base.setproperty!(plot::Plot, key::Symbol, value)
    if hasfield(Plot, key)
        setfield!(plot, key, value)
    else
        register_update!(plot, key, value)
    end
    return 
end

function register_update!(plot::Plot, key::Symbol, value)
    if haskey(plot.inputs, key)
        push!(plot.changed, key)
        plot.inputs[key] = value
    else
        throw(UnknownAttributeError(key))
    end
    return
end


#=
The backend resolves user updates by calling this function.
If there are changed inputs, we need to run every function that uses those inputs.
Options:
- issubset() doesn't work because update with inputs (a,b) should trigger if (a,c)
  have been updated, but neither is a subset of the other
- any(name -> name in set, other) works, O(other)

(*1) updates can cause more updates:
- an update may create intermediate results, e.g. text, ablines, ... (can we get around this?)

(*3) updates maybe ordered
- e.g. a boundingbox update should not trigger before positional updates
- use an ordered collection (Vector) for updates and let devs deal with it?

The backend probably needs to know what changed if it runs its own code in response
OR the backend could add functions reacting to outputs, see (*1)
=#
function resolve_updates!(plot::Plot)
    isempty(plot.changed) && return 

    for task in plot.updates
        if any(name -> name in plot.changed, task.inputs)
            task(plot)
            push!(plot.changed, task.outputs) 
        end
    end

    empty!(plot.changed)

    return # maybe Vector/Set of updated outputs?
end


################################################################################
### Version 2
################################################################################


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