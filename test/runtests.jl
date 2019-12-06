using WGLMakie, AbstractPlotting, JSServe, Test

function test(session, req)
    return scatter(rand(10))
end

app = JSServe.Application(test, "127.0.0.1", 8081)

response = JSServe.HTTP.get("http://127.0.0.1:8081/")

@test response.status == 200

#TODO tests with chromium headless!
