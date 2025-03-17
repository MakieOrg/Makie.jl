using WGLMakie, Bonito

begin
    f, ax, pl = scatter(rand(100), color=rand(100))
    ax2, pl2 = lines(f[1, 2], rand(100))
    Colorbar(f[1, 3], pl)
    display(f)
    println("##################################")
    resize!(f, 500, 500)
    msgs, msg = Bonito.collect_messages() do
        resize!(f, 1000, 600)
    end
end
# With lineindices + lastlen
"Send 154 messages with a total size of 27.395 KiB"
# Without sending lineindices + lastlen
"Send 154 messages with a total size of 26.797 KiB"
"Send 92 messages with a total size of 18.590 KiB"

payloads = getindex.(last.(msgs), "payload")
for m in payloads
    if m isa Vector{Vector{Any}} && m[1][1] isa String
        println(m)
    end
end


getindex.(last.(msgs), "payload") |> length
unique_msgs = getindex.(last.(msgs), "payload") |> unique
filter(x-> x)


using WGLMakie, Bonito
function test()
    rm(Bonito.bundle_path(WGLMakie.WGL))
    return scatter(1:4)
end
test()
