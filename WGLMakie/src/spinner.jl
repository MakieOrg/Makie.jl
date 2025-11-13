# Spinner components for loading indication

"""
    CircleSpinner(; size=40, stroke=4, color="currentColor", background_color="rgba(0, 0, 0, 0.1)", duration=1)

A circular CSS spinner component that shows a loading animation.
This is the default spinner for WGLMakie scene loading.

# Arguments
- `size`: The diameter of the spinner in pixels (default: 40)
- `stroke`: The width of the spinner border in pixels (default: 4)
- `color`: The color of the spinning part (default: "currentColor")
- `background_color`: The color of the background circle (default: "rgba(0, 0, 0, 0.1)")
- `duration`: The speed of the rotation animation in seconds (default: 1)
"""
function CircleSpinner(; size=40, stroke=4, color="currentColor", background_color="rgba(0, 0, 0, 0.1)", duration=1)
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

    return DOM.div(styles; class="wglmakie-spinner")
end
