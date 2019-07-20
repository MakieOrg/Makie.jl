using WGLMakie, AbstractPlotting, JSServe
sc = surface(0..1, 0..1, rand(4, 4));
global ss = nothing
function dom_handler(session, request)
    three, canvas = WGLMakie.three_display(session, sc)
    global ss = three
    canvas
end;
app = JSServe.Application(
    dom_handler,
    get(ENV, "WEBIO_SERVER_HOST_URL", "127.0.0.1"),
    parse(Int, get(ENV, "WEBIO_HTTP_PORT", "8081")),
    verbose = false
)
