
Base.mimewritable(::MIME"text/plain", scene::Scene) = true

function Base.show(io::IO, m::MIME"text/plain", scene::Scene)
    print(io, summary(scene))
end
