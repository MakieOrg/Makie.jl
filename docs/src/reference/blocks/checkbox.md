# Checkbox

```@figure backend=GLMakie
f = Figure()

gl = GridLayout(f[2, 1], tellwidth = false)
subgl = GridLayout(gl[1, 1])

cb1 = Checkbox(subgl[1, 1], checked = false)
cb2 = Checkbox(subgl[2, 1], checked = true)
cb3 = Checkbox(subgl[3, 1], checked = true)

Label(subgl[1, 2], "Show grid", halign = :left)
Label(subgl[2, 2], "Show ticklabels", halign = :left)
Label(subgl[3, 2], "Show title", halign = :left)
rowgap!(subgl, 8)
colgap!(subgl, 8)

ax = Axis(
    f[1, 1],
    title = "Checkboxes",
    xgridvisible = cb1.checked,
    ygridvisible = cb1.checked,
    xticklabelsvisible = cb2.checked,
    yticklabelsvisible = cb2.checked,
    xticksvisible = cb2.checked,
    yticksvisible = cb2.checked,
    titlevisible = cb3.checked,
    alignmode = Outside(),
)

f
```

## Attributes

```@attrdocs
Checkbox
```