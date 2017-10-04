const Theme = Scene

const default_theme = Theme(
    :color => UniqueColorIter(:YlGnBu),
    :scatter => Theme(
        :marker => Circle,
        :markersize => 5f0,
        :stroke_color => RGBA(0, 0, 0, 0),
        :stroke_thickness => 0f0,
        :glow_color => RGBA(0, 0, 0, 0),
        :glow_thickness => 0f0,
        :rotations => Billboard()
    )
)
