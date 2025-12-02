# Observables

Interaction and animations in Makie can be handled using [`Observables.jl`](https://juliagizmos.github.io/Observables.jl/stable/).
An `Observable` is a container object whose stored value you can update interactively.
You can create functions that are executed whenever an observable changes.
You can also create observables whose values are updated whenever other observables change.
This way you can easily build dynamic and interactive visualizations.

On this page you will learn how the `Observable`s pipeline and the event-based interaction system work. Besides this, there is also a video tutorial on how to make interactive visualizations (or animations) with Makie.jl and the `Observable` system:

```@raw html
<iframe width="560" height="315" src="https://www.youtube.com/embed/L-gyDvhjzGQ?controls=0" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
```

!!! info
    Makie 0.24 introduced the `ComputeGraph` for processing updates within plots.
    With that `Makie.update!(plot, attribute1 = new_value1, ...)` was added, which can be used instead of updating Observables.

## The `Observable` structure

A `Observable` is an object that allows its value to be updated interactively.
Let's start by creating one:

```@example observable
using GLMakie, Makie

x = Observable(0.0)
```

Each `Observable` has a type parameter, which determines what kind of objects it can store.
If you create one like we did above, the type parameter will be the type of the argument.
Keep in mind that sometimes you want a wider parametric type because you intend to update the `Observable` later with objects of different types.
You could for example write:

```julia
x2 = Observable{Real}(0.0)
x3 = Observable{Any}(0.0)
```

This is often the case when dealing with attributes that can come in different forms.
For example, a color could be `:red` or `RGB(1,0,0)`.

## Triggering A Change

You change the value of a Observable with empty index notation:

```@example observable
x[] = 3.34
nothing # hide
```

This was not particularly interesting.
But Observables allow you to register functions that are executed whenever the Observable's content is changed.

One such function is `on`. Let's register something on our Observable `x` and change `x`'s value:

```@example observable
on(x) do x
    println("New value of x is $x")
end

x[] = 5.0
nothing # hide
```

!!! note
    If you updated the `Observable` using in-place syntax (e.g. `img[] .= colorant"red"`), you need to manually
    `notify(img)` to trigger the function.

!!! note
    All registered functions in a `Observable` are executed synchronously in the order of registration.
    This means that if you change two Observables after one another, all effects of the first change will happen before the second change.

There are two ways to access the value of a `Observable`.
You can use the indexing syntax or the `to_value` function:

```julia
value = x[]
value = to_value(x)
```

The advantage of using `to_value` is that you can use it in situations where you could either be dealing with Observables or normal values. In the latter case, `to_value` just returns the original value, like `identity`.

## Chaining `Observable`s With `lift`

You can create a Observable depending on another Observable using `lift`.
The first argument of `lift` must be a function that computes the value of the output Observable given the values of the input Observables.

```@example observable
f(x) = x^2
y = lift(f, x)
```

Now, whenever `x` changes, the derived `Observable` `y` will immediately hold the value `f(x)`.
In turn, `y`'s change could trigger the update of other observables, if any have been connected.
Let's connect one more observable and update x:

```@example observable
z = lift(y) do y
    -y
end

x[] = 10.0

@show x[]
@show y[]
@show z[]
nothing # hide
```

If `x` changes, so does `y` and then `z`.

Note, though, that changing `y` does not change `x`.
There is no guarantee that chained Observables are always synchronized, because they
can be mutated in different places, even sidestepping the change trigger mechanism.

```@example observable
y[] = 20.0

@show x[]
@show y[]
@show z[]
nothing # hide
```


## Shorthand Macro For `lift`

When using `lift`, it can be tedious to reference each participating `Observable`
at least three times, once as an argument to `lift`, once as an argument to the closure that
is the first argument, and at least once inside the closure:

```julia
x = Observable(rand(100))
y = Observable(rand(100))
z = lift((x, y) -> x .+ y, x, y)
```

To circumvent this, you can use the `@lift` macro. You simply write the operation
you want to do with the lifted `Observable`s and prepend each `Observable` variable
with a dollar sign \$. The macro will lift every Observable variable it finds and wrap
the whole expression in a closure. The equivalent to the above statement using `@lift` is:

```julia
z = @lift($x .+ $y)
```

This also works with multiline statements and tuple or array indexing:

```julia
multiline_node = @lift begin
    a = $x[1:50] .* $y[51:100]
    b = sum($z)
    a .- b
end
```

If the Observable you want to reference is the result of some expression, just use `$` with parentheses around that expression.

```julia
container = (x = Observable(1), y = Observable(2))

@lift($(container.x) + $(container.y))
```

## Problems With Synchronous Updates

!!! info
    As of Makie 0.24, synchronous update issues with plots can be circumvented by using `Makie.update!(plot, attrib1 = ..., attrib2 = ...)`.

One very common problem with a pipeline based on multiple observables is that you can only change observables one by one.
Theoretically, each observable change triggers its listeners immediately.
If a function depends on two or more observables, changing one right after the other would trigger it multiple times, which is often not what you want.

Here's an example where we define two Observables and lift a third one from them:

```julia
xs = Observable(1:10)
ys = Observable(rand(10))

zs = @lift($xs .+ $ys)
```

Now let's update both `xs` and `ys`:

```julia
xs[] = 2:11
ys[] = rand(10)
```

We just triggered `zs` twice, even though we really only intended one data update.
But this double triggering is only part of the problem.

Both `xs` and `ys` in this example had length 10, so they could still be added without a problem.
If we want to append values to xs and ys, the moment we change the length of one of them, the function underlying `zs` will error because of a shape mismatch.
Sometimes the only way to fix this situation, is to mutate the content of one observable without triggering its listeners, then triggering the second one.

```julia
xs.val = 1:11 # mutate without triggering listeners
ys[] = rand(11) # trigger listeners of ys (in this case the same as xs)
```

Use this technique sparingly, as it increases the complexity of your code and can make reasoning about it more difficult.
It also only works if you can still trigger all listeners correctly.
For example, if another observable listened only to `xs`, we wouldn't have updated it correctly in the above workaround.
Often, you can avoid length change problems by using arrays of containers like `Point2f` or `Vec3f` instead of synchronizing two or three observables of single element vectors manually.
