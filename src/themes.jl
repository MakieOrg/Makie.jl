const Theme = Scene

q1 = qrotation(Vec3f0(1, 0, 0), -0.5f0*pi)
q2 = qrotation(Vec3f0(0, 0, 1), 1f0*pi)
tickrotations = (
    qrotation(Vec3f0(0,0,1), -1.5pi),
    q2,
    qmul(qmul(q2, q1), qrotation(Vec3f0(0, 1, 0), 1pi))
)

tickalign = (
    (:hcenter, :left), # x axis
    (:right, :vcenter), # y axis
    (:right, :vcenter), # z axis
)

dark_text = RGBAf0(0.0, 0.0, 0.0, 0.4)
default_theme = Theme(
    :color => UniqueColorIter(:Set1),
    :linewidth => 1f0,
    :colormap => :YlGnBu,
    :colornorm => nothing, # nothing for calculating it from intensity
    :scatter => Theme(
        :marker => Circle,
        :markersize => 5f0,
        :stroke_color => RGBA(0, 0, 0, 0),
        :stroke_thickness => 0f0,
        :glow_color => RGBA(0, 0, 0, 0),
        :glow_thickness => 0f0,
        :rotations => Billboard()
    ),
    :lines => Theme(
        :linestyle => nothing,
    ),
    :mesh => Theme(
        :shading => true,
        :attribute_id => nothing
    ),
    :axis => Theme(
        :axisnames => map(x-> ("$x Axis", 0.1, dark_text, Vec4f0(0,0,0,1), (:center, :bottom)), (:X, :Y, :Z)),
        :visible => true,

        :showticks => ntuple(i-> true, 3),
        :tickfont => ntuple(i-> (0.1, RGBAf0(0.5, 0.5, 0.5, 0.6), tickrotations[i], tickalign[i]), 3),
        :showaxis => ntuple(i-> true, 3),
        :showgrid => ntuple(i-> true, 3),

        :scalefuncs => ntuple(i-> identity, 3),
        :gridcolors => ntuple(x-> RGBAf0(0.5, 0.5, 0.5, 0.4), 3),
        :axiscolors => ntuple(x-> dark_text, 3)
    )
)
