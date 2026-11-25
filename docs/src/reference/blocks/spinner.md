# Spinner

A busy indicator driven by render ticks. Set `running = true` while work is in progress.

```julia
spinner = Spinner(fig[1, 1]; message = "Loading…", running = true)
spinner.running = false
```

```@attrdocs
Spinner
```
