# Conversions

Every attribute has a conversion function, allowing attributes to take in rich input
types, but keep the variance low for the backends.
The conversions are overloadable as explained in [Extending](@ref), making it simple
to integrate custom types.

```@docs
to_color

to_colormap

to_colornorm

to_scale

to_offset

to_rotation

to_image

to_bool

to_index_buffer

to_positions

to_array

to_scalefunc

to_text

to_font

to_intensity

to_surface

to_spritemarker

to_static_vec

to_rotations

to_markersize2d
to_markersize3d

to_linestyle

to_normals

to_faces

to_attribut_id

to_mesh

to_float

to_spatial_order

to_interval

to_volume_algorithm

to_3floats
```
