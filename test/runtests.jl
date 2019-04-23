using WGLMakie, AbstractPlotting
using Test

AbstractPlotting.set_theme!(resolution = (650, 300))

r = range(0, stop=5pi, length=100)
s = lines(r, sin.(r), linewidth = 3)
d, w = js_display(s);


<!DOCTYPE html>
<html lang="en">
<head>
	<title>three.js webgl - indexed instancing (single box), dynamic updates</title>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0">
	<style>
		body {
			color: #ffffff;
			font-family: Monospace;
			font-size: 13px;
			text-align: center;
			font-weight: bold;
			background-color: #000000;
			margin: 0px;
			overflow: hidden;
		}

		#info {
			position: absolute;
			top: 0px;
			width: 100%;
			padding: 5px;
		}

		a {
			color: #ffffff;
		}

		#webglmessage a {
			color: #da0;
		}

		#notSupported {
			width: 50%;
			margin: auto;
			border: 2px red solid;
			margin-top: 20px;
			padding: 10px;
		}
	</style>
</head>
<body>

	<div id="container"></div>
	<div id="info">
		<a href="http://threejs.org" target="_blank" rel="noopener">three.js</a> - indexed instancing (single box), dynamic updates
		<div id="notSupported" style="display:none">Sorry your graphics card + browser does not support hardware instancing</div>
	</div>

	<script src="../build/three.js"></script>

	<script src="js/WebGL.js"></script>
	<script src="js/libs/stats.min.js"></script>

	<script id="vertexShader" type="x-shader/x-vertex">

using FileIO
cd(joinpath(homedir(), ".julia", "dev", "GLMakie", "src", "GLVisualize", "assets"))
catmesh = load("cat.obj", GLNormalUVMesh)
texture = load("diffusemap.tga");
js_display(mesh(catmesh, color = texture));
