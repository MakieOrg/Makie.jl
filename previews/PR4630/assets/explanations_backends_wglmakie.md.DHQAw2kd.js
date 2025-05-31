import{_ as l,C as e,c as h,o as p,aA as a,j as i,G as t,a as k,w as d}from"./chunks/framework.BPrVvvt3.js";const C=JSON.parse('{"title":"WGLMakie","description":"","frontmatter":{},"headers":[],"relativePath":"explanations/backends/wglmakie.md","filePath":"explanations/backends/wglmakie.md","lastUpdated":null}'),r={name:"explanations/backends/wglmakie.md"},o={class:"jldocstring custom-block",open:""};function c(g,s,E,y,u,F){const n=e("Badge");return p(),h("div",null,[s[4]||(s[4]=a('<h1 id="WGLMakie" tabindex="-1">WGLMakie <a class="header-anchor" href="#WGLMakie" aria-label="Permalink to &quot;WGLMakie {#WGLMakie}&quot;">​</a></h1><p><a href="https://github.com/MakieOrg/Makie.jl/tree/master/WGLMakie" target="_blank" rel="noreferrer">WGLMakie</a> is the web-based backend, which is mostly implemented in Julia right now. WGLMakie uses <a href="https://github.com/SimonDanisch/Bonito.jl" target="_blank" rel="noreferrer">Bonito</a> to generate the HTML and JavaScript for displaying the plots. On the JavaScript side, we use <a href="https://threejs.org/" target="_blank" rel="noreferrer">ThreeJS</a> and <a href="https://en.wikipedia.org/wiki/WebGL" target="_blank" rel="noreferrer">WebGL</a> to render the plots. Moving more of the implementation to JavaScript is currently the goal and will give us a better JavaScript API, and more interaction without a running Julia server.</p><div class="warning custom-block"><p class="custom-block-title">Warning</p><p>WGLMakie can be considered experimental because the JavaScript API isn&#39;t stable yet and the notebook integration isn&#39;t perfect yet, but all plot types should work, and therefore all recipes, but there are certain caveats</p></div><h4 id="Browser-Support" tabindex="-1">Browser Support <a class="header-anchor" href="#Browser-Support" aria-label="Permalink to &quot;Browser Support {#Browser-Support}&quot;">​</a></h4><h5 id="IJulia" tabindex="-1">IJulia <a class="header-anchor" href="#IJulia" aria-label="Permalink to &quot;IJulia {#IJulia}&quot;">​</a></h5><ul><li><p>Bonito now uses the IJulia connection, and therefore can be used even with complex proxy setup without any additional setup</p></li><li><p>reload of the page isn&#39;t supported, if you reload, you need to re-execute all cells and make sure that <code>Page()</code> is executed first.</p></li></ul><h4 id="JupyterHub-/-Jupyterlab-/-Binder" tabindex="-1">JupyterHub / Jupyterlab / Binder <a class="header-anchor" href="#JupyterHub-/-Jupyterlab-/-Binder" aria-label="Permalink to &quot;JupyterHub / Jupyterlab / Binder {#JupyterHub-/-Jupyterlab-/-Binder}&quot;">​</a></h4><ul><li>WGLMakie should mostly work with a websocket connection. Bonito tries to <a href="https://github.com/SimonDanisch/Bonito.jl/blob/master/src/server-defaults.jl" target="_blank" rel="noreferrer">infer the proxy setup</a> needed to connect to the julia process. On local jupyterlab instances, this should work without problem. On hosted instances one will likely need to have <a href="https://jupyter-server-proxy.readthedocs.io/en/latest/arbitrary-ports-hosts.html#with-jupyterhub" target="_blank" rel="noreferrer"><code>jupyter-server-proxy</code></a> installed, and then execute something like <code>Page(; listen_port=9091, proxy_url=&quot;&lt;jhub-instance&gt;.com/user/&lt;username&gt;/proxy/9091&quot;)</code>. Also see: <ul><li><p><a href="https://github.com/MakieOrg/Makie.jl/issues/2464" target="_blank" rel="noreferrer">issue #2464</a></p></li><li><p><a href="https://github.com/MakieOrg/Makie.jl/issues/2405" target="_blank" rel="noreferrer">issue #2405</a></p></li></ul></li></ul><h4 id="Pluto" tabindex="-1">Pluto <a class="header-anchor" href="#Pluto" aria-label="Permalink to &quot;Pluto {#Pluto}&quot;">​</a></h4><ul><li><p>still uses Bonito&#39;s Websocket connection, so needs extra setup for remote servers.</p></li><li><p>reload of the page isn&#39;t supported, if you reload, you need to re-execute all cells and make sure that <code>Page()</code> is executed first.</p></li><li><p>static html export not fully working yet</p></li></ul><h4 id="JuliaHub" tabindex="-1">JuliaHub <a class="header-anchor" href="#JuliaHub" aria-label="Permalink to &quot;JuliaHub {#JuliaHub}&quot;">​</a></h4><ul><li><p>VSCode in the browser should work out of the box.</p></li><li><p>Pluto in JuliaHub still has a <a href="https://github.com/SimonDanisch/Bonito.jl/issues/140" target="_blank" rel="noreferrer">problem</a> with the WebSocket connection. So, you will see a plot, but interaction doesn&#39;t work.</p></li></ul><h4 id="Browser-Support-2" tabindex="-1">Browser Support <a class="header-anchor" href="#Browser-Support-2" aria-label="Permalink to &quot;Browser Support {#Browser-Support-2}&quot;">​</a></h4><p>Some browsers may have only WebGL 1.0, or need extra steps to enable WebGL, but in general, all modern browsers on <a href="https://www.lambdatest.com/web-technologies/webgl2" target="_blank" rel="noreferrer">mobile and desktop should support WebGL 2.0</a>. Safari users may need to <a href="https://discussions.apple.com/thread/8655829" target="_blank" rel="noreferrer">enable</a> WebGL, though. If you end up stuck on WebGL 1.0, the main missing feature will be <code>volume</code> &amp; <code>contour(volume)</code>.</p><h2 id="Activation-and-screen-config" tabindex="-1">Activation and screen config <a class="header-anchor" href="#Activation-and-screen-config" aria-label="Permalink to &quot;Activation and screen config {#Activation-and-screen-config}&quot;">​</a></h2><p>Activate the backend by calling <code>WGLMakie.activate!()</code> with the following options:</p>',16)),i("details",o,[i("summary",null,[s[0]||(s[0]=i("a",{id:"WGLMakie.activate!",href:"#WGLMakie.activate!"},[i("span",{class:"jlbinding"},"WGLMakie.activate!")],-1)),s[1]||(s[1]=k()),t(n,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),s[3]||(s[3]=a('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">WGLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">activate!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; screen_config</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Sets WGLMakie as the currently active backend and also allows to quickly set the <code>screen_config</code>. Note, that the <code>screen_config</code> can also be set permanently via <code>Makie.set_theme!(WGLMakie=(screen_config...,))</code>.</p><p><strong>Arguments one can pass via <code>screen_config</code>:</strong></p><ul><li><p><code>framerate = 30</code>: Set framerate (frames per second) to a higher number for smoother animations, or to a lower to use less resources.</p></li><li><p><code>resize_to = nothing</code>: Resize the canvas to the parent element with <code>resize_to=:parent</code>, or to the body if <code>resize_to = :body</code>. The default <code>nothing</code>, will resize nothing. A tuple is allowed too, with the same values just for width/height.</p></li></ul>',4)),t(n,{type:"info",class:"source-link",text:"source"},{default:d(()=>s[2]||(s[2]=[i("a",{href:"https://github.com/MakieOrg/Makie.jl/blob/3da2bc970eb27db154e3f2a4d0d4318e2726067d/WGLMakie/src/WGLMakie.jl#L48-L57",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1,__:[2]})]),s[5]||(s[5]=a(`<h2 id="Output" tabindex="-1">Output <a class="header-anchor" href="#Output" aria-label="Permalink to &quot;Output {#Output}&quot;">​</a></h2><p>You can use Bonito and WGLMakie in Pluto, IJulia, Webpages and Documenter to create interactive apps and dashboards, serve them on live webpages, or export them to static HTML.</p><p>This tutorial will run through the different modes and what kind of limitations to expect.</p><h3 id="Page" tabindex="-1">Page <a class="header-anchor" href="#Page" aria-label="Permalink to &quot;Page {#Page}&quot;">​</a></h3><p><code>Page()</code> can be used to reset the Bonito state needed for multipage output like it&#39;s the case for <code>Documenter</code> or the various notebooks (IJulia/Pluto/etc). Previously, it was necessary to always insert and display the <code>Page</code> call in notebooks, but now the call to <code>Page()</code> is optional and doesn&#39;t need to be displayed. What it does is purely reset the state for a new multi-page output, which is usually the case for <code>Documenter</code>, which creates multiple pages in one Julia session, or you can use it to reset the state in notebooks, e.g. after a page reload. <code>Page(exportable=true, offline=true)</code> can be used to force inlining all data &amp; js dependencies, so that everything can be loaded in a single HTML object without a running Julia process. The defaults should already be chosen this way for e.g. Documenter, so this should mostly be used for e.g. <code>Pluto</code> offline export (which is currently not fully supported, but should be soon).</p><p>Here is an example of how to use this in Franklin:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> WGLMakie</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Bonito, Markdown</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Page</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># for Franklin, you still need to configure</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">WGLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">activate!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Makie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">inline!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">true</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># Make sure to inline plots into Documenter output!</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatter</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, color</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div><div>
  <div class="bonito-fragment" id="e44ee81a-c7d2-4cd7-bd9c-e6a9f1b4ab5a" data-jscall-id="root">
    <div>
      <script src="bonito/js/Bonito.bundled15432232505923397289.js" type="module"><\/script>
      <style></style>
    </div>
    <div>
      <script type="module">Bonito.lock_loading(() => Bonito.init_session('e44ee81a-c7d2-4cd7-bd9c-e6a9f1b4ab5a', null, 'root', false))<\/script>
      <span></span>
    </div>
  </div>
  <div class="bonito-fragment" id="8e91b3e8-a899-44e9-a6a7-c2a1646113b3" data-jscall-id="subsession-application-dom">
    <div>
      <style></style>
    </div>
    <div>
      <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/86a171e004fc4c187843d3d37a82c62948248d9e-6840744861517073069.bin').then(msgs=> Bonito.init_session('8e91b3e8-a899-44e9-a6a7-c2a1646113b3', msgs, 'sub', false));
    })
<\/script>
      <div style="width: 100%; height: 100%" data-jscall-id="1">
        <canvas data-jp-suppress-context-menu style="display: block" data-jscall-id="2" data-lm-suppress-shortcuts="true" tabindex="0"></canvas>
      </div>
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
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div><div class="bonito-fragment" id="acb0828b-e344-4b52-b117-db173c51cf07" data-jscall-id="subsession-application-dom">
  <div>
    <style></style>
  </div>
  <div>
    <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/cfb2eb2aab63a9ee2a9065f3364367f292903a20-920422029097975044.bin').then(msgs=> Bonito.init_session('acb0828b-e344-4b52-b117-db173c51cf07', msgs, 'sub', false));
    })
<\/script>
    <div style="width: 100%; height: 100%" data-jscall-id="3">
      <canvas data-jp-suppress-context-menu style="display: block" data-jscall-id="4" data-lm-suppress-shortcuts="true" tabindex="0"></canvas>
    </div>
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
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="eb3deefd-91b5-4bcc-9dc2-9390548f30d8" data-jscall-id="subsession-application-dom">
  <div>
    <style></style>
  </div>
  <div>
    <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/ac2cdeeea64b2947ef74381ee56b216df139f628-11701130204037148268.bin').then(msgs=> Bonito.init_session('eb3deefd-91b5-4bcc-9dc2-9390548f30d8', msgs, 'sub', false));
    })
<\/script>
    <pre class="backtrace" style="overflow-x: auto;" data-jscall-id="9">
      <h3 style="color: red;" data-jscall-id="10">Failed to resolve wgl_renderobject:
&#91;ComputeEdge&#93; wgl_renderobject, wgl_update_obs &#61; #75&#40;&#40;space, vertex_color, uniform_color, uniform_colormap, uniform_colorrange, pattern, modelinv, algorithm, absorption, isovalue, isorange, diffuse, specular, shininess, backlight, depth_shift, lowclip_color, highclip_color, nan_color, uniform_model, uniform_num_clip_planes, uniform_clip_planes, visible, &#41;, changed, cached&#41;
  &#64; /home/runner/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:112
  with edge inputs:
    space &#61; :data
    vertex_color &#61; false
    uniform_color &#61; Float32&#91;0.8361665 0.30392346 … 0.23905702 0.6624621; 0.045188095 0.6407775 … 0.3660472 0.94002503; … ; 0.33517623 0.5905508 … 0.30993697 0.2679726; 0.045323353 0.60245454 … 0.75061005 0.42921057;;; 0.9570539 0.868212 … 0.7028657 0.7763234; 0.9629398 0.34344333 … 0.6246795 0.082634956; … ; 0.02269622 0.8188902 … 0.32884806 0.2932286; 0.86312115 0.9857281 … 0.71014035 0.4125797;;; 0.40008122 0.42472258 … 0.46124175 0.30734825; 0.9564842 0.42987826 … 0.71897227 0.0349782; … ; 0.29928598 0.4124205 … 0.9086682 0.71035254; 0.5718306 0.9442912 … 0.61433536 0.46043298;;; 0.42161733 0.04713232 … 0.4423706 0.34808353; 0.7368471 0.19274661 … 0.7798372 0.3966379; … ; 0.6696427 0.41396752 … 0.9879868 0.14259027; 0.12120741 0.85844874 … 0.89073 0.8749793;;; 0.41861677 0.37953126 … 0.57189596 0.2290753; 0.3784129 0.9925442 … 0.0197354 0.3413353; … ; 0.95816684 0.13565695 … 0.19433036 0.5792562; 0.08747925 0.32130218 … 0.5363709 0.7447573;;; 0.01868214 0.11286179 … 0.4527378 0.07061703; 0.76243794 0.22800419 … 0.48638424 0.07457756; … ; 0.587388 0.35983437 … 0.33854344 0.29356322; 0.6071295 0.96635514 … 0.38411385 0.6448227;;; 0.2146735 0.67891866 … 0.6942081 0.41720235; 0.8567735 0.9123581 … 0.84028673 0.19477658; … ; 0.90779024 0.1502159 … 0.35527053 0.040456153; 0.899976 0.7507993 … 0.32247734 0.9817394;;; 0.73787725 0.79143506 … 0.2830011 0.24727587; 0.54749805 0.35161063 … 0.9007338 0.9067044; … ; 0.024433661 0.9294316 … 0.00527807 0.37277326; 0.22114524 0.51309836 … 0.17007339 0.8552335;;; 0.25793827 0.06214117 … 0.50047904 0.54482263; 0.56236017 0.840739 … 0.38233835 0.111207515; … ; 0.22470519 0.6506384 … 0.4017262 0.106032886; 0.856384 0.5597562 … 0.87373245 0.6590378;;; 0.09654978 0.5723029 … 0.92858267 0.26735696; 0.5889336 0.056337334 … 0.9539094 0.0621085; … ; 0.37083882 0.27798 … 0.1289174 0.73616904; 0.8952941 0.6702238 … 0.8030518 0.48611596&#93;
    uniform_colormap &#61; ColorTypes.RGBA&#123;Float32&#125;&#91;RGBA&#123;Float32&#125;&#40;0.267004f0,0.004874f0,0.329415f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.26854455f0,0.009725964f0,0.3355704f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.2700096f0,0.014881241f0,0.34166285f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.2713982f0,0.020348338f0,0.34769002f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.2727111f0,0.026134951f0,0.3536482f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.2739467f0,0.032250617f0,0.35953856f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.2751067f0,0.03867947f0,0.36535567f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.27618998f0,0.045208905f0,0.3711003f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.27719593f0,0.051496774f0,0.37677062f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.27812532f0,0.057586387f0,0.38236228f0,0.0f0&#41;  …  RGBA&#123;Float32&#125;&#40;0.9041442f0,0.8945863f0,0.09773681f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.91432756f0,0.89585274f0,0.100217335f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.9244422f0,0.897121f0,0.10350526f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.93448746f0,0.8983907f0,0.10754401f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.94446343f0,0.899665f0,0.11227089f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.95436853f0,0.90094453f0,0.11761812f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.96420044f0,0.90223205f0,0.12352078f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.973958f0,0.903529f0,0.12991264f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.98364025f0,0.90483624f0,0.13673599f0,0.0f0&#41;, RGBA&#123;Float32&#125;&#40;0.993248f0,0.906157f0,0.143936f0,0.0f0&#41;&#93;
    uniform_colorrange &#61; Float32&#91;0.0023859786, 0.9984857&#93;
    pattern &#61; false
    modelinv &#61; Float32&#91;0.1 0.0 0.0 0.0; 0.0 0.1 0.0 0.0; 0.0 0.0 0.1 0.0; 0.0 0.0 0.0 1.0&#93;
    algorithm &#61; 7
    absorption &#61; 1.0f0
    isovalue &#61; 0.5f0
    isorange &#61; 0.05f0
    diffuse &#61; Float32&#91;1.0, 1.0, 1.0&#93;
    specular &#61; Float32&#91;0.2, 0.2, 0.2&#93;
    shininess &#61; 32.0f0
    backlight &#61; 0.0f0
    depth_shift &#61; 0.0f0
    lowclip_color &#61; RGBA&#123;Float32&#125;&#40;0.267004f0,0.004874f0,0.329415f0,0.0f0&#41;
    highclip_color &#61; RGBA&#123;Float32&#125;&#40;0.993248f0,0.906157f0,0.143936f0,0.0f0&#41;
    nan_color &#61; RGBA&#123;Float32&#125;&#40;0.0f0,0.0f0,0.0f0,0.0f0&#41;
    uniform_model &#61; Float32&#91;10.0 0.0 0.0 0.0; 0.0 10.0 0.0 0.0; 0.0 0.0 10.0 0.0; 0.0 0.0 0.0 1.0&#93;
    uniform_num_clip_planes &#61; 0
    uniform_clip_planes &#61; Vec&#123;4, Float32&#125;&#91;&#91;0.0, 0.0, 0.0, -1.0f9&#93;, &#91;0.0, 0.0, 0.0, -1.0f9&#93;, &#91;0.0, 0.0, 0.0, -1.0f9&#93;, &#91;0.0, 0.0, 0.0, -1.0f9&#93;, &#91;0.0, 0.0, 0.0, -1.0f9&#93;, &#91;0.0, 0.0, 0.0, -1.0f9&#93;, &#91;0.0, 0.0, 0.0, -1.0f9&#93;, &#91;0.0, 0.0, 0.0, -1.0f9&#93;&#93;
    visible &#61; true
Triggered by update of:
  space, arg1, arg1, arg1, arg1, colorscale, alpha, arg1, arg1, arg1, arg1, colorscale, alpha, interpolate, arg1, arg1, arg1, arg1, colorscale, alpha, colormap, alpha, colorrange, colorscale, arg1, arg1, arg1, arg1, colorscale, alpha, colormap, alpha, colormap, alpha, colorrange, colorscale, arg1, arg1, arg1, arg1, colorscale, alpha, colormap, alpha, arg1, arg1, arg1, arg1, colorscale, alpha, interpolate, arg1, arg1, arg1, arg1, colorscale, alpha, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, model, algorithm, absorption, isovalue, isorange, diffuse, specular, shininess, backlight, depth_shift, lowclip, colormap, alpha, highclip, colormap, alpha, nan_color, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, model, clip_planes, space, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, model, clip_planes, space, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, arg1, model or visible
Due to ERROR: Type Int64 not supported</h3>
      <span data-jscall-id="11">Stacktrace:</span>
      <br data-jscall-id="12" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="13">  &#91;1&#93; error&#40;s::String&#41;</span>
      <br data-jscall-id="14" />
      <span data-jscall-id="15">    &#64; Base 
        <a href="vscode://file/./error.jl:35" data-jscall-id="16">./error.jl:35</a>
      </span>
      <br data-jscall-id="17" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="18">  &#91;2&#93; type_string&#40;context::WGLMakie.WebGL, t::Type&#41;</span>
      <br data-jscall-id="19" />
      <span data-jscall-id="20">    &#64; ShaderAbstractions ~/.julia/packages/ShaderAbstractions/BCZHP/src/uniforms.jl:143</span>
      <br data-jscall-id="21" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="22">  &#91;3&#93; type_string&#40;context::WGLMakie.WebGL, x::Int64&#41;</span>
      <br data-jscall-id="23" />
      <span data-jscall-id="24">    &#64; ShaderAbstractions ~/.julia/packages/ShaderAbstractions/BCZHP/src/uniforms.jl:115</span>
      <br data-jscall-id="25" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="26">  &#91;4&#93; &#40;::WGLMakie.var&#34;#1#4&#34;&#123;Dict&#123;Symbol, Any&#125;, WGLMakie.WebGL&#125;&#41;&#40;io::IOBuffer&#41;</span>
      <br data-jscall-id="27" />
      <span data-jscall-id="28">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/shader-abstractions.jl:44</span>
      <br data-jscall-id="29" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="30">  &#91;5&#93; sprint&#40;::Function; context::Nothing, sizehint::Int64&#41;</span>
      <br data-jscall-id="31" />
      <span data-jscall-id="32">    &#64; Base 
        <a href="vscode://file/./strings/io.jl:114" data-jscall-id="33">./strings/io.jl:114</a>
      </span>
      <br data-jscall-id="34" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="35">  &#91;6&#93; sprint</span>
      <br data-jscall-id="36" />
      <span data-jscall-id="37">    &#64; 
        <a href="vscode://file/./strings/io.jl:107" data-jscall-id="38">./strings/io.jl:107</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="39" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="40">  &#91;7&#93; create_shader&#40;vertex_attr::GeometryBasics.Mesh&#123;…&#125;, uniforms::Dict&#123;…&#125;, vertshader::String, fragshader::String&#41;</span>
      <br data-jscall-id="41" />
      <span data-jscall-id="42">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/shader-abstractions.jl:39</span>
      <br data-jscall-id="43" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="44">  &#91;8&#93; create_volume_shader&#40;attr::&#64;NamedTuple&#123;…&#125;&#41;</span>
      <br data-jscall-id="45" />
      <span data-jscall-id="46">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:639</span>
      <br data-jscall-id="47" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="48">  &#91;9&#93; &#40;::WGLMakie.var&#34;#75#76&#34;&#123;…&#125;&#41;&#40;args::&#64;NamedTuple&#123;…&#125;, changed::&#64;NamedTuple&#123;…&#125;, last::Nothing&#41;</span>
      <br data-jscall-id="49" />
      <span data-jscall-id="50">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:113</span>
      <br data-jscall-id="51" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="52"> &#91;10&#93; ComputePipeline.TypedEdge&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="53" />
      <span data-jscall-id="54">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:120</span>
      <br data-jscall-id="55" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="56"> &#91;11&#93; &#40;::ComputePipeline.var&#34;#42#44&#34;&#123;ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#125;&#41;&#40;&#41;</span>
      <br data-jscall-id="57" />
      <span data-jscall-id="58">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:577</span>
      <br data-jscall-id="59" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="60"> &#91;12&#93; lock&#40;f::ComputePipeline.var&#34;#42#44&#34;&#123;ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#125;, l::ReentrantLock&#41;</span>
      <br data-jscall-id="61" />
      <span data-jscall-id="62">    &#64; Base 
        <a href="vscode://file/./lock.jl:232" data-jscall-id="63">./lock.jl:232</a>
      </span>
      <br data-jscall-id="64" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="65"> &#91;13&#93; resolve&#33;&#40;edge::ComputePipeline.ComputeEdge&#123;ComputePipeline.ComputeGraph&#125;&#41;</span>
      <br data-jscall-id="66" />
      <span data-jscall-id="67">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:570</span>
      <br data-jscall-id="68" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="69"> &#91;14&#93; _resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="70" />
      <span data-jscall-id="71">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:562</span>
      <br data-jscall-id="72" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="73"> &#91;15&#93; resolve&#33;&#40;computed::ComputePipeline.Computed&#41;</span>
      <br data-jscall-id="74" />
      <span data-jscall-id="75">    &#64; ComputePipeline ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:554</span>
      <br data-jscall-id="76" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="77"> &#91;16&#93; getindex</span>
      <br data-jscall-id="78" />
      <span data-jscall-id="79">    &#64; ~/work/Makie.jl/Makie.jl/ComputePipeline/src/ComputePipeline.jl:474 &#91;inlined&#93;</span>
      <br data-jscall-id="80" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="81"> &#91;17&#93; create_wgl_renderobject&#40;callback::typeof&#40;WGLMakie.create_volume_shader&#41;, attr::ComputePipeline.ComputeGraph, inputs::Vector&#123;…&#125;&#41;</span>
      <br data-jscall-id="82" />
      <span data-jscall-id="83">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:121</span>
      <br data-jscall-id="84" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="85"> &#91;18&#93; create_shader&#40;scene::Scene, plot::Volume&#123;Tuple&#123;…&#125;&#125;&#41;</span>
      <br data-jscall-id="86" />
      <span data-jscall-id="87">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:663</span>
      <br data-jscall-id="88" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="89"> &#91;19&#93; serialize_three&#40;scene::Scene, plot::Volume&#123;Tuple&#123;…&#125;&#125;&#41;</span>
      <br data-jscall-id="90" />
      <span data-jscall-id="91">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/plot-primitives.jl:9</span>
      <br data-jscall-id="92" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="93"> &#91;20&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
      <br data-jscall-id="94" />
      <span data-jscall-id="95">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:230</span>
      <br data-jscall-id="96" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="97"> &#91;21&#93; serialize_plots&#40;scene::Scene, plots::Vector&#123;Plot&#125;, result::Vector&#123;Any&#125;&#41;</span>
      <br data-jscall-id="98" />
      <span data-jscall-id="99">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:235</span>
      <br data-jscall-id="100" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="101"> &#91;22&#93; serialize_plots</span>
      <br data-jscall-id="102" />
      <span data-jscall-id="103">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:227 &#91;inlined&#93;</span>
      <br data-jscall-id="104" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="105"> &#91;23&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="106" />
      <span data-jscall-id="107">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:207</span>
      <br data-jscall-id="108" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="109"> &#91;24&#93; &#40;::WGLMakie.var&#34;#51#58&#34;&#41;&#40;child::Scene&#41;</span>
      <br data-jscall-id="110" />
      <span data-jscall-id="111">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="112" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="113"> &#91;25&#93; iterate</span>
      <br data-jscall-id="114" />
      <span data-jscall-id="115">    &#64; 
        <a href="vscode://file/./generator.jl:48" data-jscall-id="116">./generator.jl:48</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="117" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="118"> &#91;26&#93; _collect&#40;c::Vector&#123;…&#125;, itr::Base.Generator&#123;…&#125;, ::Base.EltypeUnknown, isz::Base.HasShape&#123;…&#125;&#41;</span>
      <br data-jscall-id="119" />
      <span data-jscall-id="120">    &#64; Base 
        <a href="vscode://file/./array.jl:811" data-jscall-id="121">./array.jl:811</a>
      </span>
      <br data-jscall-id="122" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="123"> &#91;27&#93; collect_similar</span>
      <br data-jscall-id="124" />
      <span data-jscall-id="125">    &#64; 
        <a href="vscode://file/./array.jl:720" data-jscall-id="126">./array.jl:720</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="127" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="128"> &#91;28&#93; map</span>
      <br data-jscall-id="129" />
      <span data-jscall-id="130">    &#64; 
        <a href="vscode://file/./abstractarray.jl:3371" data-jscall-id="131">./abstractarray.jl:3371</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="132" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="133"> &#91;29&#93; serialize_scene&#40;scene::Scene&#41;</span>
      <br data-jscall-id="134" />
      <span data-jscall-id="135">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/serialization.jl:191</span>
      <br data-jscall-id="136" />
      <span data-jscall-id="137">--- the above 6 lines are repeated 1 more time ---</span>
      <br data-jscall-id="138" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="139"> &#91;36&#93; three_display&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="140" />
      <span data-jscall-id="141">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/three_plot.jl:33</span>
      <br data-jscall-id="142" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="143"> &#91;37&#93; render_with_init&#40;screen::WGLMakie.Screen, session::Bonito.Session&#123;Bonito.SubConnection&#125;, scene::Scene&#41;</span>
      <br data-jscall-id="144" />
      <span data-jscall-id="145">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:109</span>
      <br data-jscall-id="146" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="147"> &#91;38&#93; jsrender</span>
      <br data-jscall-id="148" />
      <span data-jscall-id="149">    &#64; ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:143 &#91;inlined&#93;</span>
      <br data-jscall-id="150" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="151"> &#91;39&#93; jsrender&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, fig::Figure&#41;</span>
      <br data-jscall-id="152" />
      <span data-jscall-id="153">    &#64; WGLMakie ~/work/Makie.jl/Makie.jl/WGLMakie/src/display.jl:148</span>
      <br data-jscall-id="154" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="155"> &#91;40&#93; render_node&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, node::Hyperscript.Node&#123;Hyperscript.HTMLSVG&#125;&#41;</span>
      <br data-jscall-id="156" />
      <span data-jscall-id="157">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/rendering/hyperscript_integration.jl:171</span>
      <br data-jscall-id="158" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="159"> &#91;41&#93; jsrender</span>
      <br data-jscall-id="160" />
      <span data-jscall-id="161">    &#64; ~/.julia/packages/Bonito/PiA4w/src/rendering/hyperscript_integration.jl:201 &#91;inlined&#93;</span>
      <br data-jscall-id="162" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="163"> &#91;42&#93; record_states&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, dom::Hyperscript.Node&#123;Hyperscript.HTMLSVG&#125;&#41;</span>
      <br data-jscall-id="164" />
      <span data-jscall-id="165">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/export.jl:110</span>
      <br data-jscall-id="166" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="167"> &#91;43&#93; &#40;::Main.__atexample__named__wglmakie.var&#34;#1#4&#34;&#41;&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;&#41;</span>
      <br data-jscall-id="168" />
      <span data-jscall-id="169">    &#64; Main.__atexample__named__wglmakie ./wglmakie.md:138</span>
      <br data-jscall-id="170" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="171"> &#91;44&#93; &#40;::Bonito.var&#34;#10#16&#34;&#123;…&#125;&#41;&#40;session::Bonito.Session&#123;…&#125;, request::HTTP.Messages.Request&#41;</span>
      <br data-jscall-id="172" />
      <span data-jscall-id="173">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/types.jl:362</span>
      <br data-jscall-id="174" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="175"> &#91;45&#93; #invokelatest#2</span>
      <br data-jscall-id="176" />
      <span data-jscall-id="177">    &#64; 
        <a href="vscode://file/./essentials.jl:1055" data-jscall-id="178">./essentials.jl:1055</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="179" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="180"> &#91;46&#93; invokelatest</span>
      <br data-jscall-id="181" />
      <span data-jscall-id="182">    &#64; 
        <a href="vscode://file/./essentials.jl:1052" data-jscall-id="183">./essentials.jl:1052</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="184" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="185"> &#91;47&#93; rendered_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App, target::HTTP.Messages.Request&#41;</span>
      <br data-jscall-id="186" />
      <span data-jscall-id="187">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/app.jl:42</span>
      <br data-jscall-id="188" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="189"> &#91;48&#93; rendered_dom</span>
      <br data-jscall-id="190" />
      <span data-jscall-id="191">    &#64; ~/.julia/packages/Bonito/PiA4w/src/app.jl:39 &#91;inlined&#93;</span>
      <br data-jscall-id="192" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="193"> &#91;49&#93; session_dom&#40;session::Bonito.Session&#123;Bonito.SubConnection&#125;, app::Bonito.App; init::Bool, html_document::Bool&#41;</span>
      <br data-jscall-id="194" />
      <span data-jscall-id="195">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/session.jl:363</span>
      <br data-jscall-id="196" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="197"> &#91;50&#93; session_dom</span>
      <br data-jscall-id="198" />
      <span data-jscall-id="199">    &#64; ~/.julia/packages/Bonito/PiA4w/src/session.jl:362 &#91;inlined&#93;</span>
      <br data-jscall-id="200" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="201"> &#91;51&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App; parent::Bonito.Session&#123;Bonito.NoConnection&#125;&#41;</span>
      <br data-jscall-id="202" />
      <span data-jscall-id="203">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:70</span>
      <br data-jscall-id="204" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="205"> &#91;52&#93; show_html&#40;io::IOContext&#123;IOBuffer&#125;, app::Bonito.App&#41;</span>
      <br data-jscall-id="206" />
      <span data-jscall-id="207">    &#64; Bonito ~/.julia/packages/Bonito/PiA4w/src/display.jl:63</span>
      <br data-jscall-id="208" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="209"> &#91;53&#93; show</span>
      <br data-jscall-id="210" />
      <span data-jscall-id="211">    &#64; ~/.julia/packages/Bonito/PiA4w/src/display.jl:97 &#91;inlined&#93;</span>
      <br data-jscall-id="212" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="213"> &#91;54&#93; __binrepr&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Bonito.App, context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="214" />
      <span data-jscall-id="215">    &#64; Base.Multimedia 
        <a href="vscode://file/./multimedia.jl:173" data-jscall-id="216">./multimedia.jl:173</a>
      </span>
      <br data-jscall-id="217" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="218"> &#91;55&#93; _textrepr</span>
      <br data-jscall-id="219" />
      <span data-jscall-id="220">    &#64; 
        <a href="vscode://file/./multimedia.jl:163" data-jscall-id="221">./multimedia.jl:163</a> &#91;inlined&#93;
      </span>
      <br data-jscall-id="222" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="223"> &#91;56&#93; stringmime&#40;m::MIME&#123;Symbol&#40;&#34;text/html&#34;&#41;&#125;, x::Bonito.App; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="224" />
      <span data-jscall-id="225">    &#64; Base64 /opt/hostedtoolcache/julia/1.11.5/x64/share/julia/stdlib/v1.11/Base64/src/Base64.jl:44</span>
      <br data-jscall-id="226" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="227"> &#91;57&#93; display_dict&#40;x::Bonito.App; context::Pair&#123;Symbol, Bool&#125;&#41;</span>
      <br data-jscall-id="228" />
      <span data-jscall-id="229">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/utilities/utilities.jl:576</span>
      <br data-jscall-id="230" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="231"> &#91;58&#93; invokelatest&#40;::Any, ::Any, ::Vararg&#123;Any&#125;; kwargs::&#64;Kwargs&#123;context::Pair&#123;Symbol, Bool&#125;&#125;&#41;</span>
      <br data-jscall-id="232" />
      <span data-jscall-id="233">    &#64; Base 
        <a href="vscode://file/./essentials.jl:1057" data-jscall-id="234">./essentials.jl:1057</a>
      </span>
      <br data-jscall-id="235" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="236"> &#91;59&#93; runner&#40;::Type&#123;…&#125;, node::MarkdownAST.Node&#123;…&#125;, page::Documenter.Page, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="237" />
      <span data-jscall-id="238">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:885</span>
      <br data-jscall-id="239" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="240"> &#91;60&#93; dispatch&#40;::Type&#123;Documenter.Expanders.ExpanderPipeline&#125;, ::MarkdownAST.Node&#123;Nothing&#125;, ::Vararg&#123;Any&#125;&#41;</span>
      <br data-jscall-id="241" />
      <span data-jscall-id="242">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="243" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="244"> &#91;61&#93; expand&#40;doc::Documenter.Document&#41;</span>
      <br data-jscall-id="245" />
      <span data-jscall-id="246">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/expander_pipeline.jl:59</span>
      <br data-jscall-id="247" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="248"> &#91;62&#93; runner&#40;::Type&#123;Documenter.Builder.ExpandTemplates&#125;, doc::Documenter.Document&#41;</span>
      <br data-jscall-id="249" />
      <span data-jscall-id="250">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/builder_pipeline.jl:224</span>
      <br data-jscall-id="251" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="252"> &#91;63&#93; dispatch&#40;::Type&#123;Documenter.Builder.DocumentPipeline&#125;, x::Documenter.Document&#41;</span>
      <br data-jscall-id="253" />
      <span data-jscall-id="254">    &#64; Documenter.Selectors ~/.julia/packages/Documenter/iRt2s/src/utilities/Selectors.jl:170</span>
      <br data-jscall-id="255" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="256"> &#91;64&#93; #88</span>
      <br data-jscall-id="257" />
      <span data-jscall-id="258">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:275 &#91;inlined&#93;</span>
      <br data-jscall-id="259" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="260"> &#91;65&#93; withenv&#40;::Documenter.var&#34;#88#90&#34;&#123;Documenter.Document&#125;, ::Pair&#123;String, Nothing&#125;, ::Vararg&#123;Pair&#123;String, Nothing&#125;&#125;&#41;</span>
      <br data-jscall-id="261" />
      <span data-jscall-id="262">    &#64; Base 
        <a href="vscode://file/./env.jl:265" data-jscall-id="263">./env.jl:265</a>
      </span>
      <br data-jscall-id="264" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="265"> &#91;66&#93; #87</span>
      <br data-jscall-id="266" />
      <span data-jscall-id="267">    &#64; ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:274 &#91;inlined&#93;</span>
      <br data-jscall-id="268" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="269"> &#91;67&#93; cd&#40;f::Documenter.var&#34;#87#89&#34;&#123;Documenter.Document&#125;, dir::String&#41;</span>
      <br data-jscall-id="270" />
      <span data-jscall-id="271">    &#64; Base.Filesystem 
        <a href="vscode://file/./file.jl:112" data-jscall-id="272">./file.jl:112</a>
      </span>
      <br data-jscall-id="273" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="274"> &#91;68&#93; makedocs&#40;; debug::Bool, format::MarkdownVitepress, kwargs::&#64;Kwargs&#123;…&#125;&#41;</span>
      <br data-jscall-id="275" />
      <span data-jscall-id="276">    &#64; Documenter ~/.julia/packages/Documenter/iRt2s/src/makedocs.jl:273</span>
      <br data-jscall-id="277" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="278"> &#91;69&#93; make_docs&#40;; pages::Vector&#123;Pair&#123;String, Any&#125;&#125;&#41;</span>
      <br data-jscall-id="279" />
      <span data-jscall-id="280">    &#64; Main ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:189</span>
      <br data-jscall-id="281" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="282"> &#91;70&#93; top-level scope</span>
      <br data-jscall-id="283" />
      <span data-jscall-id="284">    &#64; ~/work/Makie.jl/Makie.jl/docs/makedocs.jl:205</span>
      <br data-jscall-id="285" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="286"> &#91;71&#93; include&#40;mod::Module, _path::String&#41;</span>
      <br data-jscall-id="287" />
      <span data-jscall-id="288">    &#64; Base 
        <a href="vscode://file/./Base.jl:557" data-jscall-id="289">./Base.jl:557</a>
      </span>
      <br data-jscall-id="290" />
      <span style="color: darkred; font-weight: bold;" data-jscall-id="291"> &#91;72&#93; exec_options&#40;opts::Base.JLOptions&#41;</span>
      <br data-jscall-id="292" />
      <span data-jscall-id="293">    &#64; Base 
        <a href="vscode://file/./client.jl:323" data-jscall-id="294">./client.jl:323</a>
      </span>
      <br data-jscall-id="295" />
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
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="e7847ba3-2b57-4089-ae96-0a409b8021bc" data-jscall-id="subsession-application-dom">
  <div>
    <style></style>
  </div>
  <div>
    <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/4d5694c168a91800e1f8b353e36bee7eb9294c2d-11713985289905437754.bin').then(msgs=> Bonito.init_session('e7847ba3-2b57-4089-ae96-0a409b8021bc', msgs, 'sub', false));
    })
<\/script>
    <div data-jscall-id="297">slider 1: 
      <input step="1" max="100" min="1" style="styles" data-jscall-id="298" value="1" oninput="" type="range" />
      <p data-jscall-id="296">1</p>
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
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="34aae1c9-cc4f-44cb-8776-84bc84b4a74f" data-jscall-id="subsession-application-dom">
  <div>
    <style></style>
  </div>
  <div>
    <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/3a440a35d5009d0bf774f4b64dd4ee266a66ccf6-18399369550810446954.bin').then(msgs=> Bonito.init_session('34aae1c9-cc4f-44cb-8776-84bc84b4a74f', msgs, 'sub', false));
    })
<\/script>
    <div data-jscall-id="299">
      <input step="1" max="100" min="1" style="styles" data-jscall-id="300" value="1" oninput="" type="range" />
      <input step="1" max="100" min="1" style="styles" data-jscall-id="301" value="1" oninput="" type="range" />
      <input step="1" max="100" min="1" style="styles" data-jscall-id="302" value="1" oninput="" type="range" />
      <div style="width: 100%; height: 100%" data-jscall-id="303">
        <canvas data-jp-suppress-context-menu style="display: block" data-lm-suppress-shortcuts="true" data-jscall-id="304" tabindex="0"></canvas>
      </div>
    </div>
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
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="3399a872-4ab6-49ca-a66b-e11ba9327800" data-jscall-id="subsession-application-dom">
  <div>
    <style></style>
    <link href="bonito/css/popup12105019685282523530.css" rel="stylesheet" type="text/css" />
  </div>
  <div>
    <script type="module">    Bonito.lock_loading(() => {
        return Bonito.fetch_binary('bonito/bin/50a0425ab55ac0e309dc54c21fc44bc1417ff492-8666675782826518598.bin').then(msgs=> Bonito.init_session('3399a872-4ab6-49ca-a66b-e11ba9327800', msgs, 'sub', false));
    })
<\/script>
    <div data-jscall-id="305">
      <div style="width: 100%; height: 100%" data-jscall-id="306">
        <canvas data-jp-suppress-context-menu style="display: block" data-lm-suppress-shortcuts="true" data-jscall-id="307" tabindex="0"></canvas>
      </div>
      <span>
        <div class="popup" data-jscall-id="308"></div>
      </span>
    </div>
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
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="cd162c76-645d-48c7-821f-05eb98a256c7" data-jscall-id="subsession-application-dom">
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
        return Bonito.fetch_binary('bonito/bin/ce273da6f2dd1302be1786d23e8606a6eee3297b-12663995817984702566.bin').then(msgs=> Bonito.init_session('cd162c76-645d-48c7-821f-05eb98a256c7', msgs, 'sub', false));
    })
<\/script>
    <div class=" style_2" style="" data-jscall-id="310">
      <input step="1" max="361" min="1" style="styles" data-jscall-id="311" value="1" oninput="" type="range" />
      <div class="h-6 w-6 p-2 m-2 rounded shadow" data-jscall-id="309"></div>
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
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div><div class="bonito-fragment" id="bddabdc1-306b-40ba-9f7c-e5df425fd019" data-jscall-id="subsession-application-dom">
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
  justify-items: stretch;
  align-items: legacy;
  height: 100%;
  display: grid;
  align-content: normal;
  grid-gap: 10px;
  grid-template-rows: none;
  justify-content: normal;
  grid-template-columns: 1fr 1fr;
  width: 100%;
  grid-template-areas: none;
}
.style_5 {
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
  height: 9.5px;
  border: 1px solid #ccc;
  background-color: #ddd;
  position: absolute;
  width: 0px;
  border-radius: 3px;
}
.style_8 {
  height: auto;
  padding: 12px;
  background-color: rgba(255.0, 255.0, 255.0, 0.2);
  box-shadow: 0 4px 8px rgba(0.0, 0.0, 51.0, 0.2);
  width: auto;
  border-radius: 10px;
  margin: 2px;
}
.style_9 {
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
        return Bonito.fetch_binary('bonito/bin/af313416ea5ab51b3f2bbb8f0c4b5b04b59e5295-12415736476872117521.bin').then(msgs=> Bonito.init_session('bddabdc1-306b-40ba-9f7c-e5df425fd019', msgs, 'sub', false));
    })
<\/script>
    <div data-jscall-id="312">
      <div class=" style_8" style="" data-jscall-id="313">
        <div class=" style_4" style="" data-jscall-id="314">
          <div class=" style_3" style="" data-jscall-id="315">
            <h1 data-jscall-id="316">Hello</h1>
          </div>
          <div class=" style_5" style="" data-jscall-id="317">
            <div class=" style_9" style="" data-jscall-id="318"></div>
            <div class=" style_7" style="" data-jscall-id="319"></div>
            <div class=" style_6" style="" data-jscall-id="320"></div>
          </div>
          <img data-jscall-id="321" src="https://julialang.org/assets/infra/logo.svg" />
          <div style="width: 100%; height: 100%" data-jscall-id="322">
            <canvas data-jp-suppress-context-menu style="display: block" data-lm-suppress-shortcuts="true" data-jscall-id="323" tabindex="0"></canvas>
          </div>
        </div>
      </div>
    </div>
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
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div>`,51))])}const j=l(r,[["render",c]]);export{C as __pageData,j as default};
