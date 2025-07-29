# Architecture

The idea behind Makie is to describe complex plots as a composition of primitive building blocks. These primitives are rendered to GUI windows, bitmaps or vector graphics using one of Makie's backend packages.

From an architecture perspective, the two most important objects in Makie are `Scene`s and `Plot`s.

## [Scenes](@id architecture_scenes)

A `Scene` represents an abstract rectangular canvas or viewport. It can contain `Plot` objects which are going to be rendered according to their `Scene`'s camera and light settings.
A given `Scene` can contain child scenes which may cover the full area of the parent `Scene` or a smaller rectangular section of it.
A child scene's camera and light settings may be different from its parent.
There is always one root `Scene` with zero or more child `Scene`s, each of which may again have zero or more child `Scene`s.
This structure forms a tree which is also called the "scene graph".

```@graphviz
digraph {
    rankdir=TB;
    edge [dir=none];
    
    R [label="Root scene\nSize: 600x450\nOffset: 0, 0\n5 Plots"];
    S1 [label="Child scene\nSize: 600x450\nOffset: 0, 0\n2 Plots"];
    S2 [label="Child scene\nSize: 350x300\nOffset: 100, 150\n0 Plots"];
    S3 [label="Child Scene\nSize: 600x450\nOffset: 0, 0\n17 Plots"];
    S4 [label="Child Scene\nSize: 350x300\nOffset: 0, 0\n22 Plots"];
    S5 [label="Child Scene\nSize: 100x200\nOffset: 50, 25\n3 Plots"];
    
    R -> S1;
    R -> S2;
    S1 -> S3;
    S2 -> S4;
    S2 -> S5;
}
```

Every `Scene` in Makie has a 3D camera (consisting of two 4x4 projection and view matrices) and is therefore 3D capable, although some scenes will have orthographic cameras set up which effectively make content look 2D.

A given Makie backend can `display` or render a `Scene` by attaching it to a `[MakieBackend].Screen`. Usually the displayed `Scene` will be the root scene of a given scene graph but it doesn't have to be. The root `Scene` of the scene graph will also usually be held by a `Figure` object (more on `Figure`s below).

## [Plots](@id architecture_plots)

`Plot` objects fall into two categories, primitive or non-primitive. Primitive plots are what the backends can render. Makie has a couple of primitive plot types, for example `Scatter`, `Lines`, `Text`, `Image` or `Mesh`. 

Examples for non-primitives in Makie include `ScatterLines`, a combination of `Scatter` and `Lines` or `Poly`, a combination of `Lines` and `Mesh`. The non-primitives are also sometimes called "recipes", especially because the main interface to declare them is the `@recipe` macro.

An instance of a `Plot` can contain zero or more child `Plot`s of arbitrary plot types, each of which can again contain zero or more child `Plot`s.
Which child plots a new plot type should be made out of can depend on runtime information, most often the types of positional input arguments.
This mechanism is generally implemented by overloading specific methods of `plot!(p::NewPlotType, [other args])` which fill in the empty plot object `p::NewPlotType` with child plots.

Here's an example of the hierarchical structure of the `BoxPlot` recipe which consists of a bunch of child plots, some of which are primitive and some of which are nested themselves:

```@graphviz
digraph {
    rankdir=LR;
    edge [dir=none];
    
    subgraph cluster_boxplot {
        label="BoxPlot";
        style=filled;
        fillcolor="#fcfcfcff";
        
        subgraph cluster_crossbar {
            label="CrossBar (the 'box' part)";
            
            subgraph cluster_poly {
                label="Poly (filled rectangle with optional notches)";
                
                Lines [label="Lines (stroked outline)"];
                Mesh [label="Mesh (filled area)"];
            }
            L1 [label="LineSegments (Median line)"];
        }
        
        Scatter [label="Scatter (outliers)"];
        L2 [label="LineSegments\n(whiskers and quartile lines)"];
    }
}
```

Note that whether a given plot is treated as "primitive" ultimately depends on the rendering backend. As an example, some versions of `poly` can be rendered as primitives in CairoMakie because dropping down to a triangulated mesh representation would be very inefficient and cause visual artifacts compared to using the original polygon directly.

## Figures and Blocks

Everything you see in Makie is made out of `Scene`s and `Plot`s.
But `Scene`s as a low level building block are not the most convenient container object to deal with.
`Scene`s have no notion of axis decorations or layouts, they are just blank canvases that can be positioned in other scenes by manually specifying their extent as a rectangle.

In practice, Makie users build most data visualizations out of more convenient, higher-level objects. These are the `Figure` and several different `Block` objects like `Axis`, `Axis3`, `LScene`, `Button`, `Label`, `Slider` and `Menu`. These objects are themselves built out of `Scene`s and `Plot`s.

The `Figure` consists mainly of two elements, a `Scene` and a `GridLayout`. The `Scene` is the root of the figure's scene graph and the `GridLayout` computes the positions of the figure's `Block`s.

Every `Block` object consists of a `Scene` called the `blockscene` and an arbitrary number of child plots and child scenes connected to it. When we want to create an `Axis` object in Makie we often do something like:

```julia
f = Figure()
ax = Axis(f[1, 1])
scatter!(ax, 1:10)
```

This sets up the following relationship of objects:

```@graphviz
digraph {
    rankdir=TB;
    edge [dir=none];

    subgraph cluster_figure {
        label="Figure";
        style=filled;
        fillcolor="#fcfcfcff";

        GridLayout;
        Scene [label="Root Scene"];
    }
    
    subgraph cluster_axis {
        label="Axis";
        style=filled;
        fillcolor="#fcfcfcff";
        
        GridContent [label="GridContent\n(gets Axis position from layout)"];
        BS [label="Scene (blockscene)"];
        AD [label="Plots (Axis decorations)"];
        AS [label="Scene (Axis canvas)"];
        AP [label="Plots (1 Scatter)"];
        
        BS -> AD;
        BS -> AS;
        AS -> AP;
    }
    
    GridLayout -> GridContent;
    Scene -> BS;
}
```

As you can see, there are two connections between `Figure` and `Axis`, from the figure's `GridLayout` to the axis's `GridContent` and from the figure's root scene to the `Axis`'s `blockscene`, placing all the content of `Axis` and its child plots in the scene graph.

The layout and scene connections are independent of each other. In principle, objects can be added to the scene graph without being in the layout just as objects can be added to the layout without being in the scene graph.

The `GridLayout` connection is just about placing the `Axis` scene in the right position, it's not required for display. Blocks can be placed outside a figure's layout as well by controlling their boundingbox manually:

```julia
f = Figure()
ax = Axis(f, bbox = BBox(0, 200, 0, 100))
scatter!(ax, 1:10)
```

This removes the `GridLayout` connection from the above diagram:

```@graphviz
digraph {
    rankdir=TB;
    edge [dir=none];

    subgraph cluster_figure {
        label="Figure";
        style=filled;
        fillcolor="#fcfcfcff";

        GridLayout;
        Scene [label="Root Scene"];
    }
    
    subgraph cluster_axis {
        label="Axis";
        style=filled;
        fillcolor="#fcfcfcff";
        
        GridContent [label="GridContent\n(unconnected)", style=dashed];
        BS [label="Scene (blockscene)"];
        AD [label="Plots (Axis decorations)"];
        AS [label="Scene (Axis canvas)"];
        AP [label="Plots (1 Scatter)"];
        
        BS -> AD;
        BS -> AS;
        AS -> AP;
    }
    
    GridLayout -> GridContent [style=invis];
    Scene -> BS;
}
```
