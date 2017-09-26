function _show(io::IO, ::MIME"image/png", plt::Plot{GLVisualizeBackend})
    _display(plt, false)
    GLWindow.poll_glfw()
    if Base.n_avail(Reactive._messages) > 0
        Reactive.run_till_now()
    end
    yield()
    GLWindow.render_frame(GLWindow.rootscreen(plt.o))
    GLWindow.swapbuffers(plt.o)
    buff = GLWindow.screenbuffer(plt.o)
    png = map(RGB{U8}, buff)
    FileIO.save(FileIO.Stream(FileIO.DataFormat{:PNG}, io), png)
end
