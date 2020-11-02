# 13.3

## New features

- Added interactions model to LAxis. Interactions can be added with `register_interaction!` and removed with `deregister_interaction!`, as well as activated or deactivated temporarily with `activate_interaction!` and `deactivate_interaction!`.
- Added `labelslidergrid!`, a function to create an internally aligned grid of sliders with labels and value-labels.
- LAxis has attributes `xrectzoom` and `yrectzoom` that control if the rectangle zoom changes the respective dimension or not.

## Improvements & Backend Changes

- Cleaned up LSlider style and implementation, LSlider doesn't react while below other objects anymore
- MakieLayout Mouse event types are now enum instances for less compilation
- MakieLayout Mouse events store position in both data and pixel coordinates
- Aligned colors of LMenu, LSlider, LButton etc better

## Bugfixes

