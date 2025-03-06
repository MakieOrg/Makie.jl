# Compute Pipeline

The compute pipeline is Makie's internal representation of the computations that a plot needs to do.
They were previously represented by a loose network of Observables.
Those had problems with synchronous updates (e.g. `x` and `y` need to update together, before updating `xy = Point.(x, y)`)
and repeated updates which the compute pipeline solves.

## ComputeGraph

The `ComputeGraph` is the central object of the compute pipeline.
It contains nodes that hold data and edges that represent computations.
They are both constructed indirectly through two functions - `add_input!()` and `register_computation!()`.
Here is a brief example of a graph with two inputs that are added together and stored in an output node:

```julia
# create a new, empty graph
graph = ComputeGraph()

# add inputs
add_input!(graph, :input1, 1)
add_input!(value -> Float32(value), graph, :input2, 2)

# add computations (edges + output nodes)
register_computation!(graph, [:input1, :input2], [:output]) do inputs, changed, cached
    input1, input2 = inputs
    return (input1[] + input2[], )
end
```

The two `add_input!()` calls create nodes with the names :input1 and :input2, holding the values 1 and 2 respectively.
The second call also defines a conversion function that is applied to input data before placing it into the graph.

The `register_computation!()` calls refers to these two nodes by name and defines a computation on them.
The result is stored in a new node called :output.
The callback function of the computation always takes 3 arguments:

1. `inputs::NamedTuple{input_names, Ref}` which contains `Ref`s to the data held by the inputs of the computation. The order always matches the order of the given input names.
2. `changed::NamedTuple{input_names, Bool}` which contains information on which inputs have changed since the computation was last triggered.
3. `cached::Union{Nothing, Tuple}` which contains the data of the previous output(s) in order, or nothing if no previous output exists.

The output should be either a tuple with equal size to the output names set in `register_computations!()`, or `nothing` if the result is the same as the previous.

## Updating Data

To update the compute graph one or multiple of its inputs need to be updated.
This is done with the `update!()` function.
If only one input is updated, this can also be done using `setproperty!()`.

```julia
# update both inputs together
update!(graph, input1 = 5, input2 = 1)

# update one input with setproperty!()
graph.input2 = 3
```

Note that these updates will not immediately trigger computations.
Instead dependent nodes in the graph are marked as "dirty".
If data for one of those dirty nodes is requested, the computations will run as necessary.
This allows the graph to skip redundant and outdated updates.
In this example we would trigger the computations by requesting the value of "output":

```julia
graph[:output][]
```

## Connecting Compute Graphs

Output nodes of one compute graph can be used as inputs of another.
For that they simply need to be passed in `add_inputs!()`.
Doing so will make the input nodes of the child graph unavailable to updating.

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