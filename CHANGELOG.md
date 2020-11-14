# 0.13.6

## Bugfixes

- Orientation of contourf matrix flipped for same direction as heatmap etc.
- Contourf polys can change dynamically

## Improvements & Implementation Changes

- Selection rectangle dims outer area via transparent mesh
- Heatmap, image, contourf and plots implementing special trait automatically cause tight limits for LAxis

# 0.13.5

## New features

- Added filled contour `contourf` plot function using Isoband in the backend

## Improvements & Implementation Changes

- LToggle reacts on mousedown not click to be more snappy

# 0.13.4

## Bugfixes

- Removed shadowing of Base.hasfield in MakieLayout
- Forwarded layout kwargs in `labelslidergrid!` correctly

# 0.13.3

## New features

- Added interactions model to LAxis. Interactions can be added with `register_interaction!` and removed with `deregister_interaction!`, as well as activated or deactivated temporarily with `activate_interaction!` and `deactivate_interaction!`.
- Added `labelslidergrid!`, a function to create an internally aligned grid of sliders with labels and value-labels.
- LAxis has attributes `xrectzoom` and `yrectzoom` that control if the rectangle zoom changes the respective dimension or not.

## Improvements & Implementation Changes

- Cleaned up LSlider style and implementation, LSlider doesn't react while below other objects anymore
- MakieLayout Mouse event types are now enum instances for less compilation
- MakieLayout Mouse events store position in both data and pixel coordinates
- Aligned colors of LMenu, LSlider, LButton etc better
