# Devdocs


## Logistical issues

### Transition to Plots.jl

Considering that MakiE is designed quite differently from Plots.jl to make up for all the design problems, any transition to Plots.jl will
basically mean replacing Plots.jl. I don't see how to slowly incorperate ideas from MakiE into Plots.jl without a huge amount of work.
So I'd propose to let MakiE live as it's own package for a while until we can ensure, that all features from Plots.jl are covered.
Then we can think about renaming MakiE, make a PR to Plots.jl to replace the internals with MakiE or simply deprecate Plots.jl and suggest to move to MakiE. 

### Other backends

I'm inclined to implement a reference backend different from GLVisualize with Cairo. This would make sense to me, because Cairo is completely orthogonal to
GLVisualize and offers missing bits and pieces like PDF/SVG export. I have a plan to also include 3D features for which I've already created a prototype. 
If @jheinen is on board, I'd be willing to instead create the first reference backend using GR.


### Precompilation

MakiE goes with the design of backends overloading the functions like `scatter(::Backend, args...)`
which means they can be loaded in by Julias normal code loading mechanisms and should be precompile save.
MakiE also tries to be statically compilable, but this isn't as straightforward as one could think.
So far it seems that all kind of globals are not save for static compilation and generated functions seem to also make problems.
I'm slowly removing problematic constructs from the dependencies and try to get static compilation as quick as possible.



### TODOs / Up for grabs