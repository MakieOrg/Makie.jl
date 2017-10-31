# Devdocs


## Logistical issues


### Precompilation

MakiE goes with the design of backends overloading the functions like `scatter(::Backend, args...)`
which means they can be loaded in by Julias normal code loading mechanisms and should be precompile save.
MakiE also tries to be statically compilable, but this isn't as straightforward as one could think.
So far it seems that all kind of globals are not save for static compilation and generated functions seem to also make problems.
I'm slowly removing problematic constructs from the dependencies and try to get static compilation as quick as possible.



### TODOs / Up for grabs

