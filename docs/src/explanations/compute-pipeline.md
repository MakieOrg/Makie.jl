# Compute Pipeline

The compute pipeline is Makie's internal representation of the computations that a plot needs to do.
They were previously represented by a loose network of Observables.
Those had problems with synchronous updates (e.g. `x` and `y` need to update together, before updating `xy = Point.(x, y)`) and repeated updates which the compute pipeline solves.

## ComputeGraph

The `ComputeGraph` is the central object of the compute pipeline.
It contains nodes that hold data and edges that represent computations.
They are both constructed indirectly through the two functions `add_input!()` and `register_computation!()`.
Here is a brief example of a graph with two inputs that are added together and stored in an output node:

```julia
# create a new, empty graph
graph = ComputeGraph()

# add inputs
add_input!(graph, :input1, 1)
add_input!((key, value) -> Float32(value), graph, :input2, 2)

# add computations (edges + output nodes)
register_computation!(graph, [:input1, :input2], [:output]) do inputs, changed, cached
    input1, input2 = inputs
    return (input1[] + input2[], )
end
```

The two `add_input!()` calls create nodes with the names :input1 and :input2, holding the initial values 1 and 2 respectively.
The second call also defines a conversion function that is applied to input data before placing it into the graph.

The `register_computation!()` call refers to these two nodes by name and defines a computation on them.
The result is stored in a new node called :output.
The callback function of the computation always takes 3 arguments:

1. `inputs::NamedTuple{input_names, Ref}` which contains `Ref`s to the data held by the inputs of the computation. The order always matches the order of the input names given to `register_computation!()`.
2. `changed::NamedTuple{input_names, Bool}` which contains information on which inputs have changed since the computation was last triggered.
3. `cached::Union{Nothing, Tuple}` which contains the data of the previous output(s) in order, or nothing if no previous output exists.

The output should be either a tuple with equal size to the output names set in `register_computations!()`, or `nothing` if the result is the same as the previous.

Alternatively to `register_computation!(f, graph, inputs, outputs)` you can also use `map!(f, graph, inputs, outputs)`.
`map!()` simplifies the structure of the callback function `f` by passing the inputs directly as arguments, without `changed` or `cached`.
It also allows you to pass just one symbol as the input and/or output.

```julia
graph = ComputeGraph()
add_input!(graph, :input1, 1)
add_input!((key, value) -> Float32(value), graph, :input2, 2)

map!((a, b) -> a + b, graph, [:input1, :input2], :output)
map!((a, b) -> ([a, b], [b, a]), graph, [:input1, :input2], [:ab, :ba])
```

## Updating Data

To update the compute graph at least one of its inputs need to be updated.
This is done with the `update!()` function.

```julia
# update both inputs together
update!(graph, input1 = 5, input2 = 1)
```

Note that these updates will not immediately trigger computations.
Instead dependent nodes in the graph will be marked as "dirty".
If data for one of those dirty nodes is requested, all necessary computations will run.
This allows the graph to skip redundant and outdated updates.
In this example we would trigger the computations by requesting the value of "output":

```julia
graph[:output][]
```

## Connecting multiple Compute Graphs

Two separate compute graphs can be connected by using the output of one graph as the input of another.
For that the output of parent graphs needs to be passed to the child graph with `add_inputs!(child_graph, name, node_from_parent)`.

```julia
graph = ComputeGraph()
add_input!(graph, :input1, 1)
add_input!(graph, :input2, 2)

register_computation!(graph, [:input1, :input2], [:sum]) do inputs, changed, cached
    input1, input2 = inputs
    return (input1[] + input2[], )
end

graph2 = ComputeGraph()
add_input!(graph2, :sum, graph[:sum])

register_computation!(graph2, [:sum], [:output]) do (sum,), changed, cached
    return (2 * sum[], )
end

graph2[:output][] # 2 * (1 + 2) = 6
```

Note that connecting a node between graphs will disable updating of that node in the child graph.
Therefore you can not use `update!(graph2, sum = new_value)` in the example above.
Instead the `:sum` node is solely updated by the parent graph, in which you can update either `:input1` or `:input2` to update `:sum`

## Interfacing with Observables

You can use an `obs::Observable` as an input to a ComputeGraph by passing it to `add_input!(graph, name, obs)`.
This will trigger `update!(graph, name = obs[])` every time the observable updates.

You can also generate an observable output for a compute node, either directly by calling `ComputePipeline.get_observable!(graph, name)` or by having it implicitly generate in a `map(f, computed, computed_or_obs...)` (or `on`, `onany`, `lift`, `@lift`) call.
This will create or retrieve an observable that mirrors the value of the respective compute node.
In order to preserve the "push" nature of observables, this will force the compute graph to resolve immediately when the compute node becomes outdated.
As a result the graph becomes less lazy and may run more computations than otherwise necessary.

```julia
graph = ComputeGraph()
add_input!(graph, :input1, 1)
add_input!(graph, :input2, 2)
map!((a, b) -> a + b, graph, [:input1, :input2], :output)

on(println, graph.output)
update!(graph, input1 = 2); # prints 4

obs2 = ComputePipeline.get_observable!(graph, :output)
```