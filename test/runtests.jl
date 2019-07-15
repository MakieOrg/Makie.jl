using WGLMakie, AbstractPlotting, WebIO, JSCall
x = AbstractPlotting.Node(rand(4))
s = scatter(x)
x[] = rand(4)
s[end].color = :green
x = surface(rand(4, 4))
x[end][1] = rand(4, 4)
