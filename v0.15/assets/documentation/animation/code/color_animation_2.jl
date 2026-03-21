# This file was generated, do not modify it. # hide
time = Node(0.0)
color_observable = @lift(RGBf($time, 0, 0))

fig = lines(0..10, sin, color = color_observable)

record(fig, "color_animation_2.mp4", timestamps; framerate = framerate) do t
    time[] = t
end
nothing # hide