# defined in Makie
Base.@deprecate_binding Quaternionf Quaternionf
Base.@deprecate_binding RGBf RGBf
Base.@deprecate_binding RGBAf RGBAf

# defined in GeometryBasics and reexported by Makie
export Rectf, Rect2f, Rect2i, Rect3f, Rect3i, Rect3, Recti, Rectf, Rect2
export Vec4f, Vec3f, Vec2f, Point4f, Point3f, Point2f
