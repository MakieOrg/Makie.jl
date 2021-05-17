# 0.14.0

## New features
 
- `rangebars` is added as an alternative to `errorbars` with absolute high/low values instead of relative deltas

## Improvements & Implementation Changes

- `errorbars` accepts a different, wider range of arguments and its input data can now be changed dynamically without erroring (technically breaking, even if only in a minor way)

## Bugfixes

- `errorbars` and `rangebars` data limits ignore whiskers now, which before sometimes messed up autolimits

# 0.13.11

## Improvements & Implementation Changes

- Menu optionvalue and optionlabel default to string representation for non 2-tuple argument

# 0.13.10

## Improvements & Implementation Changes

- Compat with StaticArrays 1.0

# 0.13.09

## Improvements & Implementation Changes

- addmouseevents! return value is now a MouseEventHandle and can be disconnected fully via `clear!`
- Menu options can be changed on the fly

# 0.13.6

## Bugfixes

- Orientation of contourf matrix flipped for same direction as heatmap etc.
- Contourf polys can change dynamically

## Improvements & Implementation Changes

- Selection rectangle dims outer area via transparent mesh
- Heatmap, image, contourf and plots implementing special trait automatically cause tight limits for Axis

# 0.13.5

## New features

- Added filled contour `contourf` plot function using Isoband in the backend

## Improvements & Implementation Changes

- Toggle reacts on mousedown not click to be more snappy

# 0.13.4

## Bugfixes

- Removed shadowing of Base.hasfield in MakieLayout
- Forwarded layout kwargs in `labelslidergrid!` correctly

# 0.13.3

## New features

- Added interactions model to Axis. Interactions can be added with `register_interaction!` and removed with `deregister_interaction!`, as well as activated or deactivated temporarily with `activate_interaction!` and `deactivate_interaction!`.
- Added `labelslidergrid!`, a function to create an internally aligned grid of sliders with labels and value-labels.
- Axis has attributes `xrectzoom` and `yrectzoom` that control if the rectangle zoom changes the respective dimension or not.

## Improvements & Implementation Changes

- Cleaned up Slider style and implementation, Slider doesn't react while below other objects anymore
- MakieLayout Mouse event types are now enum instances for less compilation
- MakieLayout Mouse events store position in both data and pixel coordinates
- Aligned colors of Menu, Slider, LButton etc better
