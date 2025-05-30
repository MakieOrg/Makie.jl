import{_ as e,C as t,c as d,o,aA as i,j as s,G as n,a as r,w as p}from"./chunks/framework.BPrVvvt3.js";const m=JSON.parse('{"title":"WGLMakie","description":"","frontmatter":{},"headers":[],"relativePath":"explanations/backends/wglmakie.md","filePath":"explanations/backends/wglmakie.md","lastUpdated":null}'),c={name:"explanations/backends/wglmakie.md"},h={class:"jldocstring custom-block",open:""};function k(j,a,g,y,u,E){const l=t("Badge");return o(),d("div",null,[a[4]||(a[4]=i('<h1 id="WGLMakie" tabindex="-1">WGLMakie <a class="header-anchor" href="#WGLMakie" aria-label="Permalink to &quot;WGLMakie {#WGLMakie}&quot;">​</a></h1><p><a href="https://github.com/MakieOrg/Makie.jl/tree/master/WGLMakie" target="_blank" rel="noreferrer">WGLMakie</a> is the web-based backend, which is mostly implemented in Julia right now. WGLMakie uses <a href="https://github.com/SimonDanisch/Bonito.jl" target="_blank" rel="noreferrer">Bonito</a> to generate the HTML and JavaScript for displaying the plots. On the JavaScript side, we use <a href="https://threejs.org/" target="_blank" rel="noreferrer">ThreeJS</a> and <a href="https://en.wikipedia.org/wiki/WebGL" target="_blank" rel="noreferrer">WebGL</a> to render the plots. Moving more of the implementation to JavaScript is currently the goal and will give us a better JavaScript API, and more interaction without a running Julia server.</p><div class="warning custom-block"><p class="custom-block-title">Warning</p><p>WGLMakie can be considered experimental because the JavaScript API isn&#39;t stable yet and the notebook integration isn&#39;t perfect yet, but all plot types should work, and therefore all recipes, but there are certain caveats</p></div><h4 id="Browser-Support" tabindex="-1">Browser Support <a class="header-anchor" href="#Browser-Support" aria-label="Permalink to &quot;Browser Support {#Browser-Support}&quot;">​</a></h4><h5 id="IJulia" tabindex="-1">IJulia <a class="header-anchor" href="#IJulia" aria-label="Permalink to &quot;IJulia {#IJulia}&quot;">​</a></h5><ul><li><p>Bonito now uses the IJulia connection, and therefore can be used even with complex proxy setup without any additional setup</p></li><li><p>reload of the page isn&#39;t supported, if you reload, you need to re-execute all cells and make sure that <code>Page()</code> is executed first.</p></li></ul><h4 id="JupyterHub-/-Jupyterlab-/-Binder" tabindex="-1">JupyterHub / Jupyterlab / Binder <a class="header-anchor" href="#JupyterHub-/-Jupyterlab-/-Binder" aria-label="Permalink to &quot;JupyterHub / Jupyterlab / Binder {#JupyterHub-/-Jupyterlab-/-Binder}&quot;">​</a></h4><ul><li>WGLMakie should mostly work with a websocket connection. Bonito tries to <a href="https://github.com/SimonDanisch/Bonito.jl/blob/master/src/server-defaults.jl" target="_blank" rel="noreferrer">infer the proxy setup</a> needed to connect to the julia process. On local jupyterlab instances, this should work without problem. On hosted instances one will likely need to have <a href="https://jupyter-server-proxy.readthedocs.io/en/latest/arbitrary-ports-hosts.html#with-jupyterhub" target="_blank" rel="noreferrer"><code>jupyter-server-proxy</code></a> installed, and then execute something like <code>Page(; listen_port=9091, proxy_url=&quot;&lt;jhub-instance&gt;.com/user/&lt;username&gt;/proxy/9091&quot;)</code>. Also see: <ul><li><p><a href="https://github.com/MakieOrg/Makie.jl/issues/2464" target="_blank" rel="noreferrer">issue #2464</a></p></li><li><p><a href="https://github.com/MakieOrg/Makie.jl/issues/2405" target="_blank" rel="noreferrer">issue #2405</a></p></li></ul></li></ul><h4 id="Pluto" tabindex="-1">Pluto <a class="header-anchor" href="#Pluto" aria-label="Permalink to &quot;Pluto {#Pluto}&quot;">​</a></h4><ul><li><p>still uses Bonito&#39;s Websocket connection, so needs extra setup for remote servers.</p></li><li><p>reload of the page isn&#39;t supported, if you reload, you need to re-execute all cells and make sure that <code>Page()</code> is executed first.</p></li><li><p>static html export not fully working yet</p></li></ul><h4 id="JuliaHub" tabindex="-1">JuliaHub <a class="header-anchor" href="#JuliaHub" aria-label="Permalink to &quot;JuliaHub {#JuliaHub}&quot;">​</a></h4><ul><li><p>VSCode in the browser should work out of the box.</p></li><li><p>Pluto in JuliaHub still has a <a href="https://github.com/SimonDanisch/Bonito.jl/issues/140" target="_blank" rel="noreferrer">problem</a> with the WebSocket connection. So, you will see a plot, but interaction doesn&#39;t work.</p></li></ul><h4 id="Browser-Support-2" tabindex="-1">Browser Support <a class="header-anchor" href="#Browser-Support-2" aria-label="Permalink to &quot;Browser Support {#Browser-Support-2}&quot;">​</a></h4><p>Some browsers may have only WebGL 1.0, or need extra steps to enable WebGL, but in general, all modern browsers on <a href="https://www.lambdatest.com/web-technologies/webgl2" target="_blank" rel="noreferrer">mobile and desktop should support WebGL 2.0</a>. Safari users may need to <a href="https://discussions.apple.com/thread/8655829" target="_blank" rel="noreferrer">enable</a> WebGL, though. If you end up stuck on WebGL 1.0, the main missing feature will be <code>volume</code> &amp; <code>contour(volume)</code>.</p><h2 id="Activation-and-screen-config" tabindex="-1">Activation and screen config <a class="header-anchor" href="#Activation-and-screen-config" aria-label="Permalink to &quot;Activation and screen config {#Activation-and-screen-config}&quot;">​</a></h2><p>Activate the backend by calling <code>WGLMakie.activate!()</code> with the following options:</p>',16)),s("details",h,[s("summary",null,[a[0]||(a[0]=s("a",{id:"WGLMakie.activate!",href:"#WGLMakie.activate!"},[s("span",{class:"jlbinding"},"WGLMakie.activate!")],-1)),a[1]||(a[1]=r()),n(l,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),a[3]||(a[3]=i('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">WGLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">activate!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; screen_config</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Sets WGLMakie as the currently active backend and also allows to quickly set the <code>screen_config</code>. Note, that the <code>screen_config</code> can also be set permanently via <code>Makie.set_theme!(WGLMakie=(screen_config...,))</code>.</p><p><strong>Arguments one can pass via <code>screen_config</code>:</strong></p><ul><li><p><code>framerate = 30</code>: Set framerate (frames per second) to a higher number for smoother animations, or to a lower to use less resources.</p></li><li><p><code>resize_to = nothing</code>: Resize the canvas to the parent element with <code>resize_to=:parent</code>, or to the body if <code>resize_to = :body</code>. The default <code>nothing</code>, will resize nothing. A tuple is allowed too, with the same values just for width/height.</p></li></ul>',4)),n(l,{type:"info",class:"source-link",text:"source"},{default:p(()=>a[2]||(a[2]=[s("a",{href:"https://github.com/MakieOrg/Makie.jl/blob/c7f9fc94fa1b4062a2aa343353029eae53c2faa4/WGLMakie/src/WGLMakie.jl#L48-L57",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1,__:[2]})]),a[5]||(a[5]=i(`<h2 id="Output" tabindex="-1">Output <a class="header-anchor" href="#Output" aria-label="Permalink to &quot;Output {#Output}&quot;">​</a></h2><p>You can use Bonito and WGLMakie in Pluto, IJulia, Webpages and Documenter to create interactive apps and dashboards, serve them on live webpages, or export them to static HTML.</p><p>This tutorial will run through the different modes and what kind of limitations to expect.</p><h3 id="Page" tabindex="-1">Page <a class="header-anchor" href="#Page" aria-label="Permalink to &quot;Page {#Page}&quot;">​</a></h3><p><code>Page()</code> can be used to reset the Bonito state needed for multipage output like it&#39;s the case for <code>Documenter</code> or the various notebooks (IJulia/Pluto/etc). Previously, it was necessary to always insert and display the <code>Page</code> call in notebooks, but now the call to <code>Page()</code> is optional and doesn&#39;t need to be displayed. What it does is purely reset the state for a new multi-page output, which is usually the case for <code>Documenter</code>, which creates multiple pages in one Julia session, or you can use it to reset the state in notebooks, e.g. after a page reload. <code>Page(exportable=true, offline=true)</code> can be used to force inlining all data &amp; js dependencies, so that everything can be loaded in a single HTML object without a running Julia process. The defaults should already be chosen this way for e.g. Documenter, so this should mostly be used for e.g. <code>Pluto</code> offline export (which is currently not fully supported, but should be soon).</p><p>Here is an example of how to use this in Franklin:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> WGLMakie</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Bonito, Markdown</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Page</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># for Franklin, you still need to configure</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">WGLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">activate!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Makie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">inline!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">true</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># Make sure to inline plots into Documenter output!</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatter</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, color</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div><div>
  <div class="bonito-fragment" id="c9a1dee3-b4cc-498d-bfd8-0399135f358f" data-jscall-id="root">
    <div>
      <script src="bonito/js/Bonito.bundled15432232505923397289.js" type="module"><\/script>
      <style></style>
    </div>
    <div>
      <script type="module">Bonito.lock_loading(() => Bonito.init_session('c9a1dee3-b4cc-498d-bfd8-0399135f358f', null, 'root', false))<\/script>
      <span></span>
    </div>
  </div>
  <div class="bonito-fragment" id="381bf4a4-a12a-43b7-bf3d-b09581ae204b" data-jscall-id="subsession-application-dom">
    <div>
      <style></style>
    </div>
    <div>
      <script type="module">Bonito.lock_loading(() => Bonito.init_session('381bf4a4-a12a-43b7-bf3d-b09581ae204b', null, 'sub', false))<\/script>
      <pre class="backtrace" style="overflow-x: auto;" data-jscall-id="1">
        <h3 style="color: red;" data-jscall-id="2">Failed to resolve wgl_renderobject:
&#91;ComputeEdge&#93; wgl_renderobject, wgl_update_obs &#61; #71&#40;&#40;positions_transformed_f32c, vertex_color, uniform_color, uniform_colormap, uniform_colorrange, nan_color, highclip_color, lowclip_color, pattern, strokewidth, glowwidth, glowcolor, converted_rotation, converted_strokecolor, marker_offset, sdf_marker_shape, glyph_data, depth_shift, atlas, markerspace, visible, transform_marker, f32c_scale, model_f32c, uniform_clip_planes, uniform_num_clip_planes, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:110
&#91;ComputeEdge&#93; glyph_data &#61; #86&#40;&#40;glyphindices, font_per_char, glyph_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:332
&#91;ComputeEdge&#93; glyph_scales &#61; #85&#40;&#40;glyphindices, text_blocks, text_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329
  with edge inputs:
    glyphindices &#61; UInt64&#91;&#93;
    text_blocks &#61; UnitRange&#123;Int64&#125;&#91;1:0&#93;
    text_scales &#61; Vec&#123;2, Float32&#125;&#91;&#93;
Triggered by update of:
  position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor or strokewidth
Due to ERROR: MethodError: no method matching map_per_glyph&#40;::Vector&#123;UInt64&#125;, ::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Type&#123;Vec&#123;2, Float32&#125;&#125;, ::Vector&#123;Vec&#123;2, Float32&#125;&#125;&#41;
The function &#96;map_per_glyph&#96; exists, but no method is defined for this combination of argument types.

Closest candidates are:
  map_per_glyph&#40;&#33;Matched::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Any, ::Any&#41;
   &#64; Makie ~/work/Makie.jl/Makie.jl/src/basic_recipes/text.jl:118
</h3>
        <span data-jscall-id="3">Stacktrace:</span>
        <br data-jscall-id="4" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="5">  &#91;1&#93; &#40;::WGLMakie.var&#34;#85#87&#34;&#41;&#40;::&#64;NamedTuple&#123;…&#125;, changed::&#64;NamedTuple&#123;…&#125;, last::Nothing&#41;</span>
        <br data-jscall-id="6" />
        <span data-jscall-id="7">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329</span>
        <br data-jscall-id="8" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="9">  &#91;2&#93; ComputePipeline.TypedEdge&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
        <br data-jscall-id="10" />
        <span data-jscall-id="11">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:120</span>
        <br data-jscall-id="12" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="13">  &#91;3&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
        <br data-jscall-id="14" />
        <span data-jscall-id="15">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:568</span>
        <br data-jscall-id="16" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="17">  &#91;4&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
        <br data-jscall-id="18" />
        <span data-jscall-id="19">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
        <br data-jscall-id="20" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="21">  &#91;5&#93; foreach</span>
        <br data-jscall-id="22" />
        <span data-jscall-id="23">    &#64; 
          <a href="vscode://file/./abstractarray.jl:3187" data-jscall-id="24">./abstractarray.jl:3187</a> &#91;inlined&#93;
        </span>
        <br data-jscall-id="25" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="26">  &#91;6&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
        <br data-jscall-id="27" />
        <span data-jscall-id="28">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:563</span>
        <br data-jscall-id="29" />
        <span data-jscall-id="30">--- the above 3 lines are repeated 1 more time ---</span>
        <br data-jscall-id="31" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="32"> &#91;10&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
        <br data-jscall-id="33" />
        <span data-jscall-id="34">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
        <br data-jscall-id="35" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="36"> &#91;11&#93; resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
        <br data-jscall-id="37" />
        <span data-jscall-id="38">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:546</span>
        <br data-jscall-id="39" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="40"> &#91;12&#93; getindex</span>
        <br data-jscall-id="41" />
        <span data-jscall-id="42">    &#64; ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:466 &#91;inlined&#93;</span>
        <br data-jscall-id="43" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="44"> &#91;13&#93; create_wgl_renderobject&#40;callback::typeof&#40;WGLMakie.scatter_program&#41;, attr::ComputePipeline.ComputeGraph, inputs::Vector&#123;…&#125;&#41;</span>
        <br data-jscall-id="45" />
        <span data-jscall-id="46">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:130</span>
        <br data-jscall-id="47" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="48"> &#91;14&#93; create_shader&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;2, Float32&#125;&#125;&#125;&#125;&#41;</span>
        <br data-jscall-id="49" />
        <span data-jscall-id="50">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:369</span>
        <br data-jscall-id="51" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="52"> &#91;15&#93; serialize_three&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;2, Float32&#125;&#125;&#125;&#125;&#41;</span>
        <br data-jscall-id="53" />
        <span data-jscall-id="54">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:8</span>
        <br data-jscall-id="55" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="56"> &#91;16&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
        <br data-jscall-id="57" />
        <span data-jscall-id="58">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:230</span>
        <br data-jscall-id="59" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="60"> &#91;17&#93; serialize_plots</span>
        <br data-jscall-id="61" />
        <span data-jscall-id="62">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:227 &#91;inlined&#93;</span>
        <br data-jscall-id="63" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="64"> &#91;18&#93; serialize_scene&#40;scene::Scene&#41;</span>
        <br data-jscall-id="65" />
        <span data-jscall-id="66">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:207</span>
        <br data-jscall-id="67" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="68"> &#91;19&#93; &#40;::WGLMakie.var&#34;#47#54&#34;&#41;&#40;child::Scene&#41;</span>
        <br data-jscall-id="69" />
        <span data-jscall-id="70">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
        <br data-jscall-id="71" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="72"> &#91;20&#93; iterate</span>
        <br data-jscall-id="73" />
        <span data-jscall-id="74">    &#64; 
          <a href="vscode://file/./generator.jl:48" data-jscall-id="75">./generator.jl:48</a> &#91;inlined&#93;
        </span>
        <br data-jscall-id="76" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="77"> &#91;21&#93; _collect&#40;c::Vector&#123;…&#125;, itr::Base.Generator&#123;…&#125;, ::Base.EltypeUnknown, isz::Base.HasShape&#123;…&#125;&#41;</span>
        <br data-jscall-id="78" />
        <span data-jscall-id="79">    &#64; Base 
          <a href="vscode://file/./array.jl:811" data-jscall-id="80">./array.jl:811</a>
        </span>
        <br data-jscall-id="81" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="82"> &#91;22&#93; collect_similar</span>
        <br data-jscall-id="83" />
        <span data-jscall-id="84">    &#64; 
          <a href="vscode://file/./array.jl:720" data-jscall-id="85">./array.jl:720</a> &#91;inlined&#93;
        </span>
        <br data-jscall-id="86" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="87"> &#91;23&#93; map</span>
        <br data-jscall-id="88" />
        <span data-jscall-id="89">    &#64; 
          <a href="vscode://file/./abstractarray.jl:3371" data-jscall-id="90">./abstractarray.jl:3371</a> &#91;inlined&#93;
        </span>
        <br data-jscall-id="91" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="92"> &#91;24&#93; serialize_scene&#40;scene::Scene&#41;</span>
        <br data-jscall-id="93" />
        <span data-jscall-id="94">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
        <br data-jscall-id="95" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="96"> &#91;25&#93; three_display&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
        <br data-jscall-id="97" />
        <span data-jscall-id="98">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/three_plot.jl:33</span>
        <br data-jscall-id="99" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="100"> &#91;26&#93; render_with_init&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
        <br data-jscall-id="101" />
        <span data-jscall-id="102">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:91</span>
        <br data-jscall-id="103" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="104"> &#91;27&#93; #18</span>
        <br data-jscall-id="105" />
        <span data-jscall-id="106">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:208 &#91;inlined&#93;</span>
        <br data-jscall-id="107" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="108"> &#91;28&#93; &#40;::Bonito.var&#34;#10#16&#34;&#123;…&#125;&#41;&#40;session::Bonito.Session&#123;…&#125;, request::HTTP.Messages.Request&#41;</span>
        <br data-jscall-id="109" />
        <span data-jscall-id="110">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/types.jl:362</span>
        <br data-jscall-id="111" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="112"> &#91;29&#93; #invokelatest#2</span>
        <br data-jscall-id="113" />
        <span data-jscall-id="114">    &#64; 
          <a href="vscode://file/./essentials.jl:1055" data-jscall-id="115">./essentials.jl:1055</a> &#91;inlined&#93;
        </span>
        <br data-jscall-id="116" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="117"> &#91;30&#93; invokelatest</span>
        <br data-jscall-id="118" />
        <span data-jscall-id="119">    &#64; 
          <a href="vscode://file/./essentials.jl:1052" data-jscall-id="120">./essentials.jl:1052</a> &#91;inlined&#93;
        </span>
        <br data-jscall-id="121" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="122"> &#91;31&#93; rendered_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App, target::HTTP.Messages.Request&#41;</span>
        <br data-jscall-id="123" />
        <span data-jscall-id="124">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/app.jl:42</span>
        <br data-jscall-id="125" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="126"> &#91;32&#93; rendered_dom</span>
        <br data-jscall-id="127" />
        <span data-jscall-id="128">    &#64; ~/.julia/packages/Bonito/PiA4w/src/app.jl:39 &#91;inlined&#93;</span>
        <br data-jscall-id="129" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="130"> &#91;33&#93; session_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App; init::Bool, html_document::Bool&#41;</span>
        <br data-jscall-id="131" />
        <span data-jscall-id="132">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/session.jl:363</span>
        <br data-jscall-id="133" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="134"> &#91;34&#93; session_dom</span>
        <br data-jscall-id="135" />
        <span data-jscall-id="136">    &#64; ~/.julia/packages/Bonito/PiA4w/src/session.jl:362 &#91;inlined&#93;</span>
        <br data-jscall-id="137" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="138"> &#91;35&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App; parent::Nothing&#41;</span>
        <br data-jscall-id="139" />
        <span data-jscall-id="140">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:79</span>
        <br data-jscall-id="141" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="142"> &#91;36&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App&#41;</span>
        <br data-jscall-id="143" />
        <span data-jscall-id="144">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:63</span>
        <br data-jscall-id="145" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="146"> &#91;37&#93; show</span>
        <br data-jscall-id="147" />
        <span data-jscall-id="148">    &#64; ~/.julia/packages/Bonito/PiA4w/src/display.jl:97 &#91;inlined&#93;</span>
        <br data-jscall-id="149" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="150"> &#91;38&#93; backend_show&#40;screen::WGLMakie.Screen, io::IOContext&#123;IOBuffer&#125;, m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, scene::Scene&#41;</span>
        <br data-jscall-id="151" />
        <span data-jscall-id="152">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:210</span>
        <br data-jscall-id="153" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="154"> &#91;39&#93; show&#40;io::IOContext&#123;…&#125;, m::MIME&#123;…&#125;, figlike::Makie.FigureAxisPlot; backend::Module, update::Bool&#41;</span>
        <br data-jscall-id="155" />
        <span data-jscall-id="156">    &#64; Makie ~/work/Makie.jl/Makie.jl/src/display.jl:254</span>
        <br data-jscall-id="157" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="158"> &#91;40&#93; show</span>
        <br data-jscall-id="159" />
        <span data-jscall-id="160">    &#64; ~/work/Makie.jl/Makie.jl/src/display.jl:243 &#91;inlined&#93;</span>
        <br data-jscall-id="161" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="162"> &#91;41&#93; __binrepr&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Makie.FigureAxisPlot, context::Pair&#123;Symbol, Bool&#125;&#41;</span>
        <br data-jscall-id="163" />
        <span data-jscall-id="164">    &#64; Base.Multimedia 
          <a href="vscode://file/./multimedia.jl:173" data-jscall-id="165">./multimedia.jl:173</a>
        </span>
        <br data-jscall-id="166" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="167"> &#91;42&#93; _textrepr</span>
        <br data-jscall-id="168" />
        <span data-jscall-id="169">    &#64; 
          <a href="vscode://file/./multimedia.jl:163" data-jscall-id="170">./multimedia.jl:163</a> &#91;inlined&#93;
        </span>
        <br data-jscall-id="171" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="172"> &#91;43&#93; stringmime&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Makie.FigureAxisPlot; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
        <br data-jscall-id="173" />
        <span data-jscall-id="174">    &#64; Base64 /opt/hostedtoolcache/julia/1.11.5/x64/share/julia/stdlib/v1.11/Base64/src/Base64.jl:44</span>
        <br data-jscall-id="175" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="176"> &#91;44&#93; display_dict&#40;x::Makie.FigureAxisPlot; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
        <br data-jscall-id="177" />
        <span data-jscall-id="178">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/utilities/utilities.jl:576</span>
        <br data-jscall-id="179" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="180"> &#91;45&#93; invokelatest&#40;::Any, ::Any, ::Vararg&#123;Any&#125;; kwargs::&#64;Kwargs&#123;context::Pair&#123;Symbol, Bool&#125;&#125;&#41;</span>
        <br data-jscall-id="181" />
        <span data-jscall-id="182">    &#64; Base 
          <a href="vscode://file/./essentials.jl:1057" data-jscall-id="183">./essentials.jl:1057</a>
        </span>
        <br data-jscall-id="184" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="185"> &#91;46&#93; runner&#40;::Type&#123;…&#125;, node::MarkdownAST.Node&#123;…&#125;, page::Documenter.Page, doc::Documenter.Document&#41;</span>
        <br data-jscall-id="186" />
        <span data-jscall-id="187">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:885</span>
        <br data-jscall-id="188" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="189"> &#91;47&#93; dispatch&#40;::Type&#123;Documenter.Expanders.ExpanderPipeline&#125;, ::MarkdownAST.Node&#123;Nothing&#125;, ::Vararg&#123;Any&#125;&#41;</span>
        <br data-jscall-id="190" />
        <span data-jscall-id="191">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
        <br data-jscall-id="192" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="193"> &#91;48&#93; expand&#40;doc::Documenter.Document&#41;</span>
        <br data-jscall-id="194" />
        <span data-jscall-id="195">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:59</span>
        <br data-jscall-id="196" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="197"> &#91;49&#93; runner&#40;::Type&#123;Documenter.Builder.ExpandTemplates&#125;, doc::Documenter.Document&#41;</span>
        <br data-jscall-id="198" />
        <span data-jscall-id="199">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/builder_pipeline.jl:224</span>
        <br data-jscall-id="200" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="201"> &#91;50&#93; dispatch&#40;::Type&#123;Documenter.Builder.DocumentPipeline&#125;, x::Documenter.Document&#41;</span>
        <br data-jscall-id="202" />
        <span data-jscall-id="203">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
        <br data-jscall-id="204" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="205"> &#91;51&#93; #88</span>
        <br data-jscall-id="206" />
        <span data-jscall-id="207">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:275 &#91;inlined&#93;</span>
        <br data-jscall-id="208" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="209"> &#91;52&#93; withenv&#40;::Documenter.var&#34;#88#90&#34;&#123;Documenter.Document&#125;, ::Pair&#123;String, Nothing&#125;, ::Vararg&#123;Pair&#123;String, Nothing&#125;&#125;&#41;</span>
        <br data-jscall-id="210" />
        <span data-jscall-id="211">    &#64; Base 
          <a href="vscode://file/./env.jl:265" data-jscall-id="212">./env.jl:265</a>
        </span>
        <br data-jscall-id="213" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="214"> &#91;53&#93; #87</span>
        <br data-jscall-id="215" />
        <span data-jscall-id="216">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:274 &#91;inlined&#93;</span>
        <br data-jscall-id="217" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="218"> &#91;54&#93; cd&#40;f::Documenter.var&#34;#87#89&#34;&#123;Documenter.Document&#125;, dir::String&#41;</span>
        <br data-jscall-id="219" />
        <span data-jscall-id="220">    &#64; Base.Filesystem 
          <a href="vscode://file/./file.jl:112" data-jscall-id="221">./file.jl:112</a>
        </span>
        <br data-jscall-id="222" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="223"> &#91;55&#93; makedocs&#40;; debug::Bool, format::MarkdownVitepress, kwargs::&#64;Kwargs&#123;…&#125;&#41;</span>
        <br data-jscall-id="224" />
        <span data-jscall-id="225">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:273</span>
        <br data-jscall-id="226" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="227"> &#91;56&#93; make_docs&#40;; pages::Vector&#123;Pair&#123;String, Any&#125;&#125;&#41;</span>
        <br data-jscall-id="228" />
        <span data-jscall-id="229">    &#64; Main ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:189</span>
        <br data-jscall-id="230" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="231"> &#91;57&#93; top-level scope</span>
        <br data-jscall-id="232" />
        <span data-jscall-id="233">    &#64; ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:205</span>
        <br data-jscall-id="234" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="235"> &#91;58&#93; include&#40;mod::Module, _path::String&#41;</span>
        <br data-jscall-id="236" />
        <span data-jscall-id="237">    &#64; Base 
          <a href="vscode://file/./Base.jl:557" data-jscall-id="238">./Base.jl:557</a>
        </span>
        <br data-jscall-id="239" />
        <span style="color: darkred; font-weight: bold;" data-jscall-id="240"> &#91;59&#93; exec_options&#40;opts::Base.JLOptions&#41;</span>
        <br data-jscall-id="241" />
        <span data-jscall-id="242">    &#64; Base 
          <a href="vscode://file/./client.jl:323" data-jscall-id="243">./client.jl:323</a>
        </span>
        <br data-jscall-id="244" />
      </pre>
    </div>
  </div>
</div></div><p>As you can see, the output is completely static, because we don&#39;t have a running Julia server, as it would be the case with e.g. Pluto. To make the plot interactive, we will need to write more parts of WGLMakie in JS, which is an ongoing effort. As you can see, the interactivity already keeps working for 3D:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">N </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 60</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> xy_data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x, y)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    r </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> sqrt</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">^</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> +</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> y</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">^</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    r </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">==</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 0.0</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> ?</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 1f0</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> :</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">sin</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(r)</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">/</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">r)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">l </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> range</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, stop </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, length </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> N)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">z </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Float32[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">xy_data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x, y) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> x </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> l, y </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> l]</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">surface</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    -</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">..</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">..</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, z,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :Spectral</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div><div class="bonito-fragment" id="b0956896-1a21-4aa8-9585-b07cac470764" data-jscall-id="subsession-application-dom">
  <div>
    <style></style>
  </div>
  <div>
    <script type="module">Bonito.lock_loading(() => Bonito.init_session('b0956896-1a21-4aa8-9585-b07cac470764', null, 'sub', false))<\/script>
    <pre class="backtrace" style="overflow-x: auto;" data-jscall-id="245">
      <h3 style="color: red;" data-jscall-id="246">Failed to resolve wgl_renderobject:
&#91;ComputeEdge&#93; wgl_renderobject, wgl_update_obs &#61; #71&#40;&#40;positions_transformed_f32c, vertex_color, uniform_color, uniform_colormap, uniform_colorrange, nan_color, highclip_color, lowclip_color, pattern, strokewidth, glowwidth, glowcolor, converted_rotation, converted_strokecolor, marker_offset, sdf_marker_shape, glyph_data, depth_shift, atlas, markerspace, visible, transform_marker, f32c_scale, model_f32c, uniform_clip_planes, uniform_num_clip_planes, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:110
&#91;ComputeEdge&#93; glyph_data &#61; #86&#40;&#40;glyphindices, font_per_char, glyph_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:332
&#91;ComputeEdge&#93; glyph_scales &#61; #85&#40;&#40;glyphindices, text_blocks, text_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329
  with edge inputs:
    glyphindices &#61; UInt64&#91;0x000000000000000e, 0x0000000000000012, 0x000000000000000f, 0x0000000000000011, 0x000000000000000e, 0x0000000000000011, 0x000000000000000f, 0x0000000000000016, 0x0000000000000011, 0x000000000000000f  …  0x0000000000000016, 0x0000000000000011, 0x000000000000000f, 0x0000000000000016, 0x0000000000000011, 0x0000000000000011, 0x000000000000000f, 0x0000000000000018, 0x0000000000000016, 0x000000000000005b&#93;
    text_blocks &#61; UnitRange&#123;Int64&#125;&#91;1:4, 5:8, 9:11, 12:14, 15:17, 18:18, 19:22, 23:26, 27:29, 30:32, 33:35, 36:36, 37:40, 41:44, 45:48, 49:52, 53:53&#93;
    text_scales &#61; Vec&#123;2, Float32&#125;&#91;&#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;  …  &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.07246046, 0.07246046&#93;, &#91;0.086952545, 0.086952545&#93;&#93;
Triggered by update of:
  position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor or strokewidth
Due to ERROR: MethodError: no method matching map_per_glyph&#40;::Vector&#123;UInt64&#125;, ::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Type&#123;Vec&#123;2, Float32&#125;&#125;, ::Vector&#123;Vec&#123;2, Float32&#125;&#125;&#41;
The function &#96;map_per_glyph&#96; exists, but no method is defined for this combination of argument types.

Closest candidates are:
  map_per_glyph&#40;&#33;Matched::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Any, ::Any&#41;
   &#64; Makie ~/work/Makie.jl/Makie.jl/src/basic_recipes/text.jl:118
</h3>
      <span data-jscall-id="247">Stacktrace:</span>
      <br data-jscall-id="248" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="249">  &#91;1&#93; &#40;::WGLMakie.var&#34;#85#87&#34;&#41;&#40;::&#64;NamedTuple&#123;…&#125;, changed::&#64;NamedTuple&#123;…&#125;, last::Nothing&#41;</span>
      <br data-jscall-id="250" />
      <span data-jscall-id="251">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329</span>
      <br data-jscall-id="252" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="253">  &#91;2&#93; ComputePipeline.TypedEdge&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="254" />
      <span data-jscall-id="255">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:120</span>
      <br data-jscall-id="256" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="257">  &#91;3&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="258" />
      <span data-jscall-id="259">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:568</span>
      <br data-jscall-id="260" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="261">  &#91;4&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="262" />
      <span data-jscall-id="263">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="264" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="265">  &#91;5&#93; foreach</span>
      <br data-jscall-id="266" />
      <span data-jscall-id="267">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3187" data-jscall-id="268">./abstractarray.jl:3187</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="269" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="270">  &#91;6&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="271" />
      <span data-jscall-id="272">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:563</span>
      <br data-jscall-id="273" />
      <span data-jscall-id="274">--- the above 3 lines are repeated 1 more time ---</span>
      <br data-jscall-id="275" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="276"> &#91;10&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="277" />
      <span data-jscall-id="278">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="279" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="280"> &#91;11&#93; resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="281" />
      <span data-jscall-id="282">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:546</span>
      <br data-jscall-id="283" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="284"> &#91;12&#93; getindex</span>
      <br data-jscall-id="285" />
      <span data-jscall-id="286">    &#64; ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:466 &#91;inlined&#93;</span>
      <br data-jscall-id="287" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="288"> &#91;13&#93; create_wgl_renderobject&#40;callback::typeof&#40;WGLMakie.scatter_program&#41;, attr::ComputePipeline.ComputeGraph, inputs::Vector&#123;…&#125;&#41;</span>
      <br data-jscall-id="289" />
      <span data-jscall-id="290">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:130</span>
      <br data-jscall-id="291" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="292"> &#91;14&#93; create_shader&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;3, Float32&#125;&#125;&#125;&#125;&#41;</span>
      <br data-jscall-id="293" />
      <span data-jscall-id="294">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:369</span>
      <br data-jscall-id="295" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="296"> &#91;15&#93; serialize_three&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;3, Float32&#125;&#125;&#125;&#125;&#41;</span>
      <br data-jscall-id="297" />
      <span data-jscall-id="298">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:8</span>
      <br data-jscall-id="299" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="300"> &#91;16&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
      <br data-jscall-id="301" />
      <span data-jscall-id="302">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:230</span>
      <br data-jscall-id="303" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="304"> &#91;17&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
      <br data-jscall-id="305" />
      <span data-jscall-id="306">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:235</span>
      <br data-jscall-id="307" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="308"> &#91;18&#93; serialize_plots</span>
      <br data-jscall-id="309" />
      <span data-jscall-id="310">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:227 &#91;inlined&#93;</span>
      <br data-jscall-id="311" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="312"> &#91;19&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="313" />
      <span data-jscall-id="314">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:207</span>
      <br data-jscall-id="315" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="316"> &#91;20&#93; &#40;::WGLMakie.var&#34;#47#54&#34;&#41;&#40;child::Scene&#41;</span>
      <br data-jscall-id="317" />
      <span data-jscall-id="318">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="319" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="320"> &#91;21&#93; iterate</span>
      <br data-jscall-id="321" />
      <span data-jscall-id="322">    &#64; 
        <a href="vscode://file/./generator.jl:48" data-jscall-id="323">./generator.jl:48</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="324" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="325"> &#91;22&#93; _collect&#40;c::Vector&#123;…&#125;, itr::Base.Generator&#123;…&#125;, ::Base.EltypeUnknown, isz::Base.HasShape&#123;…&#125;&#41;</span>
      <br data-jscall-id="326" />
      <span data-jscall-id="327">    &#64; Base 
        <a href="vscode://file/./array.jl:811" data-jscall-id="328">./array.jl:811</a>
      </span>
      <br data-jscall-id="329" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="330"> &#91;23&#93; collect_similar</span>
      <br data-jscall-id="331" />
      <span data-jscall-id="332">    &#64; 
        <a href="vscode://file/./array.jl:720" data-jscall-id="333">./array.jl:720</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="334" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="335"> &#91;24&#93; map</span>
      <br data-jscall-id="336" />
      <span data-jscall-id="337">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3371" data-jscall-id="338">./abstractarray.jl:3371</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="339" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="340"> &#91;25&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="341" />
      <span data-jscall-id="342">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="343" />
      <span data-jscall-id="344">--- the above 6 lines are repeated 1 more time ---</span>
      <br data-jscall-id="345" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="346"> &#91;32&#93; three_display&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="347" />
      <span data-jscall-id="348">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/three_plot.jl:33</span>
      <br data-jscall-id="349" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="350"> &#91;33&#93; render_with_init&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="351" />
      <span data-jscall-id="352">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:91</span>
      <br data-jscall-id="353" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="354"> &#91;34&#93; #18</span>
      <br data-jscall-id="355" />
      <span data-jscall-id="356">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:208 &#91;inlined&#93;</span>
      <br data-jscall-id="357" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="358"> &#91;35&#93; &#40;::Bonito.var&#34;#10#16&#34;&#123;…&#125;&#41;&#40;session::Bonito.Session&#123;…&#125;, request::HTTP.Messages.Request&#41;</span>
      <br data-jscall-id="359" />
      <span data-jscall-id="360">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/types.jl:362</span>
      <br data-jscall-id="361" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="362"> &#91;36&#93; #invokelatest#2</span>
      <br data-jscall-id="363" />
      <span data-jscall-id="364">    &#64; 
        <a href="vscode://file/./essentials.jl:1055" data-jscall-id="365">./essentials.jl:1055</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="366" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="367"> &#91;37&#93; invokelatest</span>
      <br data-jscall-id="368" />
      <span data-jscall-id="369">    &#64; 
        <a href="vscode://file/./essentials.jl:1052" data-jscall-id="370">./essentials.jl:1052</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="371" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="372"> &#91;38&#93; rendered_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App, target::HTTP.Messages.Request&#41;</span>
      <br data-jscall-id="373" />
      <span data-jscall-id="374">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/app.jl:42</span>
      <br data-jscall-id="375" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="376"> &#91;39&#93; rendered_dom</span>
      <br data-jscall-id="377" />
      <span data-jscall-id="378">    &#64; ~/.julia/packages/Bonito/PiA4w/src/app.jl:39 &#91;inlined&#93;</span>
      <br data-jscall-id="379" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="380"> &#91;40&#93; session_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App; init::Bool, html_document::Bool&#41;</span>
      <br data-jscall-id="381" />
      <span data-jscall-id="382">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/session.jl:363</span>
      <br data-jscall-id="383" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="384"> &#91;41&#93; session_dom</span>
      <br data-jscall-id="385" />
      <span data-jscall-id="386">    &#64; ~/.julia/packages/Bonito/PiA4w/src/session.jl:362 &#91;inlined&#93;</span>
      <br data-jscall-id="387" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="388"> &#91;42&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App; parent::Bonito.Session&#123;Bonito.NoConnection&#125;&#41;</span>
      <br data-jscall-id="389" />
      <span data-jscall-id="390">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:70</span>
      <br data-jscall-id="391" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="392"> &#91;43&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App&#41;</span>
      <br data-jscall-id="393" />
      <span data-jscall-id="394">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:63</span>
      <br data-jscall-id="395" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="396"> &#91;44&#93; show</span>
      <br data-jscall-id="397" />
      <span data-jscall-id="398">    &#64; ~/.julia/packages/Bonito/PiA4w/src/display.jl:97 &#91;inlined&#93;</span>
      <br data-jscall-id="399" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="400"> &#91;45&#93; backend_show&#40;screen::WGLMakie.Screen, io::IOContext&#123;IOBuffer&#125;, m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="401" />
      <span data-jscall-id="402">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:210</span>
      <br data-jscall-id="403" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="404"> &#91;46&#93; show&#40;io::IOContext&#123;…&#125;, m::MIME&#123;…&#125;, figlike::Makie.FigureAxisPlot; backend::Module, update::Bool&#41;</span>
      <br data-jscall-id="405" />
      <span data-jscall-id="406">    &#64; Makie ~/work/Makie.jl/Makie.jl/src/display.jl:254</span>
      <br data-jscall-id="407" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="408"> &#91;47&#93; show</span>
      <br data-jscall-id="409" />
      <span data-jscall-id="410">    &#64; ~/work/Makie.jl/Makie.jl/src/display.jl:243 &#91;inlined&#93;</span>
      <br data-jscall-id="411" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="412"> &#91;48&#93; __binrepr&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Makie.FigureAxisPlot, context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="413" />
      <span data-jscall-id="414">    &#64; Base.Multimedia 
        <a href="vscode://file/./multimedia.jl:173" data-jscall-id="415">./multimedia.jl:173</a>
      </span>
      <br data-jscall-id="416" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="417"> &#91;49&#93; _textrepr</span>
      <br data-jscall-id="418" />
      <span data-jscall-id="419">    &#64; 
        <a href="vscode://file/./multimedia.jl:163" data-jscall-id="420">./multimedia.jl:163</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="421" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="422"> &#91;50&#93; stringmime&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Makie.FigureAxisPlot; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="423" />
      <span data-jscall-id="424">    &#64; Base64 /opt/hostedtoolcache/julia/1.11.5/x64/share/julia/stdlib/v1.11/Base64/src/Base64.jl:44</span>
      <br data-jscall-id="425" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="426"> &#91;51&#93; display_dict&#40;x::Makie.FigureAxisPlot; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="427" />
      <span data-jscall-id="428">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/utilities/utilities.jl:576</span>
      <br data-jscall-id="429" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="430"> &#91;52&#93; invokelatest&#40;::Any, ::Any, ::Vararg&#123;Any&#125;; kwargs::&#64;Kwargs&#123;context::Pair&#123;Symbol, Bool&#125;&#125;&#41;</span>
      <br data-jscall-id="431" />
      <span data-jscall-id="432">    &#64; Base 
        <a href="vscode://file/./essentials.jl:1057" data-jscall-id="433">./essentials.jl:1057</a>
      </span>
      <br data-jscall-id="434" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="435"> &#91;53&#93; runner&#40;::Type&#123;…&#125;, node::MarkdownAST.Node&#123;…&#125;, page::Documenter.Page, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="436" />
      <span data-jscall-id="437">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:885</span>
      <br data-jscall-id="438" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="439"> &#91;54&#93; dispatch&#40;::Type&#123;Documenter.Expanders.ExpanderPipeline&#125;, ::MarkdownAST.Node&#123;Nothing&#125;, ::Vararg&#123;Any&#125;&#41;</span>
      <br data-jscall-id="440" />
      <span data-jscall-id="441">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="442" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="443"> &#91;55&#93; expand&#40;doc::Documenter.Document&#41;</span>
      <br data-jscall-id="444" />
      <span data-jscall-id="445">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:59</span>
      <br data-jscall-id="446" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="447"> &#91;56&#93; runner&#40;::Type&#123;Documenter.Builder.ExpandTemplates&#125;, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="448" />
      <span data-jscall-id="449">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/builder_pipeline.jl:224</span>
      <br data-jscall-id="450" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="451"> &#91;57&#93; dispatch&#40;::Type&#123;Documenter.Builder.DocumentPipeline&#125;, x::Documenter.Document&#41;</span>
      <br data-jscall-id="452" />
      <span data-jscall-id="453">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="454" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="455"> &#91;58&#93; #88</span>
      <br data-jscall-id="456" />
      <span data-jscall-id="457">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:275 &#91;inlined&#93;</span>
      <br data-jscall-id="458" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="459"> &#91;59&#93; withenv&#40;::Documenter.var&#34;#88#90&#34;&#123;Documenter.Document&#125;, ::Pair&#123;String, Nothing&#125;, ::Vararg&#123;Pair&#123;String, Nothing&#125;&#125;&#41;</span>
      <br data-jscall-id="460" />
      <span data-jscall-id="461">    &#64; Base 
        <a href="vscode://file/./env.jl:265" data-jscall-id="462">./env.jl:265</a>
      </span>
      <br data-jscall-id="463" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="464"> &#91;60&#93; #87</span>
      <br data-jscall-id="465" />
      <span data-jscall-id="466">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:274 &#91;inlined&#93;</span>
      <br data-jscall-id="467" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="468"> &#91;61&#93; cd&#40;f::Documenter.var&#34;#87#89&#34;&#123;Documenter.Document&#125;, dir::String&#41;</span>
      <br data-jscall-id="469" />
      <span data-jscall-id="470">    &#64; Base.Filesystem 
        <a href="vscode://file/./file.jl:112" data-jscall-id="471">./file.jl:112</a>
      </span>
      <br data-jscall-id="472" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="473"> &#91;62&#93; makedocs&#40;; debug::Bool, format::MarkdownVitepress, kwargs::&#64;Kwargs&#123;…&#125;&#41;</span>
      <br data-jscall-id="474" />
      <span data-jscall-id="475">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:273</span>
      <br data-jscall-id="476" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="477"> &#91;63&#93; make_docs&#40;; pages::Vector&#123;Pair&#123;String, Any&#125;&#125;&#41;</span>
      <br data-jscall-id="478" />
      <span data-jscall-id="479">    &#64; Main ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:189</span>
      <br data-jscall-id="480" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="481"> &#91;64&#93; top-level scope</span>
      <br data-jscall-id="482" />
      <span data-jscall-id="483">    &#64; ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:205</span>
      <br data-jscall-id="484" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="485"> &#91;65&#93; include&#40;mod::Module, _path::String&#41;</span>
      <br data-jscall-id="486" />
      <span data-jscall-id="487">    &#64; Base 
        <a href="vscode://file/./Base.jl:557" data-jscall-id="488">./Base.jl:557</a>
      </span>
      <br data-jscall-id="489" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="490"> &#91;66&#93; exec_options&#40;opts::Base.JLOptions&#41;</span>
      <br data-jscall-id="491" />
      <span data-jscall-id="492">    &#64; Base 
        <a href="vscode://file/./client.jl:323" data-jscall-id="493">./client.jl:323</a>
      </span>
      <br data-jscall-id="494" />
    </pre>
  </div>
</div></div><p>There are a couple of ways to keep interacting with Plots in a static export.</p><h2 id="Record-a-statemap" tabindex="-1">Record a statemap <a class="header-anchor" href="#Record-a-statemap" aria-label="Permalink to &quot;Record a statemap {#Record-a-statemap}&quot;">​</a></h2><p>Bonito allows to record a statemap for all widgets, that satisfy the following interface:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># must be true to be found inside the DOM</span></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">is_widget</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> true</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># Updating the widget isn&#39;t dependent on any other state (only thing supported right now)</span></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">is_independant</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> true</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># The values a widget can iterate</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> value_range </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># updating the widget with a certain value (usually an observable)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> update_value!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x, value) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><p>Currently, only sliders overload the interface:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Observables</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">App</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> session</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Session</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    n </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    index_slider </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Slider</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">n)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    volume </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> rand</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(n, n, n)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    slice </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> map</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(index_slider) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> idx</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> volume[:, :, idx]</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    end</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    fig </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ax, cplot </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> contour</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(fig[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], volume)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    rectplot </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> linesegments!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Rect</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">12</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">12</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">), linewidth</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, color</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:red</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    on</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(index_slider) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> idx</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        translate!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(rectplot, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,idx)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    end</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    heatmap</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(fig[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], slice)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    slider </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">div</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;z-index: &quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, index_slider, index_slider</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">value)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Bonito</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">record_states</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(session, DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">div</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(slider, fig))</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="267392d4-5a26-4a77-902d-72f949dfd29b" data-jscall-id="subsession-application-dom">
  <div>
    <style></style>
  </div>
  <div>
    <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/ab4999699ed48c65ae55f17be8215d9193938ba9-10723854640879968728.bin').then(msgs=> Bonito.init_session('267392d4-5a26-4a77-902d-72f949dfd29b', msgs, 'sub', false));
    })
<\/script>
    <pre class="backtrace" style="overflow-x: auto;" data-jscall-id="499">
      <h3 style="color: red;" data-jscall-id="500">Failed to resolve wgl_renderobject:
&#91;ComputeEdge&#93; wgl_renderobject, wgl_update_obs &#61; #71&#40;&#40;positions_transformed_f32c, vertex_color, uniform_color, uniform_colormap, uniform_colorrange, nan_color, highclip_color, lowclip_color, pattern, strokewidth, glowwidth, glowcolor, converted_rotation, converted_strokecolor, marker_offset, sdf_marker_shape, glyph_data, depth_shift, atlas, markerspace, visible, transform_marker, f32c_scale, model_f32c, uniform_clip_planes, uniform_num_clip_planes, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:110
&#91;ComputeEdge&#93; glyph_data &#61; #86&#40;&#40;glyphindices, font_per_char, glyph_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:332
&#91;ComputeEdge&#93; glyph_scales &#61; #85&#40;&#40;glyphindices, text_blocks, text_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329
  with edge inputs:
    glyphindices &#61; UInt64&#91;0x0000000000000011, 0x000000000000000f, 0x0000000000000011, 0x0000000000000013, 0x000000000000000f, 0x0000000000000016, 0x0000000000000016, 0x000000000000000f, 0x0000000000000011, 0x0000000000000018  …  0x0000000000000011, 0x000000000000005a, 0x0000000000000011, 0x0000000000000013, 0x0000000000000015, 0x0000000000000017, 0x0000000000000019, 0x0000000000000012, 0x0000000000000011, 0x000000000000005b&#93;
    text_blocks &#61; UnitRange&#123;Int64&#125;&#91;1:3, 4:6, 7:9, 10:12, 13:16, 17:17, 18:20, 21:23, 24:26, 27:29, 30:33, 34:34, 35:35, 36:36, 37:37, 38:38, 39:39, 40:41, 42:42&#93;
    text_scales &#61; Vec&#123;2, Float32&#125;&#91;&#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;  …  &#91;0.6, 0.6&#93;, &#91;0.72, 0.72&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.6, 0.6&#93;, &#91;0.72, 0.72&#93;&#93;
Triggered by update of:
  position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor or strokewidth
Due to ERROR: MethodError: no method matching map_per_glyph&#40;::Vector&#123;UInt64&#125;, ::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Type&#123;Vec&#123;2, Float32&#125;&#125;, ::Vector&#123;Vec&#123;2, Float32&#125;&#125;&#41;
The function &#96;map_per_glyph&#96; exists, but no method is defined for this combination of argument types.

Closest candidates are:
  map_per_glyph&#40;&#33;Matched::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Any, ::Any&#41;
   &#64; Makie ~/work/Makie.jl/Makie.jl/src/basic_recipes/text.jl:118
</h3>
      <span data-jscall-id="501">Stacktrace:</span>
      <br data-jscall-id="502" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="503">  &#91;1&#93; &#40;::WGLMakie.var&#34;#85#87&#34;&#41;&#40;::&#64;NamedTuple&#123;…&#125;, changed::&#64;NamedTuple&#123;…&#125;, last::Nothing&#41;</span>
      <br data-jscall-id="504" />
      <span data-jscall-id="505">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329</span>
      <br data-jscall-id="506" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="507">  &#91;2&#93; ComputePipeline.TypedEdge&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="508" />
      <span data-jscall-id="509">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:120</span>
      <br data-jscall-id="510" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="511">  &#91;3&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="512" />
      <span data-jscall-id="513">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:568</span>
      <br data-jscall-id="514" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="515">  &#91;4&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="516" />
      <span data-jscall-id="517">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="518" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="519">  &#91;5&#93; foreach</span>
      <br data-jscall-id="520" />
      <span data-jscall-id="521">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3187" data-jscall-id="522">./abstractarray.jl:3187</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="523" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="524">  &#91;6&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="525" />
      <span data-jscall-id="526">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:563</span>
      <br data-jscall-id="527" />
      <span data-jscall-id="528">--- the above 3 lines are repeated 1 more time ---</span>
      <br data-jscall-id="529" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="530"> &#91;10&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="531" />
      <span data-jscall-id="532">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="533" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="534"> &#91;11&#93; resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="535" />
      <span data-jscall-id="536">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:546</span>
      <br data-jscall-id="537" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="538"> &#91;12&#93; getindex</span>
      <br data-jscall-id="539" />
      <span data-jscall-id="540">    &#64; ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:466 &#91;inlined&#93;</span>
      <br data-jscall-id="541" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="542"> &#91;13&#93; create_wgl_renderobject&#40;callback::typeof&#40;WGLMakie.scatter_program&#41;, attr::ComputePipeline.ComputeGraph, inputs::Vector&#123;…&#125;&#41;</span>
      <br data-jscall-id="543" />
      <span data-jscall-id="544">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:130</span>
      <br data-jscall-id="545" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="546"> &#91;14&#93; create_shader&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;3, Float32&#125;&#125;&#125;&#125;&#41;</span>
      <br data-jscall-id="547" />
      <span data-jscall-id="548">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:369</span>
      <br data-jscall-id="549" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="550"> &#91;15&#93; serialize_three&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;3, Float32&#125;&#125;&#125;&#125;&#41;</span>
      <br data-jscall-id="551" />
      <span data-jscall-id="552">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:8</span>
      <br data-jscall-id="553" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="554"> &#91;16&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
      <br data-jscall-id="555" />
      <span data-jscall-id="556">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:230</span>
      <br data-jscall-id="557" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="558"> &#91;17&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
      <br data-jscall-id="559" />
      <span data-jscall-id="560">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:235</span>
      <br data-jscall-id="561" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="562"> &#91;18&#93; serialize_plots</span>
      <br data-jscall-id="563" />
      <span data-jscall-id="564">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:227 &#91;inlined&#93;</span>
      <br data-jscall-id="565" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="566"> &#91;19&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="567" />
      <span data-jscall-id="568">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:207</span>
      <br data-jscall-id="569" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="570"> &#91;20&#93; &#40;::WGLMakie.var&#34;#47#54&#34;&#41;&#40;child::Scene&#41;</span>
      <br data-jscall-id="571" />
      <span data-jscall-id="572">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="573" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="574"> &#91;21&#93; iterate</span>
      <br data-jscall-id="575" />
      <span data-jscall-id="576">    &#64; 
        <a href="vscode://file/./generator.jl:48" data-jscall-id="577">./generator.jl:48</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="578" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="579"> &#91;22&#93; _collect&#40;c::Vector&#123;…&#125;, itr::Base.Generator&#123;…&#125;, ::Base.EltypeUnknown, isz::Base.HasShape&#123;…&#125;&#41;</span>
      <br data-jscall-id="580" />
      <span data-jscall-id="581">    &#64; Base 
        <a href="vscode://file/./array.jl:811" data-jscall-id="582">./array.jl:811</a>
      </span>
      <br data-jscall-id="583" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="584"> &#91;23&#93; collect_similar</span>
      <br data-jscall-id="585" />
      <span data-jscall-id="586">    &#64; 
        <a href="vscode://file/./array.jl:720" data-jscall-id="587">./array.jl:720</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="588" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="589"> &#91;24&#93; map</span>
      <br data-jscall-id="590" />
      <span data-jscall-id="591">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3371" data-jscall-id="592">./abstractarray.jl:3371</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="593" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="594"> &#91;25&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="595" />
      <span data-jscall-id="596">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="597" />
      <span data-jscall-id="598">--- the above 6 lines are repeated 1 more time ---</span>
      <br data-jscall-id="599" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="600"> &#91;32&#93; three_display&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="601" />
      <span data-jscall-id="602">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/three_plot.jl:33</span>
      <br data-jscall-id="603" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="604"> &#91;33&#93; render_with_init&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="605" />
      <span data-jscall-id="606">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:91</span>
      <br data-jscall-id="607" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="608"> &#91;34&#93; jsrender</span>
      <br data-jscall-id="609" />
      <span data-jscall-id="610">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:124 &#91;inlined&#93;</span>
      <br data-jscall-id="611" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="612"> &#91;35&#93; jsrender&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, fig::Figure&#41;</span>
      <br data-jscall-id="613" />
      <span data-jscall-id="614">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:129</span>
      <br data-jscall-id="615" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="616"> &#91;36&#93; render_node&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, node::Hyperscript.Node&#123;Hyperscript.HTMLSVG&#125;&#41;</span>
      <br data-jscall-id="617" />
      <span data-jscall-id="618">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/rendering/hyperscript_integration.jl:171</span>
      <br data-jscall-id="619" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="620"> &#91;37&#93; jsrender</span>
      <br data-jscall-id="621" />
      <span data-jscall-id="622">    &#64; ~/.julia/packages/Bonito/PiA4w/src/rendering/hyperscript_integration.jl:201 &#91;inlined&#93;</span>
      <br data-jscall-id="623" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="624"> &#91;38&#93; record_states&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, dom::Hyperscript.Node&#123;Hyperscript.HTMLSVG&#125;&#41;</span>
      <br data-jscall-id="625" />
      <span data-jscall-id="626">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/export.jl:110</span>
      <br data-jscall-id="627" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="628"> &#91;39&#93; &#40;::Main.__atexample__named__wglmakie.var&#34;#1#4&#34;&#41;&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;&#41;</span>
      <br data-jscall-id="629" />
      <span data-jscall-id="630">    &#64; Main.__atexample__named__wglmakie ./wglmakie.md:138</span>
      <br data-jscall-id="631" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="632"> &#91;40&#93; &#40;::Bonito.var&#34;#10#16&#34;&#123;…&#125;&#41;&#40;session::Bonito.Session&#123;…&#125;, request::HTTP.Messages.Request&#41;</span>
      <br data-jscall-id="633" />
      <span data-jscall-id="634">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/types.jl:362</span>
      <br data-jscall-id="635" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="636"> &#91;41&#93; #invokelatest#2</span>
      <br data-jscall-id="637" />
      <span data-jscall-id="638">    &#64; 
        <a href="vscode://file/./essentials.jl:1055" data-jscall-id="639">./essentials.jl:1055</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="640" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="641"> &#91;42&#93; invokelatest</span>
      <br data-jscall-id="642" />
      <span data-jscall-id="643">    &#64; 
        <a href="vscode://file/./essentials.jl:1052" data-jscall-id="644">./essentials.jl:1052</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="645" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="646"> &#91;43&#93; rendered_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App, target::HTTP.Messages.Request&#41;</span>
      <br data-jscall-id="647" />
      <span data-jscall-id="648">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/app.jl:42</span>
      <br data-jscall-id="649" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="650"> &#91;44&#93; rendered_dom</span>
      <br data-jscall-id="651" />
      <span data-jscall-id="652">    &#64; ~/.julia/packages/Bonito/PiA4w/src/app.jl:39 &#91;inlined&#93;</span>
      <br data-jscall-id="653" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="654"> &#91;45&#93; session_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App; init::Bool, html_document::Bool&#41;</span>
      <br data-jscall-id="655" />
      <span data-jscall-id="656">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/session.jl:363</span>
      <br data-jscall-id="657" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="658"> &#91;46&#93; session_dom</span>
      <br data-jscall-id="659" />
      <span data-jscall-id="660">    &#64; ~/.julia/packages/Bonito/PiA4w/src/session.jl:362 &#91;inlined&#93;</span>
      <br data-jscall-id="661" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="662"> &#91;47&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App; parent::Bonito.Session&#123;Bonito.NoConnection&#125;&#41;</span>
      <br data-jscall-id="663" />
      <span data-jscall-id="664">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:70</span>
      <br data-jscall-id="665" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="666"> &#91;48&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App&#41;</span>
      <br data-jscall-id="667" />
      <span data-jscall-id="668">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:63</span>
      <br data-jscall-id="669" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="670"> &#91;49&#93; show</span>
      <br data-jscall-id="671" />
      <span data-jscall-id="672">    &#64; ~/.julia/packages/Bonito/PiA4w/src/display.jl:97 &#91;inlined&#93;</span>
      <br data-jscall-id="673" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="674"> &#91;50&#93; __binrepr&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Bonito.App, context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="675" />
      <span data-jscall-id="676">    &#64; Base.Multimedia 
        <a href="vscode://file/./multimedia.jl:173" data-jscall-id="677">./multimedia.jl:173</a>
      </span>
      <br data-jscall-id="678" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="679"> &#91;51&#93; _textrepr</span>
      <br data-jscall-id="680" />
      <span data-jscall-id="681">    &#64; 
        <a href="vscode://file/./multimedia.jl:163" data-jscall-id="682">./multimedia.jl:163</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="683" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="684"> &#91;52&#93; stringmime&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Bonito.App; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="685" />
      <span data-jscall-id="686">    &#64; Base64 /opt/hostedtoolcache/julia/1.11.5/x64/share/julia/stdlib/v1.11/Base64/src/Base64.jl:44</span>
      <br data-jscall-id="687" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="688"> &#91;53&#93; display_dict&#40;x::Bonito.App; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="689" />
      <span data-jscall-id="690">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/utilities/utilities.jl:576</span>
      <br data-jscall-id="691" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="692"> &#91;54&#93; invokelatest&#40;::Any, ::Any, ::Vararg&#123;Any&#125;; kwargs::&#64;Kwargs&#123;context::Pair&#123;Symbol, Bool&#125;&#125;&#41;</span>
      <br data-jscall-id="693" />
      <span data-jscall-id="694">    &#64; Base 
        <a href="vscode://file/./essentials.jl:1057" data-jscall-id="695">./essentials.jl:1057</a>
      </span>
      <br data-jscall-id="696" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="697"> &#91;55&#93; runner&#40;::Type&#123;…&#125;, node::MarkdownAST.Node&#123;…&#125;, page::Documenter.Page, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="698" />
      <span data-jscall-id="699">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:885</span>
      <br data-jscall-id="700" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="701"> &#91;56&#93; dispatch&#40;::Type&#123;Documenter.Expanders.ExpanderPipeline&#125;, ::MarkdownAST.Node&#123;Nothing&#125;, ::Vararg&#123;Any&#125;&#41;</span>
      <br data-jscall-id="702" />
      <span data-jscall-id="703">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="704" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="705"> &#91;57&#93; expand&#40;doc::Documenter.Document&#41;</span>
      <br data-jscall-id="706" />
      <span data-jscall-id="707">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:59</span>
      <br data-jscall-id="708" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="709"> &#91;58&#93; runner&#40;::Type&#123;Documenter.Builder.ExpandTemplates&#125;, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="710" />
      <span data-jscall-id="711">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/builder_pipeline.jl:224</span>
      <br data-jscall-id="712" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="713"> &#91;59&#93; dispatch&#40;::Type&#123;Documenter.Builder.DocumentPipeline&#125;, x::Documenter.Document&#41;</span>
      <br data-jscall-id="714" />
      <span data-jscall-id="715">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="716" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="717"> &#91;60&#93; #88</span>
      <br data-jscall-id="718" />
      <span data-jscall-id="719">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:275 &#91;inlined&#93;</span>
      <br data-jscall-id="720" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="721"> &#91;61&#93; withenv&#40;::Documenter.var&#34;#88#90&#34;&#123;Documenter.Document&#125;, ::Pair&#123;String, Nothing&#125;, ::Vararg&#123;Pair&#123;String, Nothing&#125;&#125;&#41;</span>
      <br data-jscall-id="722" />
      <span data-jscall-id="723">    &#64; Base 
        <a href="vscode://file/./env.jl:265" data-jscall-id="724">./env.jl:265</a>
      </span>
      <br data-jscall-id="725" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="726"> &#91;62&#93; #87</span>
      <br data-jscall-id="727" />
      <span data-jscall-id="728">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:274 &#91;inlined&#93;</span>
      <br data-jscall-id="729" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="730"> &#91;63&#93; cd&#40;f::Documenter.var&#34;#87#89&#34;&#123;Documenter.Document&#125;, dir::String&#41;</span>
      <br data-jscall-id="731" />
      <span data-jscall-id="732">    &#64; Base.Filesystem 
        <a href="vscode://file/./file.jl:112" data-jscall-id="733">./file.jl:112</a>
      </span>
      <br data-jscall-id="734" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="735"> &#91;64&#93; makedocs&#40;; debug::Bool, format::MarkdownVitepress, kwargs::&#64;Kwargs&#123;…&#125;&#41;</span>
      <br data-jscall-id="736" />
      <span data-jscall-id="737">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:273</span>
      <br data-jscall-id="738" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="739"> &#91;65&#93; make_docs&#40;; pages::Vector&#123;Pair&#123;String, Any&#125;&#125;&#41;</span>
      <br data-jscall-id="740" />
      <span data-jscall-id="741">    &#64; Main ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:189</span>
      <br data-jscall-id="742" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="743"> &#91;66&#93; top-level scope</span>
      <br data-jscall-id="744" />
      <span data-jscall-id="745">    &#64; ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:205</span>
      <br data-jscall-id="746" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="747"> &#91;67&#93; include&#40;mod::Module, _path::String&#41;</span>
      <br data-jscall-id="748" />
      <span data-jscall-id="749">    &#64; Base 
        <a href="vscode://file/./Base.jl:557" data-jscall-id="750">./Base.jl:557</a>
      </span>
      <br data-jscall-id="751" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="752"> &#91;68&#93; exec_options&#40;opts::Base.JLOptions&#41;</span>
      <br data-jscall-id="753" />
      <span data-jscall-id="754">    &#64; Base 
        <a href="vscode://file/./client.jl:323" data-jscall-id="755">./client.jl:323</a>
      </span>
      <br data-jscall-id="756" />
    </pre>
  </div>
</div></div><h2 id="Execute-Javascript-directly" tabindex="-1">Execute Javascript directly <a class="header-anchor" href="#Execute-Javascript-directly" aria-label="Permalink to &quot;Execute Javascript directly {#Execute-Javascript-directly}&quot;">​</a></h2><p>Bonito makes it easy to build whole HTML and JS applications. You can for example directly register JavaScript function that get run on change.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Bonito</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">App</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> session</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Session</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    s1 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Slider</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    slider_val </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">p</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(s1[]) </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># initialize with current value</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # call the \`on_update\` function whenever s1.value changes in JS:</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    onjs</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(session, s1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">value, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">js</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> on_update</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">new_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) {</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">        //interpolating of DOM nodes and other Julia values work mostly as expected:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        const</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> p_element</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> $</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(slider_val)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        p_element.innerText </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> new_value</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    }</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">div</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;slider 1: &quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, s1, slider_val)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="aefa0a01-c820-48c9-a8fc-a9b75cf55dd6" data-jscall-id="subsession-application-dom">
  <div>
    <style></style>
  </div>
  <div>
    <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/9c93fc4d8e34a5968d5e0faa7006b4537930a5a3-17019536550312030753.bin').then(msgs=> Bonito.init_session('aefa0a01-c820-48c9-a8fc-a9b75cf55dd6', msgs, 'sub', false));
    })
<\/script>
    <div data-jscall-id="758">slider 1: 
      <input step="1" max="100" min="1" style="styles" data-jscall-id="759" value="1" oninput="" type="range" />
      <p data-jscall-id="757">1</p>
    </div>
  </div>
</div></div><p>One can also interpolate plots into JS and update those via JS. The problem is, that there isn&#39;t an amazing interface yet. The returned object is directly a THREE object, with all plot attributes converted into Javascript types. The good news is, all attributes should be in either <code>three_scene.material.uniforms</code>, or <code>three_scene.geometry.attributes</code>. Going forward, we should create an API in WGLMakie, that makes it as easy as in Julia: <code>plot.attribute = value</code>. But while this isn&#39;t in place, logging the the returned object makes it pretty easy to figure out what to do - btw, the JS console + logging is amazing and makes it very easy to play around with the object once logged.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Bonito</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> on_document_load</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> WGLMakie</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">App</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> session</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Session</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    s1 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Slider</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    slider_val </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">p</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(s1[]) </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># initialize with current value</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    fig, ax, splot </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> scatter</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # With on_document_load one can run JS after everything got loaded.</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # This is an alternative to \`evaljs\`, which we can&#39;t use here,</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # since it gets run asap, which means the plots won&#39;t be found yet.</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    on_document_load</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(session, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">js</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">        // you get a promise for an array of plots, when interpolating into JS:</span></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">        $</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(splot).</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">then</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">plots</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">{</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">            // just one plot for atomics like scatter, but for recipes it can be multiple plots</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">            const</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> scatter_plot</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> plots[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">            // open the console with ctr+shift+i, to inspect the values</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">            // tip - you can right click on the log and store the actual variable as a global, and directly interact with it to change the plot.</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            console.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">log</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(scatter_plot)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            console.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">log</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(scatter_plot.material.uniforms)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            console.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">log</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(scatter_plot.geometry.attributes)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        })</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # with the above, we can find out that the positions are stored in \`offset\`</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # (*sigh*, this is because threejs special cases \`position\` attributes so it can&#39;t be used)</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # Now, lets go and change them when using the slider :)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    onjs</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(session, s1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">value, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">js</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> on_update</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">new_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) {</span></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">        $</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(splot).</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">then</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">plots</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">{</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">            const</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> scatter_plot</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> plots[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">            // change first point x + y value</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            scatter_plot.geometry.attributes.pos.array[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (new_value</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">/</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            scatter_plot.geometry.attributes.pos.array[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (new_value</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">/</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">            // this always needs to be set of geometry attributes after an update</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            scatter_plot.geometry.attributes.pos.needsUpdate </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> true</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        })</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    }</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # and for got measures, add a slider to change the color:</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    color_slider </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Slider</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">LinRange</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    onjs</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(session, color_slider</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">value, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">js</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> on_update</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">hue</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) {</span></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">        $</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(splot).</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">then</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">plots</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">{</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">            const</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> scatter_plot</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> plots[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">            const</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> color</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> new</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> THREE</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">Color</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            color.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">setHSL</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(hue, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1.0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.5</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            scatter_plot.material.uniforms.color.value.x </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> color.r</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            scatter_plot.material.uniforms.color.value.y </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> color.g</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            scatter_plot.material.uniforms.color.value.z </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> color.b</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        })</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    }</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    markersize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Slider</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    onjs</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(session, markersize</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">value, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">js</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> on_update</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">size</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) {</span></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">        $</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(splot).</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">then</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">plots</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">{</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">            const</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> scatter_plot</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> plots[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            scatter_plot.material.uniforms.markersize.value.x </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> size</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            scatter_plot.material.uniforms.markersize.value.y </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> size</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        })</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    }</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">div</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(s1, color_slider, markersize, fig)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="e172dfaa-8fdb-4cf0-8cca-a9f9d744cc14" data-jscall-id="subsession-application-dom">
  <div>
    <style></style>
  </div>
  <div>
    <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/3dee85f87594627102dd20956fff9171db5ad779-6806904260870416648.bin').then(msgs=> Bonito.init_session('e172dfaa-8fdb-4cf0-8cca-a9f9d744cc14', msgs, 'sub', false));
    })
<\/script>
    <pre class="backtrace" style="overflow-x: auto;" data-jscall-id="764">
      <h3 style="color: red;" data-jscall-id="765">Failed to resolve wgl_renderobject:
&#91;ComputeEdge&#93; wgl_renderobject, wgl_update_obs &#61; #71&#40;&#40;positions_transformed_f32c, vertex_color, uniform_color, uniform_colormap, uniform_colorrange, nan_color, highclip_color, lowclip_color, pattern, strokewidth, glowwidth, glowcolor, converted_rotation, converted_strokecolor, marker_offset, sdf_marker_shape, glyph_data, depth_shift, atlas, markerspace, visible, transform_marker, f32c_scale, model_f32c, uniform_clip_planes, uniform_num_clip_planes, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:110
&#91;ComputeEdge&#93; glyph_data &#61; #86&#40;&#40;glyphindices, font_per_char, glyph_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:332
&#91;ComputeEdge&#93; glyph_scales &#61; #85&#40;&#40;glyphindices, text_blocks, text_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329
  with edge inputs:
    glyphindices &#61; UInt64&#91;&#93;
    text_blocks &#61; UnitRange&#123;Int64&#125;&#91;1:0&#93;
    text_scales &#61; Vec&#123;2, Float32&#125;&#91;&#93;
Triggered by update of:
  position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor or strokewidth
Due to ERROR: MethodError: no method matching map_per_glyph&#40;::Vector&#123;UInt64&#125;, ::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Type&#123;Vec&#123;2, Float32&#125;&#125;, ::Vector&#123;Vec&#123;2, Float32&#125;&#125;&#41;
The function &#96;map_per_glyph&#96; exists, but no method is defined for this combination of argument types.

Closest candidates are:
  map_per_glyph&#40;&#33;Matched::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Any, ::Any&#41;
   &#64; Makie ~/work/Makie.jl/Makie.jl/src/basic_recipes/text.jl:118
</h3>
      <span data-jscall-id="766">Stacktrace:</span>
      <br data-jscall-id="767" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="768">  &#91;1&#93; &#40;::WGLMakie.var&#34;#85#87&#34;&#41;&#40;::&#64;NamedTuple&#123;…&#125;, changed::&#64;NamedTuple&#123;…&#125;, last::Nothing&#41;</span>
      <br data-jscall-id="769" />
      <span data-jscall-id="770">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329</span>
      <br data-jscall-id="771" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="772">  &#91;2&#93; ComputePipeline.TypedEdge&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="773" />
      <span data-jscall-id="774">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:120</span>
      <br data-jscall-id="775" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="776">  &#91;3&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="777" />
      <span data-jscall-id="778">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:568</span>
      <br data-jscall-id="779" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="780">  &#91;4&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="781" />
      <span data-jscall-id="782">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="783" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="784">  &#91;5&#93; foreach</span>
      <br data-jscall-id="785" />
      <span data-jscall-id="786">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3187" data-jscall-id="787">./abstractarray.jl:3187</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="788" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="789">  &#91;6&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="790" />
      <span data-jscall-id="791">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:563</span>
      <br data-jscall-id="792" />
      <span data-jscall-id="793">--- the above 3 lines are repeated 1 more time ---</span>
      <br data-jscall-id="794" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="795"> &#91;10&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="796" />
      <span data-jscall-id="797">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="798" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="799"> &#91;11&#93; resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="800" />
      <span data-jscall-id="801">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:546</span>
      <br data-jscall-id="802" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="803"> &#91;12&#93; getindex</span>
      <br data-jscall-id="804" />
      <span data-jscall-id="805">    &#64; ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:466 &#91;inlined&#93;</span>
      <br data-jscall-id="806" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="807"> &#91;13&#93; create_wgl_renderobject&#40;callback::typeof&#40;WGLMakie.scatter_program&#41;, attr::ComputePipeline.ComputeGraph, inputs::Vector&#123;…&#125;&#41;</span>
      <br data-jscall-id="808" />
      <span data-jscall-id="809">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:130</span>
      <br data-jscall-id="810" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="811"> &#91;14&#93; create_shader&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;2, Float32&#125;&#125;&#125;&#125;&#41;</span>
      <br data-jscall-id="812" />
      <span data-jscall-id="813">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:369</span>
      <br data-jscall-id="814" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="815"> &#91;15&#93; serialize_three&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;2, Float32&#125;&#125;&#125;&#125;&#41;</span>
      <br data-jscall-id="816" />
      <span data-jscall-id="817">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:8</span>
      <br data-jscall-id="818" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="819"> &#91;16&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
      <br data-jscall-id="820" />
      <span data-jscall-id="821">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:230</span>
      <br data-jscall-id="822" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="823"> &#91;17&#93; serialize_plots</span>
      <br data-jscall-id="824" />
      <span data-jscall-id="825">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:227 &#91;inlined&#93;</span>
      <br data-jscall-id="826" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="827"> &#91;18&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="828" />
      <span data-jscall-id="829">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:207</span>
      <br data-jscall-id="830" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="831"> &#91;19&#93; &#40;::WGLMakie.var&#34;#47#54&#34;&#41;&#40;child::Scene&#41;</span>
      <br data-jscall-id="832" />
      <span data-jscall-id="833">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="834" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="835"> &#91;20&#93; iterate</span>
      <br data-jscall-id="836" />
      <span data-jscall-id="837">    &#64; 
        <a href="vscode://file/./generator.jl:48" data-jscall-id="838">./generator.jl:48</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="839" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="840"> &#91;21&#93; _collect&#40;c::Vector&#123;…&#125;, itr::Base.Generator&#123;…&#125;, ::Base.EltypeUnknown, isz::Base.HasShape&#123;…&#125;&#41;</span>
      <br data-jscall-id="841" />
      <span data-jscall-id="842">    &#64; Base 
        <a href="vscode://file/./array.jl:811" data-jscall-id="843">./array.jl:811</a>
      </span>
      <br data-jscall-id="844" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="845"> &#91;22&#93; collect_similar</span>
      <br data-jscall-id="846" />
      <span data-jscall-id="847">    &#64; 
        <a href="vscode://file/./array.jl:720" data-jscall-id="848">./array.jl:720</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="849" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="850"> &#91;23&#93; map</span>
      <br data-jscall-id="851" />
      <span data-jscall-id="852">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3371" data-jscall-id="853">./abstractarray.jl:3371</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="854" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="855"> &#91;24&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="856" />
      <span data-jscall-id="857">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="858" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="859"> &#91;25&#93; three_display&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="860" />
      <span data-jscall-id="861">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/three_plot.jl:33</span>
      <br data-jscall-id="862" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="863"> &#91;26&#93; render_with_init&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="864" />
      <span data-jscall-id="865">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:91</span>
      <br data-jscall-id="866" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="867"> &#91;27&#93; jsrender</span>
      <br data-jscall-id="868" />
      <span data-jscall-id="869">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:124 &#91;inlined&#93;</span>
      <br data-jscall-id="870" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="871"> &#91;28&#93; jsrender&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, fig::Figure&#41;</span>
      <br data-jscall-id="872" />
      <span data-jscall-id="873">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:129</span>
      <br data-jscall-id="874" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="875"> &#91;29&#93; render_node&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, node::Hyperscript.Node&#123;Hyperscript.HTMLSVG&#125;&#41;</span>
      <br data-jscall-id="876" />
      <span data-jscall-id="877">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/rendering/hyperscript_integration.jl:171</span>
      <br data-jscall-id="878" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="879"> &#91;30&#93; jsrender&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, node::Hyperscript.Node&#123;Hyperscript.HTMLSVG&#125;&#41;</span>
      <br data-jscall-id="880" />
      <span data-jscall-id="881">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/rendering/hyperscript_integration.jl:201</span>
      <br data-jscall-id="882" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="883"> &#91;31&#93; rendered_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App, target::HTTP.Messages.Request&#41;</span>
      <br data-jscall-id="884" />
      <span data-jscall-id="885">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/app.jl:43</span>
      <br data-jscall-id="886" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="887"> &#91;32&#93; rendered_dom</span>
      <br data-jscall-id="888" />
      <span data-jscall-id="889">    &#64; ~/.julia/packages/Bonito/PiA4w/src/app.jl:39 &#91;inlined&#93;</span>
      <br data-jscall-id="890" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="891"> &#91;33&#93; session_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App; init::Bool, html_document::Bool&#41;</span>
      <br data-jscall-id="892" />
      <span data-jscall-id="893">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/session.jl:363</span>
      <br data-jscall-id="894" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="895"> &#91;34&#93; session_dom</span>
      <br data-jscall-id="896" />
      <span data-jscall-id="897">    &#64; ~/.julia/packages/Bonito/PiA4w/src/session.jl:362 &#91;inlined&#93;</span>
      <br data-jscall-id="898" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="899"> &#91;35&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App; parent::Bonito.Session&#123;Bonito.NoConnection&#125;&#41;</span>
      <br data-jscall-id="900" />
      <span data-jscall-id="901">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:70</span>
      <br data-jscall-id="902" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="903"> &#91;36&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App&#41;</span>
      <br data-jscall-id="904" />
      <span data-jscall-id="905">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:63</span>
      <br data-jscall-id="906" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="907"> &#91;37&#93; show</span>
      <br data-jscall-id="908" />
      <span data-jscall-id="909">    &#64; ~/.julia/packages/Bonito/PiA4w/src/display.jl:97 &#91;inlined&#93;</span>
      <br data-jscall-id="910" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="911"> &#91;38&#93; __binrepr&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Bonito.App, context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="912" />
      <span data-jscall-id="913">    &#64; Base.Multimedia 
        <a href="vscode://file/./multimedia.jl:173" data-jscall-id="914">./multimedia.jl:173</a>
      </span>
      <br data-jscall-id="915" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="916"> &#91;39&#93; _textrepr</span>
      <br data-jscall-id="917" />
      <span data-jscall-id="918">    &#64; 
        <a href="vscode://file/./multimedia.jl:163" data-jscall-id="919">./multimedia.jl:163</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="920" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="921"> &#91;40&#93; stringmime&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Bonito.App; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="922" />
      <span data-jscall-id="923">    &#64; Base64 /opt/hostedtoolcache/julia/1.11.5/x64/share/julia/stdlib/v1.11/Base64/src/Base64.jl:44</span>
      <br data-jscall-id="924" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="925"> &#91;41&#93; display_dict&#40;x::Bonito.App; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="926" />
      <span data-jscall-id="927">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/utilities/utilities.jl:576</span>
      <br data-jscall-id="928" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="929"> &#91;42&#93; invokelatest&#40;::Any, ::Any, ::Vararg&#123;Any&#125;; kwargs::&#64;Kwargs&#123;context::Pair&#123;Symbol, Bool&#125;&#125;&#41;</span>
      <br data-jscall-id="930" />
      <span data-jscall-id="931">    &#64; Base 
        <a href="vscode://file/./essentials.jl:1057" data-jscall-id="932">./essentials.jl:1057</a>
      </span>
      <br data-jscall-id="933" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="934"> &#91;43&#93; runner&#40;::Type&#123;…&#125;, node::MarkdownAST.Node&#123;…&#125;, page::Documenter.Page, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="935" />
      <span data-jscall-id="936">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:885</span>
      <br data-jscall-id="937" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="938"> &#91;44&#93; dispatch&#40;::Type&#123;Documenter.Expanders.ExpanderPipeline&#125;, ::MarkdownAST.Node&#123;Nothing&#125;, ::Vararg&#123;Any&#125;&#41;</span>
      <br data-jscall-id="939" />
      <span data-jscall-id="940">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="941" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="942"> &#91;45&#93; expand&#40;doc::Documenter.Document&#41;</span>
      <br data-jscall-id="943" />
      <span data-jscall-id="944">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:59</span>
      <br data-jscall-id="945" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="946"> &#91;46&#93; runner&#40;::Type&#123;Documenter.Builder.ExpandTemplates&#125;, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="947" />
      <span data-jscall-id="948">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/builder_pipeline.jl:224</span>
      <br data-jscall-id="949" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="950"> &#91;47&#93; dispatch&#40;::Type&#123;Documenter.Builder.DocumentPipeline&#125;, x::Documenter.Document&#41;</span>
      <br data-jscall-id="951" />
      <span data-jscall-id="952">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="953" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="954"> &#91;48&#93; #88</span>
      <br data-jscall-id="955" />
      <span data-jscall-id="956">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:275 &#91;inlined&#93;</span>
      <br data-jscall-id="957" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="958"> &#91;49&#93; withenv&#40;::Documenter.var&#34;#88#90&#34;&#123;Documenter.Document&#125;, ::Pair&#123;String, Nothing&#125;, ::Vararg&#123;Pair&#123;String, Nothing&#125;&#125;&#41;</span>
      <br data-jscall-id="959" />
      <span data-jscall-id="960">    &#64; Base 
        <a href="vscode://file/./env.jl:265" data-jscall-id="961">./env.jl:265</a>
      </span>
      <br data-jscall-id="962" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="963"> &#91;50&#93; #87</span>
      <br data-jscall-id="964" />
      <span data-jscall-id="965">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:274 &#91;inlined&#93;</span>
      <br data-jscall-id="966" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="967"> &#91;51&#93; cd&#40;f::Documenter.var&#34;#87#89&#34;&#123;Documenter.Document&#125;, dir::String&#41;</span>
      <br data-jscall-id="968" />
      <span data-jscall-id="969">    &#64; Base.Filesystem 
        <a href="vscode://file/./file.jl:112" data-jscall-id="970">./file.jl:112</a>
      </span>
      <br data-jscall-id="971" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="972"> &#91;52&#93; makedocs&#40;; debug::Bool, format::MarkdownVitepress, kwargs::&#64;Kwargs&#123;…&#125;&#41;</span>
      <br data-jscall-id="973" />
      <span data-jscall-id="974">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:273</span>
      <br data-jscall-id="975" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="976"> &#91;53&#93; make_docs&#40;; pages::Vector&#123;Pair&#123;String, Any&#125;&#125;&#41;</span>
      <br data-jscall-id="977" />
      <span data-jscall-id="978">    &#64; Main ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:189</span>
      <br data-jscall-id="979" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="980"> &#91;54&#93; top-level scope</span>
      <br data-jscall-id="981" />
      <span data-jscall-id="982">    &#64; ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:205</span>
      <br data-jscall-id="983" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="984"> &#91;55&#93; include&#40;mod::Module, _path::String&#41;</span>
      <br data-jscall-id="985" />
      <span data-jscall-id="986">    &#64; Base 
        <a href="vscode://file/./Base.jl:557" data-jscall-id="987">./Base.jl:557</a>
      </span>
      <br data-jscall-id="988" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="989"> &#91;56&#93; exec_options&#40;opts::Base.JLOptions&#41;</span>
      <br data-jscall-id="990" />
      <span data-jscall-id="991">    &#64; Base 
        <a href="vscode://file/./client.jl:323" data-jscall-id="992">./client.jl:323</a>
      </span>
      <br data-jscall-id="993" />
    </pre>
  </div>
</div></div><p>This summarizes the current state of interactivity with WGLMakie inside static pages.</p><h2 id="Offline-Tooltip" tabindex="-1">Offline Tooltip <a class="header-anchor" href="#Offline-Tooltip" aria-label="Permalink to &quot;Offline Tooltip {#Offline-Tooltip}&quot;">​</a></h2><p><code>Makie.DataInspector</code> works just fine with WGLMakie, but it requires a running Julia process to show and update the tooltip.</p><p>There is also a way to show a tooltip in Javascript directly, which needs to be inserted into the HTML dom. This means, we actually need to use <code>Bonito.App</code> to return a <code>DOM</code> object:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">App</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> session</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    f, ax, pl </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> scatter</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, markersize</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, color</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Float32[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.5</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.6</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    custom_info </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;a&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;b&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;c&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;d&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    on_click_callback </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> js</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">plot</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">index</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> {</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">        // the plot object is currently just the raw THREEJS mesh</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        console.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">log</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(plot)</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">        // Which can be used to extract e.g. position or color:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        const</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> {</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pos</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">color</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">} </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> plot.geometry.attributes</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        console.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">log</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(pos)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        console.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">log</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(color)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        const</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> x</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> pos.array[index</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">// everything is a flat array in JS</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        const</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> y</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> pos.array[index</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">+</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        const</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> c</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Math.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">round</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(color.array[index] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">/</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"> // rounding to a digit in JS</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        const</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> custom</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> $</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(custom_info)[index]</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">        // return either a string, or an HTMLNode:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        return</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Point: &lt;&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> +</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> x </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">+</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;, &quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> +</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> y </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">+</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;&gt;, value: &quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> +</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> c </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">+</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot; custom: &quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> +</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> custom</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    }</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;&quot;&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # ToolTip(figurelike, js_callback; plots=plots_you_want_to_hover)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    tooltip </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> WGLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">ToolTip</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f, on_click_callback; plots</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">pl)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">div</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f, tooltip)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="f528be00-b4f8-434a-98a5-eb11197665cb" data-jscall-id="subsession-application-dom">
  <div>
    <style></style>
  </div>
  <div>
    <script type="module">Bonito.lock_loading(() => Bonito.init_session('f528be00-b4f8-434a-98a5-eb11197665cb', null, 'sub', false))<\/script>
    <pre class="backtrace" style="overflow-x: auto;" data-jscall-id="995">
      <h3 style="color: red;" data-jscall-id="996">Failed to resolve wgl_renderobject:
&#91;ComputeEdge&#93; wgl_renderobject, wgl_update_obs &#61; #71&#40;&#40;positions_transformed_f32c, vertex_color, uniform_color, uniform_colormap, uniform_colorrange, nan_color, highclip_color, lowclip_color, pattern, strokewidth, glowwidth, glowcolor, converted_rotation, converted_strokecolor, marker_offset, sdf_marker_shape, glyph_data, depth_shift, atlas, markerspace, visible, transform_marker, f32c_scale, model_f32c, uniform_clip_planes, uniform_num_clip_planes, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:110
&#91;ComputeEdge&#93; glyph_data &#61; #86&#40;&#40;glyphindices, font_per_char, glyph_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:332
&#91;ComputeEdge&#93; glyph_scales &#61; #85&#40;&#40;glyphindices, text_blocks, text_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329
  with edge inputs:
    glyphindices &#61; UInt64&#91;&#93;
    text_blocks &#61; UnitRange&#123;Int64&#125;&#91;1:0&#93;
    text_scales &#61; Vec&#123;2, Float32&#125;&#91;&#93;
Triggered by update of:
  position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, fontsize, fonts, font, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor or strokewidth
Due to ERROR: MethodError: no method matching map_per_glyph&#40;::Vector&#123;UInt64&#125;, ::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Type&#123;Vec&#123;2, Float32&#125;&#125;, ::Vector&#123;Vec&#123;2, Float32&#125;&#125;&#41;
The function &#96;map_per_glyph&#96; exists, but no method is defined for this combination of argument types.

Closest candidates are:
  map_per_glyph&#40;&#33;Matched::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Any, ::Any&#41;
   &#64; Makie ~/work/Makie.jl/Makie.jl/src/basic_recipes/text.jl:118
</h3>
      <span data-jscall-id="997">Stacktrace:</span>
      <br data-jscall-id="998" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="999">  &#91;1&#93; &#40;::WGLMakie.var&#34;#85#87&#34;&#41;&#40;::&#64;NamedTuple&#123;…&#125;, changed::&#64;NamedTuple&#123;…&#125;, last::Nothing&#41;</span>
      <br data-jscall-id="1000" />
      <span data-jscall-id="1001">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329</span>
      <br data-jscall-id="1002" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1003">  &#91;2&#93; ComputePipeline.TypedEdge&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="1004" />
      <span data-jscall-id="1005">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:120</span>
      <br data-jscall-id="1006" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1007">  &#91;3&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="1008" />
      <span data-jscall-id="1009">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:568</span>
      <br data-jscall-id="1010" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1011">  &#91;4&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="1012" />
      <span data-jscall-id="1013">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="1014" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1015">  &#91;5&#93; foreach</span>
      <br data-jscall-id="1016" />
      <span data-jscall-id="1017">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3187" data-jscall-id="1018">./abstractarray.jl:3187</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="1019" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1020">  &#91;6&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="1021" />
      <span data-jscall-id="1022">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:563</span>
      <br data-jscall-id="1023" />
      <span data-jscall-id="1024">--- the above 3 lines are repeated 1 more time ---</span>
      <br data-jscall-id="1025" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1026"> &#91;10&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="1027" />
      <span data-jscall-id="1028">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="1029" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1030"> &#91;11&#93; resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="1031" />
      <span data-jscall-id="1032">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:546</span>
      <br data-jscall-id="1033" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1034"> &#91;12&#93; getindex</span>
      <br data-jscall-id="1035" />
      <span data-jscall-id="1036">    &#64; ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:466 &#91;inlined&#93;</span>
      <br data-jscall-id="1037" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1038"> &#91;13&#93; create_wgl_renderobject&#40;callback::typeof&#40;WGLMakie.scatter_program&#41;, attr::ComputePipeline.ComputeGraph, inputs::Vector&#123;…&#125;&#41;</span>
      <br data-jscall-id="1039" />
      <span data-jscall-id="1040">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:130</span>
      <br data-jscall-id="1041" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1042"> &#91;14&#93; create_shader&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;2, Float32&#125;&#125;&#125;&#125;&#41;</span>
      <br data-jscall-id="1043" />
      <span data-jscall-id="1044">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:369</span>
      <br data-jscall-id="1045" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1046"> &#91;15&#93; serialize_three&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;2, Float32&#125;&#125;&#125;&#125;&#41;</span>
      <br data-jscall-id="1047" />
      <span data-jscall-id="1048">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:8</span>
      <br data-jscall-id="1049" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1050"> &#91;16&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
      <br data-jscall-id="1051" />
      <span data-jscall-id="1052">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:230</span>
      <br data-jscall-id="1053" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1054"> &#91;17&#93; serialize_plots</span>
      <br data-jscall-id="1055" />
      <span data-jscall-id="1056">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:227 &#91;inlined&#93;</span>
      <br data-jscall-id="1057" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1058"> &#91;18&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="1059" />
      <span data-jscall-id="1060">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:207</span>
      <br data-jscall-id="1061" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1062"> &#91;19&#93; &#40;::WGLMakie.var&#34;#47#54&#34;&#41;&#40;child::Scene&#41;</span>
      <br data-jscall-id="1063" />
      <span data-jscall-id="1064">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="1065" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1066"> &#91;20&#93; iterate</span>
      <br data-jscall-id="1067" />
      <span data-jscall-id="1068">    &#64; 
        <a href="vscode://file/./generator.jl:48" data-jscall-id="1069">./generator.jl:48</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="1070" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1071"> &#91;21&#93; _collect&#40;c::Vector&#123;…&#125;, itr::Base.Generator&#123;…&#125;, ::Base.EltypeUnknown, isz::Base.HasShape&#123;…&#125;&#41;</span>
      <br data-jscall-id="1072" />
      <span data-jscall-id="1073">    &#64; Base 
        <a href="vscode://file/./array.jl:811" data-jscall-id="1074">./array.jl:811</a>
      </span>
      <br data-jscall-id="1075" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1076"> &#91;22&#93; collect_similar</span>
      <br data-jscall-id="1077" />
      <span data-jscall-id="1078">    &#64; 
        <a href="vscode://file/./array.jl:720" data-jscall-id="1079">./array.jl:720</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="1080" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1081"> &#91;23&#93; map</span>
      <br data-jscall-id="1082" />
      <span data-jscall-id="1083">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3371" data-jscall-id="1084">./abstractarray.jl:3371</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="1085" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1086"> &#91;24&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="1087" />
      <span data-jscall-id="1088">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="1089" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1090"> &#91;25&#93; three_display&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="1091" />
      <span data-jscall-id="1092">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/three_plot.jl:33</span>
      <br data-jscall-id="1093" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1094"> &#91;26&#93; render_with_init&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="1095" />
      <span data-jscall-id="1096">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:91</span>
      <br data-jscall-id="1097" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1098"> &#91;27&#93; jsrender</span>
      <br data-jscall-id="1099" />
      <span data-jscall-id="1100">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:124 &#91;inlined&#93;</span>
      <br data-jscall-id="1101" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1102"> &#91;28&#93; jsrender&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, fig::Figure&#41;</span>
      <br data-jscall-id="1103" />
      <span data-jscall-id="1104">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:129</span>
      <br data-jscall-id="1105" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1106"> &#91;29&#93; render_node&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, node::Hyperscript.Node&#123;Hyperscript.HTMLSVG&#125;&#41;</span>
      <br data-jscall-id="1107" />
      <span data-jscall-id="1108">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/rendering/hyperscript_integration.jl:171</span>
      <br data-jscall-id="1109" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1110"> &#91;30&#93; jsrender&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, node::Hyperscript.Node&#123;Hyperscript.HTMLSVG&#125;&#41;</span>
      <br data-jscall-id="1111" />
      <span data-jscall-id="1112">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/rendering/hyperscript_integration.jl:201</span>
      <br data-jscall-id="1113" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1114"> &#91;31&#93; rendered_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App, target::HTTP.Messages.Request&#41;</span>
      <br data-jscall-id="1115" />
      <span data-jscall-id="1116">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/app.jl:43</span>
      <br data-jscall-id="1117" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1118"> &#91;32&#93; rendered_dom</span>
      <br data-jscall-id="1119" />
      <span data-jscall-id="1120">    &#64; ~/.julia/packages/Bonito/PiA4w/src/app.jl:39 &#91;inlined&#93;</span>
      <br data-jscall-id="1121" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1122"> &#91;33&#93; session_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App; init::Bool, html_document::Bool&#41;</span>
      <br data-jscall-id="1123" />
      <span data-jscall-id="1124">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/session.jl:363</span>
      <br data-jscall-id="1125" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1126"> &#91;34&#93; session_dom</span>
      <br data-jscall-id="1127" />
      <span data-jscall-id="1128">    &#64; ~/.julia/packages/Bonito/PiA4w/src/session.jl:362 &#91;inlined&#93;</span>
      <br data-jscall-id="1129" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1130"> &#91;35&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App; parent::Bonito.Session&#123;Bonito.NoConnection&#125;&#41;</span>
      <br data-jscall-id="1131" />
      <span data-jscall-id="1132">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:70</span>
      <br data-jscall-id="1133" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1134"> &#91;36&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App&#41;</span>
      <br data-jscall-id="1135" />
      <span data-jscall-id="1136">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:63</span>
      <br data-jscall-id="1137" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1138"> &#91;37&#93; show</span>
      <br data-jscall-id="1139" />
      <span data-jscall-id="1140">    &#64; ~/.julia/packages/Bonito/PiA4w/src/display.jl:97 &#91;inlined&#93;</span>
      <br data-jscall-id="1141" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1142"> &#91;38&#93; __binrepr&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Bonito.App, context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="1143" />
      <span data-jscall-id="1144">    &#64; Base.Multimedia 
        <a href="vscode://file/./multimedia.jl:173" data-jscall-id="1145">./multimedia.jl:173</a>
      </span>
      <br data-jscall-id="1146" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1147"> &#91;39&#93; _textrepr</span>
      <br data-jscall-id="1148" />
      <span data-jscall-id="1149">    &#64; 
        <a href="vscode://file/./multimedia.jl:163" data-jscall-id="1150">./multimedia.jl:163</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="1151" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1152"> &#91;40&#93; stringmime&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Bonito.App; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="1153" />
      <span data-jscall-id="1154">    &#64; Base64 /opt/hostedtoolcache/julia/1.11.5/x64/share/julia/stdlib/v1.11/Base64/src/Base64.jl:44</span>
      <br data-jscall-id="1155" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1156"> &#91;41&#93; display_dict&#40;x::Bonito.App; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="1157" />
      <span data-jscall-id="1158">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/utilities/utilities.jl:576</span>
      <br data-jscall-id="1159" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1160"> &#91;42&#93; invokelatest&#40;::Any, ::Any, ::Vararg&#123;Any&#125;; kwargs::&#64;Kwargs&#123;context::Pair&#123;Symbol, Bool&#125;&#125;&#41;</span>
      <br data-jscall-id="1161" />
      <span data-jscall-id="1162">    &#64; Base 
        <a href="vscode://file/./essentials.jl:1057" data-jscall-id="1163">./essentials.jl:1057</a>
      </span>
      <br data-jscall-id="1164" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1165"> &#91;43&#93; runner&#40;::Type&#123;…&#125;, node::MarkdownAST.Node&#123;…&#125;, page::Documenter.Page, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="1166" />
      <span data-jscall-id="1167">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:885</span>
      <br data-jscall-id="1168" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1169"> &#91;44&#93; dispatch&#40;::Type&#123;Documenter.Expanders.ExpanderPipeline&#125;, ::MarkdownAST.Node&#123;Nothing&#125;, ::Vararg&#123;Any&#125;&#41;</span>
      <br data-jscall-id="1170" />
      <span data-jscall-id="1171">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="1172" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1173"> &#91;45&#93; expand&#40;doc::Documenter.Document&#41;</span>
      <br data-jscall-id="1174" />
      <span data-jscall-id="1175">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:59</span>
      <br data-jscall-id="1176" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1177"> &#91;46&#93; runner&#40;::Type&#123;Documenter.Builder.ExpandTemplates&#125;, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="1178" />
      <span data-jscall-id="1179">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/builder_pipeline.jl:224</span>
      <br data-jscall-id="1180" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1181"> &#91;47&#93; dispatch&#40;::Type&#123;Documenter.Builder.DocumentPipeline&#125;, x::Documenter.Document&#41;</span>
      <br data-jscall-id="1182" />
      <span data-jscall-id="1183">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="1184" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1185"> &#91;48&#93; #88</span>
      <br data-jscall-id="1186" />
      <span data-jscall-id="1187">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:275 &#91;inlined&#93;</span>
      <br data-jscall-id="1188" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1189"> &#91;49&#93; withenv&#40;::Documenter.var&#34;#88#90&#34;&#123;Documenter.Document&#125;, ::Pair&#123;String, Nothing&#125;, ::Vararg&#123;Pair&#123;String, Nothing&#125;&#125;&#41;</span>
      <br data-jscall-id="1190" />
      <span data-jscall-id="1191">    &#64; Base 
        <a href="vscode://file/./env.jl:265" data-jscall-id="1192">./env.jl:265</a>
      </span>
      <br data-jscall-id="1193" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1194"> &#91;50&#93; #87</span>
      <br data-jscall-id="1195" />
      <span data-jscall-id="1196">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:274 &#91;inlined&#93;</span>
      <br data-jscall-id="1197" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1198"> &#91;51&#93; cd&#40;f::Documenter.var&#34;#87#89&#34;&#123;Documenter.Document&#125;, dir::String&#41;</span>
      <br data-jscall-id="1199" />
      <span data-jscall-id="1200">    &#64; Base.Filesystem 
        <a href="vscode://file/./file.jl:112" data-jscall-id="1201">./file.jl:112</a>
      </span>
      <br data-jscall-id="1202" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1203"> &#91;52&#93; makedocs&#40;; debug::Bool, format::MarkdownVitepress, kwargs::&#64;Kwargs&#123;…&#125;&#41;</span>
      <br data-jscall-id="1204" />
      <span data-jscall-id="1205">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:273</span>
      <br data-jscall-id="1206" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1207"> &#91;53&#93; make_docs&#40;; pages::Vector&#123;Pair&#123;String, Any&#125;&#125;&#41;</span>
      <br data-jscall-id="1208" />
      <span data-jscall-id="1209">    &#64; Main ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:189</span>
      <br data-jscall-id="1210" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1211"> &#91;54&#93; top-level scope</span>
      <br data-jscall-id="1212" />
      <span data-jscall-id="1213">    &#64; ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:205</span>
      <br data-jscall-id="1214" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1215"> &#91;55&#93; include&#40;mod::Module, _path::String&#41;</span>
      <br data-jscall-id="1216" />
      <span data-jscall-id="1217">    &#64; Base 
        <a href="vscode://file/./Base.jl:557" data-jscall-id="1218">./Base.jl:557</a>
      </span>
      <br data-jscall-id="1219" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1220"> &#91;56&#93; exec_options&#40;opts::Base.JLOptions&#41;</span>
      <br data-jscall-id="1221" />
      <span data-jscall-id="1222">    &#64; Base 
        <a href="vscode://file/./client.jl:323" data-jscall-id="1223">./client.jl:323</a>
      </span>
      <br data-jscall-id="1224" />
    </pre>
  </div>
</div></div><h1 id="Pluto/IJulia" tabindex="-1">Pluto/IJulia <a class="header-anchor" href="#Pluto/IJulia" aria-label="Permalink to &quot;Pluto/IJulia {#Pluto/IJulia}&quot;">​</a></h1><p>Note that the normal interactivity from Makie is preserved with WGLMakie in e.g. Pluto, as long as the Julia session is running. Which brings us to setting up Pluto/IJulia sessions! Locally, WGLMakie should just work out of the box for Pluto/IJulia, but if you&#39;re accessing the notebook from another PC, you must set something like:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">begin</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Bonito</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    some_forwarded_port </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 8080</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    Page</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(listen_url</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;0.0.0.0&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, listen_port</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">some_forwarded_port)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><p>Or also specify a proxy URL, if you have a more complex proxy setup. For more advanced setups consult the <code>?Page</code> docs and <code>Bonito.configure_server!</code>. In the <a href="/previews/PR4630/explanations/headless#Using-WGLMakie">headless</a> documentation, you can also read more about setting up the Bonito server and port forwarding.</p><h2 id="Styling" tabindex="-1">Styling <a class="header-anchor" href="#Styling" aria-label="Permalink to &quot;Styling {#Styling}&quot;">​</a></h2><p>Bonito allows to load arbitrary css, and <code>DOM.xxx</code> wraps all existing HTML tags. So any CSS file can be used, e.g. even libraries like <a href="https://tailwindcss.com/" target="_blank" rel="noreferrer">Tailwind</a> with <code>Asset</code>:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">TailwindCSS </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Bonito</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Asset</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/path/to/tailwind.min.css&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Bonito also offers the <code>Styles</code> type, which allows to define whole stylesheets and assign them to any DOM object. That&#39;s how Bonito creates styleable components:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">Rows</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(args</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">div</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(args</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, style</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Styles</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;display&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;grid&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;grid-template-rows&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;fr&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;grid-template-columns&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;repeat(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$(length(args))</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">, fr)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span></code></pre></div><p>This Style object will only be inserted one time into the DOM in one Session, and subsequent uses will just give the div the same class.</p><p>Note, that Bonito already defines something like the above <code>Rows</code>:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Colors</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Bonito</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">App</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> session</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Session</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    hue_slider </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Slider</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">360</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    color_swatch </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">div</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(class</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;h-6 w-6 p-2 m-2 rounded shadow&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    onjs</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(session, hue_slider</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">value, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">js</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">hue</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">){</span></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">        $</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(color_swatch).style.backgroundColor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;hsl(&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> +</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> hue </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">+</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;,60%,50%)&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    }</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    return</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Row</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(hue_slider, color_swatch)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="d3e1f40f-8c8d-4f9b-85c9-446d1a1908bb" data-jscall-id="subsession-application-dom">
  <div>
    <style>.style_2 {
  justify-items: legacy;
  align-items: legacy;
  height: 100%;
  display: grid;
  align-content: normal;
  grid-gap: 10px;
  grid-template-rows: 1fr;
  justify-content: normal;
  grid-template-columns: repeat(2, 1fr);
  width: 100%;
  grid-template-areas: none;
}
</style>
  </div>
  <div>
    <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/bc41c34ebce4defa2b59e1384936a1766b94f876-11990912823188127482.bin').then(msgs=> Bonito.init_session('d3e1f40f-8c8d-4f9b-85c9-446d1a1908bb', msgs, 'sub', false));
    })
<\/script>
    <div class=" style_2" style="" data-jscall-id="1226">
      <input step="1" max="361" min="1" style="styles" data-jscall-id="1227" value="1" oninput="" type="range" />
      <div class="h-6 w-6 p-2 m-2 rounded shadow" data-jscall-id="1225"></div>
    </div>
  </div>
</div></div><p>Bonito also offers a styleable Card component:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Markdown</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">App</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> session</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Session</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # We can now use this wherever we want:</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    fig </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">300</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">300</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    contour</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(fig[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">rand</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    card </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Card</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Grid</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        Centered</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">h1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Hello&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">); style</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Styles</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;grid-column&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;1 / 3&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)),</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        StylableSlider</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; style</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Styles</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;grid-column&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;1 / 3&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)),</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">img</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(src</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;https://julialang.org/assets/infra/logo.svg&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">),</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        fig; columns</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;1fr 1fr&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, justify_items</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;stretch&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ))</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # Markdown creates a DOM as well, and you can interpolate</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # arbitrary jsrender&#39;able elements in there:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">div</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(card)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="dab1ef9f-0508-4fee-a79d-2c52be713194" data-jscall-id="subsession-application-dom">
  <div>
    <style>.style_3 {
  justify-items: center;
  align-items: center;
  height: 100%;
  display: grid;
  align-content: center;
  grid-gap: 10px;
  grid-template-rows: none;
  justify-content: center;
  grid-template-columns: 1fr;
  width: 100%;
  grid-column: 1 / 3;
  grid-template-areas: none;
}
.style_4 {
  align-items: center;
  grid-column: 1 / 3;
  display: grid;
  background-color: transparent;
  grid-template-columns: 1fr;
  padding-right: 9.5px;
  position: relative;
  margin: 5px;
  grid-template-rows: 15px;
  padding-left: 9.5px;
}
.style_5 {
  height: 9.5px;
  border: 1px solid #ccc;
  background-color: #ddd;
  position: absolute;
  width: 0px;
  border-radius: 3px;
}
.style_6 {
  left: -7.5px;
  height: 15px;
  border: 1px solid #ccc;
  background-color: #fff;
  position: absolute;
  width: 15px;
  border-radius: 50%;
  cursor: pointer;
}
.style_7 {
  height: 7.5px;
  border: 1px solid #ccc;
  background-color: #eee;
  position: absolute;
  width: 100%;
  border-radius: 3px;
}
</style>
  </div>
  <div>
    <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/082b6bb22c06b09f025ddebe7736f275f303034a-13082433270914795784.bin').then(msgs=> Bonito.init_session('dab1ef9f-0508-4fee-a79d-2c52be713194', msgs, 'sub', false));
    })
<\/script>
    <pre class="backtrace" style="overflow-x: auto;" data-jscall-id="1238">
      <h3 style="color: red;" data-jscall-id="1239">Failed to resolve wgl_renderobject:
&#91;ComputeEdge&#93; wgl_renderobject, wgl_update_obs &#61; #71&#40;&#40;positions_transformed_f32c, vertex_color, uniform_color, uniform_colormap, uniform_colorrange, nan_color, highclip_color, lowclip_color, pattern, strokewidth, glowwidth, glowcolor, converted_rotation, converted_strokecolor, marker_offset, sdf_marker_shape, glyph_data, depth_shift, atlas, markerspace, visible, transform_marker, f32c_scale, model_f32c, uniform_clip_planes, uniform_num_clip_planes, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:110
&#91;ComputeEdge&#93; glyph_data &#61; #86&#40;&#40;glyphindices, font_per_char, glyph_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:332
&#91;ComputeEdge&#93; glyph_scales &#61; #85&#40;&#40;glyphindices, text_blocks, text_scales, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329
  with edge inputs:
    glyphindices &#61; UInt64&#91;&#93;
    text_blocks &#61; UnitRange&#123;Int64&#125;&#91;&#93;
    text_scales &#61; Vec&#123;2, Float32&#125;&#91;&#93;
Triggered by update of:
  position, text, arg1, labelsize, fonts, labelfont, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, labelsize, fonts, labelfont, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor, strokewidth, position, text, arg1, labelsize, fonts, labelfont, align, rotation, justification, lineheight, word_wrap_width, offset, fonts, color, colorscale, alpha, colorrange, colorscale, color, colorscale, alpha, colormap, alpha, nan_color, lowclip, colormap, alpha, highclip, colormap, alpha, colormap, alpha, strokecolor or strokewidth
Due to ERROR: MethodError: no method matching map_per_glyph&#40;::Vector&#123;UInt64&#125;, ::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Type&#123;Vec&#123;2, Float32&#125;&#125;, ::Vector&#123;Vec&#123;2, Float32&#125;&#125;&#41;
The function &#96;map_per_glyph&#96; exists, but no method is defined for this combination of argument types.

Closest candidates are:
  map_per_glyph&#40;&#33;Matched::Vector&#123;UnitRange&#123;Int64&#125;&#125;, ::Any, ::Any&#41;
   &#64; Makie ~/work/Makie.jl/Makie.jl/src/basic_recipes/text.jl:118
</h3>
      <span data-jscall-id="1240">Stacktrace:</span>
      <br data-jscall-id="1241" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1242">  &#91;1&#93; &#40;::WGLMakie.var&#34;#85#87&#34;&#41;&#40;::&#64;NamedTuple&#123;…&#125;, changed::&#64;NamedTuple&#123;…&#125;, last::Nothing&#41;</span>
      <br data-jscall-id="1243" />
      <span data-jscall-id="1244">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:329</span>
      <br data-jscall-id="1245" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1246">  &#91;2&#93; ComputePipeline.TypedEdge&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="1247" />
      <span data-jscall-id="1248">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:120</span>
      <br data-jscall-id="1249" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1250">  &#91;3&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="1251" />
      <span data-jscall-id="1252">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:568</span>
      <br data-jscall-id="1253" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1254">  &#91;4&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="1255" />
      <span data-jscall-id="1256">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="1257" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1258">  &#91;5&#93; foreach</span>
      <br data-jscall-id="1259" />
      <span data-jscall-id="1260">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3187" data-jscall-id="1261">./abstractarray.jl:3187</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="1262" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1263">  &#91;6&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="1264" />
      <span data-jscall-id="1265">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:563</span>
      <br data-jscall-id="1266" />
      <span data-jscall-id="1267">--- the above 3 lines are repeated 1 more time ---</span>
      <br data-jscall-id="1268" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1269"> &#91;10&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="1270" />
      <span data-jscall-id="1271">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="1272" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1273"> &#91;11&#93; resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="1274" />
      <span data-jscall-id="1275">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:546</span>
      <br data-jscall-id="1276" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1277"> &#91;12&#93; getindex</span>
      <br data-jscall-id="1278" />
      <span data-jscall-id="1279">    &#64; ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:466 &#91;inlined&#93;</span>
      <br data-jscall-id="1280" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1281"> &#91;13&#93; create_wgl_renderobject&#40;callback::typeof&#40;WGLMakie.scatter_program&#41;, attr::ComputePipeline.ComputeGraph, inputs::Vector&#123;…&#125;&#41;</span>
      <br data-jscall-id="1282" />
      <span data-jscall-id="1283">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:130</span>
      <br data-jscall-id="1284" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1285"> &#91;14&#93; create_shader&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;2, Float32&#125;&#125;&#125;&#125;&#41;</span>
      <br data-jscall-id="1286" />
      <span data-jscall-id="1287">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:369</span>
      <br data-jscall-id="1288" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1289"> &#91;15&#93; serialize_three&#40;scene::Scene, plot::MakieCore.Text&#123;Tuple&#123;Vector&#123;Point&#123;2, Float32&#125;&#125;&#125;&#125;&#41;</span>
      <br data-jscall-id="1290" />
      <span data-jscall-id="1291">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:8</span>
      <br data-jscall-id="1292" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1293"> &#91;16&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
      <br data-jscall-id="1294" />
      <span data-jscall-id="1295">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:230</span>
      <br data-jscall-id="1296" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1297"> &#91;17&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
      <br data-jscall-id="1298" />
      <span data-jscall-id="1299">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:235</span>
      <br data-jscall-id="1300" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1301"> &#91;18&#93; serialize_plots</span>
      <br data-jscall-id="1302" />
      <span data-jscall-id="1303">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:227 &#91;inlined&#93;</span>
      <br data-jscall-id="1304" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1305"> &#91;19&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="1306" />
      <span data-jscall-id="1307">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:207</span>
      <br data-jscall-id="1308" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1309"> &#91;20&#93; &#40;::WGLMakie.var&#34;#47#54&#34;&#41;&#40;child::Scene&#41;</span>
      <br data-jscall-id="1310" />
      <span data-jscall-id="1311">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="1312" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1313"> &#91;21&#93; iterate</span>
      <br data-jscall-id="1314" />
      <span data-jscall-id="1315">    &#64; 
        <a href="vscode://file/./generator.jl:48" data-jscall-id="1316">./generator.jl:48</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="1317" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1318"> &#91;22&#93; _collect&#40;c::Vector&#123;…&#125;, itr::Base.Generator&#123;…&#125;, ::Base.EltypeUnknown, isz::Base.HasShape&#123;…&#125;&#41;</span>
      <br data-jscall-id="1319" />
      <span data-jscall-id="1320">    &#64; Base 
        <a href="vscode://file/./array.jl:811" data-jscall-id="1321">./array.jl:811</a>
      </span>
      <br data-jscall-id="1322" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1323"> &#91;23&#93; collect_similar</span>
      <br data-jscall-id="1324" />
      <span data-jscall-id="1325">    &#64; 
        <a href="vscode://file/./array.jl:720" data-jscall-id="1326">./array.jl:720</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="1327" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1328"> &#91;24&#93; map</span>
      <br data-jscall-id="1329" />
      <span data-jscall-id="1330">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3371" data-jscall-id="1331">./abstractarray.jl:3371</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="1332" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1333"> &#91;25&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="1334" />
      <span data-jscall-id="1335">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="1336" />
      <span data-jscall-id="1337">--- the above 6 lines are repeated 1 more time ---</span>
      <br data-jscall-id="1338" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1339"> &#91;32&#93; three_display&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="1340" />
      <span data-jscall-id="1341">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/three_plot.jl:33</span>
      <br data-jscall-id="1342" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1343"> &#91;33&#93; render_with_init&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="1344" />
      <span data-jscall-id="1345">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:91</span>
      <br data-jscall-id="1346" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1347"> &#91;34&#93; jsrender</span>
      <br data-jscall-id="1348" />
      <span data-jscall-id="1349">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:124 &#91;inlined&#93;</span>
      <br data-jscall-id="1350" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1351"> &#91;35&#93; jsrender&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, fig::Figure&#41;</span>
      <br data-jscall-id="1352" />
      <span data-jscall-id="1353">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:129</span>
      <br data-jscall-id="1354" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1355"> &#91;36&#93; render_node&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, node::Hyperscript.Node&#123;Hyperscript.HTMLSVG&#125;&#41;</span>
      <br data-jscall-id="1356" />
      <span data-jscall-id="1357">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/rendering/hyperscript_integration.jl:171</span>
      <br data-jscall-id="1358" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1359"> &#91;37&#93; jsrender&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, node::Hyperscript.Node&#123;Hyperscript.HTMLSVG&#125;&#41;</span>
      <br data-jscall-id="1360" />
      <span data-jscall-id="1361">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/rendering/hyperscript_integration.jl:201</span>
      <br data-jscall-id="1362" />
      <span data-jscall-id="1363">--- the above 2 lines are repeated 2 more times ---</span>
      <br data-jscall-id="1364" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1365"> &#91;42&#93; rendered_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App, target::HTTP.Messages.Request&#41;</span>
      <br data-jscall-id="1366" />
      <span data-jscall-id="1367">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/app.jl:43</span>
      <br data-jscall-id="1368" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1369"> &#91;43&#93; rendered_dom</span>
      <br data-jscall-id="1370" />
      <span data-jscall-id="1371">    &#64; ~/.julia/packages/Bonito/PiA4w/src/app.jl:39 &#91;inlined&#93;</span>
      <br data-jscall-id="1372" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1373"> &#91;44&#93; session_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App; init::Bool, html_document::Bool&#41;</span>
      <br data-jscall-id="1374" />
      <span data-jscall-id="1375">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/session.jl:363</span>
      <br data-jscall-id="1376" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1377"> &#91;45&#93; session_dom</span>
      <br data-jscall-id="1378" />
      <span data-jscall-id="1379">    &#64; ~/.julia/packages/Bonito/PiA4w/src/session.jl:362 &#91;inlined&#93;</span>
      <br data-jscall-id="1380" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1381"> &#91;46&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App; parent::Bonito.Session&#123;Bonito.NoConnection&#125;&#41;</span>
      <br data-jscall-id="1382" />
      <span data-jscall-id="1383">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:70</span>
      <br data-jscall-id="1384" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1385"> &#91;47&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App&#41;</span>
      <br data-jscall-id="1386" />
      <span data-jscall-id="1387">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:63</span>
      <br data-jscall-id="1388" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1389"> &#91;48&#93; show</span>
      <br data-jscall-id="1390" />
      <span data-jscall-id="1391">    &#64; ~/.julia/packages/Bonito/PiA4w/src/display.jl:97 &#91;inlined&#93;</span>
      <br data-jscall-id="1392" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1393"> &#91;49&#93; __binrepr&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Bonito.App, context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="1394" />
      <span data-jscall-id="1395">    &#64; Base.Multimedia 
        <a href="vscode://file/./multimedia.jl:173" data-jscall-id="1396">./multimedia.jl:173</a>
      </span>
      <br data-jscall-id="1397" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1398"> &#91;50&#93; _textrepr</span>
      <br data-jscall-id="1399" />
      <span data-jscall-id="1400">    &#64; 
        <a href="vscode://file/./multimedia.jl:163" data-jscall-id="1401">./multimedia.jl:163</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="1402" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1403"> &#91;51&#93; stringmime&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Bonito.App; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="1404" />
      <span data-jscall-id="1405">    &#64; Base64 /opt/hostedtoolcache/julia/1.11.5/x64/share/julia/stdlib/v1.11/Base64/src/Base64.jl:44</span>
      <br data-jscall-id="1406" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1407"> &#91;52&#93; display_dict&#40;x::Bonito.App; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="1408" />
      <span data-jscall-id="1409">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/utilities/utilities.jl:576</span>
      <br data-jscall-id="1410" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1411"> &#91;53&#93; invokelatest&#40;::Any, ::Any, ::Vararg&#123;Any&#125;; kwargs::&#64;Kwargs&#123;context::Pair&#123;Symbol, Bool&#125;&#125;&#41;</span>
      <br data-jscall-id="1412" />
      <span data-jscall-id="1413">    &#64; Base 
        <a href="vscode://file/./essentials.jl:1057" data-jscall-id="1414">./essentials.jl:1057</a>
      </span>
      <br data-jscall-id="1415" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1416"> &#91;54&#93; runner&#40;::Type&#123;…&#125;, node::MarkdownAST.Node&#123;…&#125;, page::Documenter.Page, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="1417" />
      <span data-jscall-id="1418">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:885</span>
      <br data-jscall-id="1419" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1420"> &#91;55&#93; dispatch&#40;::Type&#123;Documenter.Expanders.ExpanderPipeline&#125;, ::MarkdownAST.Node&#123;Nothing&#125;, ::Vararg&#123;Any&#125;&#41;</span>
      <br data-jscall-id="1421" />
      <span data-jscall-id="1422">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="1423" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1424"> &#91;56&#93; expand&#40;doc::Documenter.Document&#41;</span>
      <br data-jscall-id="1425" />
      <span data-jscall-id="1426">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:59</span>
      <br data-jscall-id="1427" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1428"> &#91;57&#93; runner&#40;::Type&#123;Documenter.Builder.ExpandTemplates&#125;, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="1429" />
      <span data-jscall-id="1430">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/builder_pipeline.jl:224</span>
      <br data-jscall-id="1431" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1432"> &#91;58&#93; dispatch&#40;::Type&#123;Documenter.Builder.DocumentPipeline&#125;, x::Documenter.Document&#41;</span>
      <br data-jscall-id="1433" />
      <span data-jscall-id="1434">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="1435" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1436"> &#91;59&#93; #88</span>
      <br data-jscall-id="1437" />
      <span data-jscall-id="1438">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:275 &#91;inlined&#93;</span>
      <br data-jscall-id="1439" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1440"> &#91;60&#93; withenv&#40;::Documenter.var&#34;#88#90&#34;&#123;Documenter.Document&#125;, ::Pair&#123;String, Nothing&#125;, ::Vararg&#123;Pair&#123;String, Nothing&#125;&#125;&#41;</span>
      <br data-jscall-id="1441" />
      <span data-jscall-id="1442">    &#64; Base 
        <a href="vscode://file/./env.jl:265" data-jscall-id="1443">./env.jl:265</a>
      </span>
      <br data-jscall-id="1444" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1445"> &#91;61&#93; #87</span>
      <br data-jscall-id="1446" />
      <span data-jscall-id="1447">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:274 &#91;inlined&#93;</span>
      <br data-jscall-id="1448" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1449"> &#91;62&#93; cd&#40;f::Documenter.var&#34;#87#89&#34;&#123;Documenter.Document&#125;, dir::String&#41;</span>
      <br data-jscall-id="1450" />
      <span data-jscall-id="1451">    &#64; Base.Filesystem 
        <a href="vscode://file/./file.jl:112" data-jscall-id="1452">./file.jl:112</a>
      </span>
      <br data-jscall-id="1453" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1454"> &#91;63&#93; makedocs&#40;; debug::Bool, format::MarkdownVitepress, kwargs::&#64;Kwargs&#123;…&#125;&#41;</span>
      <br data-jscall-id="1455" />
      <span data-jscall-id="1456">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:273</span>
      <br data-jscall-id="1457" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1458"> &#91;64&#93; make_docs&#40;; pages::Vector&#123;Pair&#123;String, Any&#125;&#125;&#41;</span>
      <br data-jscall-id="1459" />
      <span data-jscall-id="1460">    &#64; Main ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:189</span>
      <br data-jscall-id="1461" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1462"> &#91;65&#93; top-level scope</span>
      <br data-jscall-id="1463" />
      <span data-jscall-id="1464">    &#64; ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:205</span>
      <br data-jscall-id="1465" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1466"> &#91;66&#93; include&#40;mod::Module, _path::String&#41;</span>
      <br data-jscall-id="1467" />
      <span data-jscall-id="1468">    &#64; Base 
        <a href="vscode://file/./Base.jl:557" data-jscall-id="1469">./Base.jl:557</a>
      </span>
      <br data-jscall-id="1470" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="1471"> &#91;67&#93; exec_options&#40;opts::Base.JLOptions&#41;</span>
      <br data-jscall-id="1472" />
      <span data-jscall-id="1473">    &#64; Base 
        <a href="vscode://file/./client.jl:323" data-jscall-id="1474">./client.jl:323</a>
      </span>
      <br data-jscall-id="1475" />
    </pre>
  </div>
</div></div><p>Hopefully, over time there will be helper libraries with lots of stylised elements like the above, to make flashy dashboards with Bonito + WGLMakie.</p><h1 id="Export" tabindex="-1">Export <a class="header-anchor" href="#Export" aria-label="Permalink to &quot;Export {#Export}&quot;">​</a></h1><p>Documenter just renders the plots + Page as html, so if you want to inline WGLMakie/Bonito objects into your own page, one can just use something like this:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> WGLMakie, Bonito, FileIO</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">WGLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">activate!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">open</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;index.html&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;w&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> io</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    println</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(io, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &lt;html&gt;</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">        &lt;head&gt;</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">        &lt;/head&gt;</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">        &lt;body&gt;</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    Page</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(exportable</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">true</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, offline</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">true</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # Then, you can just inline plots or whatever you want :)</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # Of course it would make more sense to put this into a single app</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    app </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> App</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">        C</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x;kw</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Card</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x; height</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;fit-content&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, width</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;fit-content&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, kw</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        figure </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (; size</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">300</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">300</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        f1 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> scatter</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; figure)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        f2 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mesh</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">load</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">assetpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;brain.stl&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)); figure)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        C</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(DOM</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">div</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">            Bonito</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">StylableSlider</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">),</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">            Row</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">C</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f1), </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">C</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f2))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        ); padding</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;30px&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, margin</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;15px&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    end</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    show</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(io, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">MIME</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;text/html&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(), app)</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">    # or anything else from Bonito, or that can be displayed as html:</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    println</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(io, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">        &lt;/body&gt;</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &lt;/html&gt;</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div>`,51))])}const f=e(c,[["render",k]]);export{m as __pageData,f as default};
