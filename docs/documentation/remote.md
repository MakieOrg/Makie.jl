# Remote servers

Makie can be used remotely and it supports working headless systems (such as CI servers).

## GLMakie

For [GLMakie](https://github.com/JuliaPlots/GLMakie.jl) you can either use X11 forwarding to render on the local
host or use [VirtualGL](https://www.virtualgl.org/) to render on the remote server.

### GLMakie with X11 forwarding

In this scenario you need an X server on the remote and you will have to connect to the remote server with
```
ssh -X user@host
```
See [here](https://unix.stackexchange.com/questions/12755/how-to-forward-x-over-ssh-to-run-graphics-applications-remotely)
about more details about X11 forwarding.

### GLMakie with VirtualGL

The first step is to [install VirtualGL](https://cdn.rawgit.com/VirtualGL/virtualgl/2.6.3/doc/index.html#hd005) on the remote
server ([Linux only](https://virtualgl.org/Documentation/OSSupport)) and on the local client.
If you need to establish the connection to the server via a secondary intermediate server,
VirtualGL also needs to be installed there.
On the remote server you will need to [configure the VirtualGL server](https://cdn.rawgit.com/VirtualGL/virtualgl/2.6.5/doc/index.html#hd006).
Be sure to [check that the configuration is ok](https://cdn.rawgit.com/VirtualGL/virtualgl/2.6.5/doc/index.html#hd006002001).

After everything is set up, you can connect to the remote server via
```
/opt/VirtualGL/bin/vglconnect -s user@server
```
and then you will have to start julia via VirtualGL
```
/opt/VirtualGL/bin/vglrun julia
```

### GLMakie in CI

You can also use GLMakie on CI or servers without a GPU by using `xvfb` for software rendering.
This procedure is used in the [GLMakie tests](https://github.com/JuliaPlots/GLMakie.jl/blob/8954fc34354a09ceb11159a8e8e35429c05a710f/.github/workflows/ci.yml#L41-L42).

## WGLMakie

For WGLMakie, you can setup a server with JSServe and serve the content from a remote server.
This also works for creating interactive plots with Documenter.
Check out the [docs](http://juliaplots.org/WGLMakie.jl/stable/) for more details about this.

If you want to use WGLMakie in VS Code on a remote server, you will have to forward the port
used by WGLMakie in order for the plot pane integration to work.
If you don't need to change the port on which WGLMakie,
you will just have to [forward](https://code.visualstudio.com/docs/remote/ssh#_forwarding-a-port-creating-ssh-tunnel) the 9284 port.

If you want to change the port on which WGLMakie runs on the remote, say `8081`, you will have to use the following
```julia
using JSServe

JSServe.configure_server!(listen_port=8081)
```
before any plotting commands with WGLMakie.

If you also need to use a different port than `8081` on the _local_ machine, say `8080`,
you will also need to set the `forwarded_port` like this:
```julia
using JSServe

JSServe.configure_server!(listen_port=8081, forwarded_port=8080)
```

## CairoMakie

For CairoMakie there shouldn't be any difference in using it on a remote or locally.
