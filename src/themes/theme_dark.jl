function theme_dark()
    Attributes(
        backgroundcolor = :gray10,
        textcolor = :gray45,
        linecolor = :gray60,
        Axis = (
            backgroundcolor = :transparent,
            xgridcolor = (:white, 0.09),
            ygridcolor = (:white, 0.09),
            leftspinevisible = false,
            rightspinevisible = false,
            bottomspinevisible = false,
            topspinevisible = false,
            xminorticksvisible = false,
            yminorticksvisible = false,
            xticksvisible = false,
            yticksvisible = false,
            xlabelpadding = 3,
            ylabelpadding = 3
        ),
        Legend = (
            framevisible = false,
            padding = (0, 0, 0, 0),
        ),
        Axis3 = (
            xgridcolor = (:white, 0.09),
            ygridcolor = (:white, 0.09),
            zgridcolor = (:white, 0.09),
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
