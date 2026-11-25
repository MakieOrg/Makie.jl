# Modal

A dialog that dims the figure and blocks pointer input to the content beneath it.
Add blocks to the dialog's layout, then show or hide it with `open!` and `close!`.

```julia
modal = Modal(fig; title = "Settings")
Slider(modal[1, 1]; range = 1:10)
open!(modal)
```

```@attrdocs
Modal
```
