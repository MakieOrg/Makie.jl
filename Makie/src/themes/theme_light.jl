function theme_light()
    return Theme(
        textcolor = :gray50,
        Axis = (
            backgroundcolor = :transparent,
            xgridcolor = (:black, 0.07),
            ygridcolor = (:black, 0.07),
            leftspinevisible = false,
            rightspinevisible = false,
            bottomspinevisible = false,
            topspinevisible = false,
            xminorticksvisible = false,
            yminorticksvisible = false,
            xticksvisible = false,
            yticksvisible = false,
            xlabelpadding = 3,
            ylabelpadding = 3,
        ),
        Legend = (
            framevisible = false,
            padding = (0, 0, 0, 0),
        ),
        Axis3 = (
            xgridcolor = (:black, 0.07),
            ygridcolor = (:black, 0.07),
            zgridcolor = (:black, 0.07),
            xspinesvisible = false,
            yspinesvisible = false,
            zspinesvisible = false,
            xticksvisible = false,
            yticksvisible = false,
            zticksvisible = false,
        ),
        Colorbar = (
            ticksvisible = false,
            spinewidth = 0,
            ticklabelpad = 5,
        )
    )
end
