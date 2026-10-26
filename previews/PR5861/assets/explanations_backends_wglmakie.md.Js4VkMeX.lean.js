import{_ as r,C as k,ap as d,o,c as E,ao as a,j as i,a as g,E as n,w as t,a2 as e}from"./chunks/framework.Bl2ODOpW.js";const T=JSON.parse('{"title":"WGLMakie","description":"","frontmatter":{},"headers":[],"relativePath":"explanations/backends/wglmakie.md","filePath":"explanations/backends/wglmakie.md","lastUpdated":null}'),y={name:"explanations/backends/wglmakie.md"},c={class:"jldocstring custom-block",open:""},F={class:"vp-raw-html",innerHTML:`<div><div data-jscall-id="root" id="845ef042-695b-4f25-a7b7-b08dab007c76" class="bonito-fragment" style="display:contents"><div style="display:contents"><script src="bonito/js/Bonito.bundled5040008371911548254.js" type="module"><\/script><style></style><style>@media (prefers-color-scheme: light) {
  :root {
    --bonito-widget-hover-bg: #f3f4f6;
    color-scheme: light;
    --bonito-widget-muted-bg: #f3f4f6;
    accent-color: #3182bb;
    --bonito-widget-accent: #3182bb;
    --bonito-widget-fg: #1a1a1a;
    --bonito-widget-bg: #ffffff;
    --bonito-widget-border: #9ca3af;
  }
}
@media (prefers-color-scheme: dark) {
  :root {
    --bonito-widget-hover-bg: #3a3a40;
    color-scheme: dark;
    --bonito-widget-muted-bg: #36363c;
    accent-color: #6ea8e0;
    --bonito-widget-accent: #6ea8e0;
    --bonito-widget-fg: #e8e8ea;
    --bonito-widget-bg: #2a2a2e;
    --bonito-widget-border: #52525b;
  }
}
html .noUi-target {
  box-shadow: none;
  background: var(--bonito-widget-muted-bg, #fafafa);
  border-color: var(--bonito-widget-border, #d3d3d3);
}
html .noUi-connects {
  background: var(--bonito-widget-muted-bg, #fafafa);
}
html .noUi-connect {
  background: var(--bonito-widget-accent, #3182bb);
}
html .noUi-handle {
  box-shadow: none;
  background: var(--bonito-widget-bg, #fff);
  border-color: var(--bonito-widget-border, #d3d3d3);
}
html .noUi-handle::before {
  background: var(--bonito-widget-border, #d3d3d3);
}
html .noUi-handle::after {
  background: var(--bonito-widget-border, #d3d3d3);
}
html .noUi-tooltip {
  background: var(--bonito-widget-bg, #fff);
  border-color: var(--bonito-widget-border, #d3d3d3);
  color: var(--bonito-widget-fg, #000);
}
html .noUi-marker {
  background: var(--bonito-widget-border, #ccc);
}
html .noUi-value {
  color: var(--bonito-widget-fg, inherit);
}
</style></div><div style="display:contents"><script type="module">Bonito.init_session("845ef042-695b-4f25-a7b7-b08dab007c76", Bonito.fetch_binary('bonito/bin/9961f006f655910721ca524fa355f4a088dbf626-6622845114839835074.bin'), "root", false);
<\/script><div></div></div></div><div data-jscall-id="subsession-application-dom" id="2f89f7a6-4bbe-4b59-bfe6-526e23b8070b" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  animation: wglmakie-spin 1.0s linear infinite;
  position: absolute;
  left: 50%;
  z-index: 1000;
  border-radius: 50%;
  width: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  transform: translate(-50%, -50%);
  border-top: 4px solid currentColor;
  height: 40px;
  pointer-events: none;
  top: 50%;
}
@keyframes wglmakie-spin {
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled1870091951256107923.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("2f89f7a6-4bbe-4b59-bfe6-526e23b8070b", Bonito.fetch_binary('bonito/bin/63ba8bea63aaca896029320959021684701423df-18004045387350592342.bin'), "sub", false);
<\/script><div data-jscall-id="1" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="2" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="3" class="wglmakie-spinner"></div></div></div></div></div>`},u={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="55f863ea-d81e-450f-a8a1-6f0e9365f6f0" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  animation: wglmakie-spin 1.0s linear infinite;
  position: absolute;
  left: 50%;
  z-index: 1000;
  border-radius: 50%;
  width: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  transform: translate(-50%, -50%);
  border-top: 4px solid currentColor;
  height: 40px;
  pointer-events: none;
  top: 50%;
}
@keyframes wglmakie-spin {
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled1870091951256107923.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("55f863ea-d81e-450f-a8a1-6f0e9365f6f0", Bonito.fetch_binary('bonito/bin/8bfd6f08575de2fcda2c661e89d97d4d19fe0696-7678069692721175519.bin'), "sub", false);
<\/script><div data-jscall-id="4" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="5" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="6" class="wglmakie-spinner"></div></div></div></div>`},C={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="51550264-85a8-44ed-a652-fec372e1e433" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  animation: wglmakie-spin 1.0s linear infinite;
  position: absolute;
  left: 50%;
  z-index: 1000;
  border-radius: 50%;
  width: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  transform: translate(-50%, -50%);
  border-top: 4px solid currentColor;
  height: 40px;
  pointer-events: none;
  top: 50%;
}
@keyframes wglmakie-spin {
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled1870091951256107923.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("51550264-85a8-44ed-a652-fec372e1e433", Bonito.fetch_binary('bonito/bin/afa60cbc6e706b031eb7eb20033209995f8df433-14427481421552762440.bin'), "sub", false);
<\/script><div data-jscall-id="7"><div data-jscall-id="8">z-index: <input data-jscall-id="9" step="1" type="range" min="1" max="10" oninput="" value="1" autocomplete="off" /><span data-jscall-id="10">1</span></div><div data-jscall-id="11" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="12" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="13" class="wglmakie-spinner"></div></div></div></div></div>`},b={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="c3602432-bc33-40d0-a312-0d906471eed3" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style></div><div style="display:contents"><script type="module">Bonito.init_session("c3602432-bc33-40d0-a312-0d906471eed3", Bonito.fetch_binary('bonito/bin/416f001c7b3fbdf7b9eceb2065c39b01e5fbc6d2-1862176004268848567.bin'), "sub", false);
<\/script><div data-jscall-id="15">slider 1: <input data-jscall-id="16" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><p data-jscall-id="14"><span class="text-plain" style="white-space: pre-wrap">1</span></p></div></div></div>`},m={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="d45d7a5c-ce8b-4352-9b81-470614f3edb3" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  animation: wglmakie-spin 1.0s linear infinite;
  position: absolute;
  left: 50%;
  z-index: 1000;
  border-radius: 50%;
  width: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  transform: translate(-50%, -50%);
  border-top: 4px solid currentColor;
  height: 40px;
  pointer-events: none;
  top: 50%;
}
@keyframes wglmakie-spin {
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled1870091951256107923.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("d45d7a5c-ce8b-4352-9b81-470614f3edb3", Bonito.fetch_binary('bonito/bin/c6c01a4b67ec27be0216f32d9c1fd2f433565077-8699428316819675286.bin'), "sub", false);
<\/script><div data-jscall-id="17"><input data-jscall-id="18" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><input data-jscall-id="19" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><input data-jscall-id="20" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><div data-jscall-id="21" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="22" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="23" class="wglmakie-spinner"></div></div></div></div></div>`},B={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="16fa3cbf-2d40-4699-a3c7-8ffd245381dd" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  animation: wglmakie-spin 1.0s linear infinite;
  position: absolute;
  left: 50%;
  z-index: 1000;
  border-radius: 50%;
  width: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  transform: translate(-50%, -50%);
  border-top: 4px solid currentColor;
  height: 40px;
  pointer-events: none;
  top: 50%;
}
@keyframes wglmakie-spin {
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled1870091951256107923.js" type="module"><\/script><link rel="stylesheet" type="text/css" href="bonito/css/popup15566812377123610001.css" /></div><div style="display:contents"><script type="module">Bonito.init_session("16fa3cbf-2d40-4699-a3c7-8ffd245381dd", Bonito.fetch_binary('bonito/bin/0bac0a021bc91f18735f8d4eb2670e468bd1f94b-6212126101774691907.bin'), "sub", false);
<\/script><div data-jscall-id="24"><div data-jscall-id="25" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="26" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="27" class="wglmakie-spinner"></div></div><span><div data-jscall-id="28" class="popup"></div></span></div></div></div>`},A={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="621abeb4-b4e9-417b-ac63-c9adf4bd3766" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  animation: wglmakie-spin 1.0s linear infinite;
  position: absolute;
  left: 50%;
  z-index: 1000;
  border-radius: 50%;
  width: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  transform: translate(-50%, -50%);
  border-top: 4px solid currentColor;
  height: 40px;
  pointer-events: none;
  top: 50%;
}
@keyframes wglmakie-spin {
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled1870091951256107923.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("621abeb4-b4e9-417b-ac63-c9adf4bd3766", Bonito.fetch_binary('bonito/bin/c2cbd4cb0211b49d3f1d85d2a999258a180cb29e-3430010115812018415.bin'), "sub", false);
<\/script><div data-jscall-id="29"><div data-jscall-id="30" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="31" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="32" class="wglmakie-spinner"></div></div><span><style data-jscall-id="34">    .mytip {
        position: absolute; display: none;
        background: white; color: black;
        border: 1px solid black; border-radius: 0;
        padding: 2px 6px; font-family: sans-serif;
    }
    .mytip.show { display: block; }
</style><div data-jscall-id="33" class="mytip"></div></span></div></div></div>`},f={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="6ff547b9-d708-410e-909b-3e082f3946af" class="bonito-fragment" style="display:contents"><div style="display:contents"><style>.style_2 {
  justify-items: legacy;
  align-content: normal;
  grid-template-rows: 1fr;
  align-items: legacy;
  grid-template-areas: none;
  width: 100%;
  justify-content: normal;
  grid-template-columns: repeat(2, 1fr);
  height: 100%;
  grid-gap: 10px;
  display: grid;
}
</style></div><div style="display:contents"><script type="module">Bonito.init_session("6ff547b9-d708-410e-909b-3e082f3946af", Bonito.fetch_binary('bonito/bin/fb2aee8d719f0b874f778b5e4e66e3d5e701eb6d-6491285941885560060.bin'), "sub", false);
<\/script><div data-jscall-id="36" class=" style_2" style=""><input data-jscall-id="37" step="1" type="range" min="1" max="361" oninput="" value="1" autocomplete="off" /><div data-jscall-id="35" class="h-6 w-6 p-2 m-2 rounded shadow"></div></div></div></div>`},D={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="c4b6cd4b-081e-4b13-9f39-9bc281c89641" class="bonito-fragment" style="display:contents"><div style="display:contents"><style>.style_3 {
  grid-column: 1 / 3;
  justify-items: center;
  align-content: center;
  grid-template-rows: none;
  align-items: center;
  grid-template-areas: none;
  width: 100%;
  justify-content: center;
  grid-template-columns: 1fr;
  height: 100%;
  grid-gap: 10px;
  display: grid;
}
.style_4 {
  height: 7.5px;
  width: 100%;
  background-color: var(--bonito-widget-muted-bg, #eee);
  position: absolute;
  border: 1px solid var(--bonito-widget-border, #ccc);
  border-radius: 3px;
}
.style_5 {
  height: 9.5px;
  width: 0px;
  background-color: var(--bonito-widget-border, #ddd);
  position: absolute;
  border: 1px solid var(--bonito-widget-border, #ccc);
  border-radius: 3px;
}
.style_6 {
  height: 15px;
  cursor: pointer;
  width: 15px;
  background-color: var(--bonito-widget-bg, #fff);
  position: absolute;
  border: 1px solid var(--bonito-widget-border, #ccc);
  left: -7.5px;
  border-radius: 50%;
}
.style_7 {
  grid-template-columns: 1fr;
  margin: 5px;
  padding-left: 9.5px;
  grid-column: 1 / 3;
  padding-right: 9.5px;
  background-color: transparent;
  display: grid;
  position: relative;
  grid-template-rows: 15px;
  align-items: center;
}
.style_8 {
  justify-items: stretch;
  align-content: normal;
  grid-template-rows: none;
  align-items: legacy;
  grid-template-areas: none;
  width: 100%;
  justify-content: normal;
  grid-template-columns: 1fr 1fr;
  height: 100%;
  grid-gap: 10px;
  display: grid;
}
.style_9 {
  height: auto;
  margin: 2px;
  box-shadow: 0 4px 8px rgba(0.0, 0.0, 51.0, 0.2);
  padding: 12px;
  background-color: rgba(255.0, 255.0, 255.0, 0.2);
  width: auto;
  border-radius: 10px;
}
</style><style>.wglmakie-spinner {
  animation: wglmakie-spin 1.0s linear infinite;
  position: absolute;
  left: 50%;
  z-index: 1000;
  border-radius: 50%;
  width: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  transform: translate(-50%, -50%);
  border-top: 4px solid currentColor;
  height: 40px;
  pointer-events: none;
  top: 50%;
}
@keyframes wglmakie-spin {
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled1870091951256107923.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("c4b6cd4b-081e-4b13-9f39-9bc281c89641", Bonito.fetch_binary('bonito/bin/8047109f959b4a1a5e77fbe0911a907f5c05913c-18096186648041991779.bin'), "sub", false);
<\/script><div data-jscall-id="38"><div data-jscall-id="39" class=" style_9" style=""><div data-jscall-id="40" class=" style_8" style=""><div data-jscall-id="41" class=" style_3" style=""><h1 data-jscall-id="42">Hello</h1></div><div data-jscall-id="43" class=" style_7" style=""><div data-jscall-id="44" class=" style_4" style=""></div><div data-jscall-id="45" class=" style_5" style=""></div><div data-jscall-id="46" class=" style_6" style=""></div></div><img data-jscall-id="47" src="https://julialang.org/assets/infra/logo.svg" /><div data-jscall-id="48" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="49" height="300px" data-lm-suppress-shortcuts="true" width="300px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="50" class="wglmakie-spinner"></div></div></div></div></div></div></div>`};function v(w,s,_,x,q,j){const p=k("Badge"),l=k("ClientOnly"),h=d("exec-scripts");return o(),E("div",null,[s[4]||(s[4]=a("",21)),i("details",c,[i("summary",null,[s[0]||(s[0]=i("a",{id:"WGLMakie.activate!",href:"#WGLMakie.activate!"},[i("span",{class:"jlbinding"},"WGLMakie.activate!")],-1)),s[1]||(s[1]=g()),n(p,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),s[3]||(s[3]=a("",4)),n(p,{type:"info",class:"source-link",text:"source"},{default:t(()=>[...s[2]||(s[2]=[i("a",{href:"https://github.com/MakieOrg/Makie.jl/blob/e6bbb3ccac48055aab12424a5c67a125f19f252f/WGLMakie/src/WGLMakie.jl#L49-L58",target:"_blank",rel:"noreferrer"},"source",-1)])]),_:1})]),s[5]||(s[5]=a("",32)),n(l,null,{default:t(()=>[e(i("div",F,null,512),[[h]])]),_:1}),s[6]||(s[6]=a("",2)),n(l,null,{default:t(()=>[e(i("div",u,null,512),[[h]])]),_:1}),s[7]||(s[7]=a("",6)),n(l,null,{default:t(()=>[e(i("div",C,null,512),[[h]])]),_:1}),s[8]||(s[8]=a("",3)),n(l,null,{default:t(()=>[e(i("div",b,null,512),[[h]])]),_:1}),s[9]||(s[9]=a("",2)),n(l,null,{default:t(()=>[e(i("div",m,null,512),[[h]])]),_:1}),s[10]||(s[10]=a("",5)),n(l,null,{default:t(()=>[e(i("div",B,null,512),[[h]])]),_:1}),s[11]||(s[11]=a("",4)),n(l,null,{default:t(()=>[e(i("div",A,null,512),[[h]])]),_:1}),s[12]||(s[12]=a("",8)),n(l,null,{default:t(()=>[e(i("div",f,null,512),[[h]])]),_:1}),s[13]||(s[13]=a("",2)),n(l,null,{default:t(()=>[e(i("div",D,null,512),[[h]])]),_:1}),s[14]||(s[14]=a("",6))])}const M=r(y,[["render",v]]);export{T as __pageData,M as default};
