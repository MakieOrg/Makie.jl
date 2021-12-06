using GLMakie, LinearAlgebra, GeometryBasics

begin
    scene = Scene(backgroundcolor=:gray, resolution=(500, 500))
    sub1 = Scene(scene, px_area = Rect2f(0, 0, 250, 500), backgroundcolor=:white, clear=true)
    scene
end


begin
    sub2 = Scene(scene, px_area = Rect2f(250, 0, 250, 500), backgroundcolor=(:gray, 0.5), clear=true, camera=nothing)
    scene
end

# By default, the scenes goes from -1 to 1.
# So to draw a rectangle outlining the screen, the following rectangle does the job:
lines!(sub1, Rect2f(-1, -1, 2, 2), linewidth=5)
# this is, because the projection matrix and view matrix is the identity matrix:
sub1.camera

# One can change the mapping, to e.g. draw from -3 to 5:
sub1.camera.projection[] = Makie.orthographicprojection(-3f0, 5f0, -3f0, 5f0, -100f0, 100f0)
# which changes the position of our rectangle:
scene

# one can also change it to a perspective, 3d projection
w, h = size(sub1)
sub1.camera.projection[] = Makie.perspectiveprojection(45f0, Float32(w / h), 0.1f0, 100f0)
# Now, we also need to change the view matrix, to "put" the camera into some place.
sub1.camera.view[] = Makie.lookat(Vec3f(10), Vec3f(0), Vec3f(0, 0, 1))

# One can also resize scenes dynamically:

sub2.px_area[] = Rect2i(125, 125, 250, 250)
lines!(sub2, Rect2f(-1, -1, 2, 2), linewidth=5)
sub2.clear = false
scene

# Without clear, this will create a see through scene...
# We give that new sub scene a 3d camera,
sub3 = Scene(sub2, camera=cam3d!, clear=false)
meshscatter!(sub3, rand(Point3f, 10))
center!(sub3)
scene

# this way we get an outline, that always strokes the parent scene, and then
# we can put a 3d scene inside of that.
