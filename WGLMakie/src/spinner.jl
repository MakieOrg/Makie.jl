# Spinner components for loading indication

"""
    CircleSpinner(; size=40, stroke=4, color="currentColor", background_color="rgba(0, 0, 0, 0.1)", duration=1)

A circular CSS spinner component that shows a loading animation.
This is the default spinner for WGLMakie scene loading.

CircleSpinner is a struct that creates a fresh DOM element on each render via `Bonito.jsrender`,
ensuring that each scene gets its own spinner instance (avoiding shared DOM issues).

# Arguments
- `size`: The diameter of the spinner in pixels (default: 40)
- `stroke`: The width of the spinner border in pixels (default: 4)
- `color`: The color of the spinning part (default: "currentColor")
- `background_color`: The color of the background circle (default: "rgba(0, 0, 0, 0.1)")
- `duration`: The speed of the rotation animation in seconds (default: 1)

# Example
```julia
# Use default spinner
WGLMakie.activate!()

# Customize spinner appearance
spinner = WGLMakie.CircleSpinner(size=60, stroke=6, color="blue")
WGLMakie.activate!(; spinner=spinner)
```

# Custom Spinners

To create your own custom spinner, define a struct and implement `Bonito.jsrender`:

```julia
struct MySpinner
    message::String
end

function Bonito.jsrender(session::Session, spinner::MySpinner)
    styles = Bonito.Styles(...)
    return Bonito.jsrender(session, DOM.div(styles, spinner.message; class="wglmakie-spinner"))
end
```

The `wglmakie-spinner` class is required for WGLMakie to find and remove the spinner after loading.
"""
struct CircleSpinner
    size::Int
    stroke::Int
    color::String
    background_color::String
    duration::Float64
end

function CircleSpinner(;
    size::Int=40,
    stroke::Int=4,
    color::String="currentColor",
    background_color::String="rgba(0, 0, 0, 0.1)",
    duration::Real=1
)
    return CircleSpinner(size, stroke, color, background_color, Float64(duration))
end

function Bonito.jsrender(session::Bonito.Session, spinner::CircleSpinner)
    (; size, stroke, color, background_color, duration) = spinner

    keyframes = Bonito.CSS(
        "@keyframes wglmakie-spin",
        Bonito.CSS("0%", "transform" => "translate(-50%, -50%) rotate(0deg)"),
        Bonito.CSS("100%", "transform" => "translate(-50%, -50%) rotate(360deg)"),
    )

    styles = Bonito.Styles(
        Bonito.CSS(
            ".wglmakie-spinner",
            "position" => "absolute",
            "top" => "50%",
            "left" => "50%",
            "transform" => "translate(-50%, -50%)",
            "width" => "$(size)px",
            "height" => "$(size)px",
            "border" => "$(stroke)px solid $(background_color)",
            "border-top" => "$(stroke)px solid $(color)",
            "border-radius" => "50%",
            "animation" => "wglmakie-spin $(duration)s linear infinite",
            "z-index" => "1000",
            "pointer-events" => "none",
        ),
        keyframes,
    )

    return Bonito.jsrender(session, DOM.div(styles; class="wglmakie-spinner"))
end
