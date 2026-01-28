# Table

The `Table` block displays tabular data with interactive features like row selection, column sorting, and scrolling.

```@example table
using GLMakie
GLMakie.activate!() # hide

fig = Figure()

# Sample data
data = (
    name = ["Alice", "Bob", "Charlie", "Diana", "Eve"],
    age = [28, 35, 42, 31, 25],
    city = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix"]
)

t = Table(fig[1, 1]; data = data)

# Listen to selection changes
on(t.selection) do sel
    if sel !== nothing
        println("Selected: ", sel)
    end
end

fig
nothing # hide
```

## Styling

You can customize the appearance of the table with various styling attributes:

```@figure backend=GLMakie

fig = Figure()

data = (
    id = 1:10,
    name = ["Item $i" for i in 1:10],
    value = rand(10) .* 100
)

t = Table(fig[1, 1];
    data = data,
    header_color = RGBf(0.2, 0.4, 0.6),
    header_textcolor = :white,
    cell_color_even = RGBf(0.95, 0.95, 1.0),
    cell_color_odd = RGBf(0.9, 0.9, 0.95),
    cell_color_selected = RGBf(0.7, 0.85, 1.0),
    row_height = 30.0,
    header_height = 35.0
)

# Select row 3 by default
t.i_selected[] = 3

fig
```

## Scrolling

When `max_visible_rows` is set, the table becomes scrollable:

```@figure backend=GLMakie

fig = Figure()

# Large dataset
data = (
    row = 1:50,
    name = ["Entry $i" for i in 1:50],
    value = rand(50)
)

t = Table(fig[1, 1];
    data = data,
    max_visible_rows = 10
)

fig
```


## Sorting

Click on column headers to sort by that column. Click again to toggle between ascending and descending order.

```@figure backend=GLMakie

fig = Figure()

data = (
    name = ["Zebra", "Apple", "Mango", "Banana", "Cherry"],
    count = [5, 12, 8, 15, 3]
)

t = Table(fig[1, 1];
    data = data,
    sortable = true,
    show_sort_indicator = true
)

# Sort by the second column (count), descending
t.sort_column[] = 2
t.sort_direction[] = :descending

fig
```


## Callbacks

You can register callbacks for various interactions:

```julia
# Single click callback
t.on_row_click[] = (table, row_index, row_data) -> begin
    println("Clicked row $row_index: $row_data")
end

# Double click callback
t.on_row_doubleclick[] = (table, row_index, row_data) -> begin
    println("Double-clicked row $row_index")
end

# Sort change callback
t.on_sort_change[] = (table, column_index, direction) -> begin
    println("Sorted by column $column_index ($direction)")
end
```


## Attributes

```@attrdocs
Table
```
