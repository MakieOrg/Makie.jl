using WGLMakie, AbstractPlotting, WebIO, JSCall
x = AbstractPlotting.Node(rand(4))
scatter(x)
x[] = rand(4)
