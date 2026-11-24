import{_ as r,C as k,ap as d,o,c as E,ao as a,j as i,a as g,E as n,w as t,a2 as h}from"./chunks/framework.CExAt_zo.js";const T=JSON.parse('{"title":"WGLMakie","description":"","frontmatter":{},"headers":[],"relativePath":"explanations/backends/wglmakie.md","filePath":"explanations/backends/wglmakie.md","lastUpdated":null}'),y={name:"explanations/backends/wglmakie.md"},c={class:"jldocstring custom-block",open:""},F={class:"vp-raw-html",innerHTML:`<div><div data-jscall-id="root" id="b1df0b6f-6b51-4138-a883-4250a3ac76ec" class="bonito-fragment" style="display:contents"><div style="display:contents"><script src="bonito/js/Bonito.bundled18292985539897097442.js" type="module"><\/script><style></style><style>@media (prefers-color-scheme: light) {
  :root {
    color-scheme: light;
    accent-color: #3182bb;
    --bonito-widget-bg: #ffffff;
    --bonito-widget-fg: #1a1a1a;
    --bonito-widget-border: #9ca3af;
    --bonito-widget-hover-bg: #f3f4f6;
    --bonito-widget-muted-bg: #f3f4f6;
    --bonito-widget-accent: #3182bb;
  }
}
@media (prefers-color-scheme: dark) {
  :root {
    color-scheme: dark;
    accent-color: #6ea8e0;
    --bonito-widget-bg: #2a2a2e;
    --bonito-widget-fg: #e8e8ea;
    --bonito-widget-border: #52525b;
    --bonito-widget-hover-bg: #3a3a40;
    --bonito-widget-muted-bg: #36363c;
    --bonito-widget-accent: #6ea8e0;
  }
}
html .noUi-target {
  background: var(--bonito-widget-muted-bg, #fafafa);
  border-color: var(--bonito-widget-border, #d3d3d3);
  box-shadow: none;
}
html .noUi-connects {
  background: var(--bonito-widget-muted-bg, #fafafa);
}
html .noUi-connect {
  background: var(--bonito-widget-accent, #3182bb);
}
html .noUi-handle {
  background: var(--bonito-widget-bg, #fff);
  border-color: var(--bonito-widget-border, #d3d3d3);
  box-shadow: none;
}
html .noUi-handle::before {
  background: var(--bonito-widget-border, #d3d3d3);
}
html .noUi-handle::after {
  background: var(--bonito-widget-border, #d3d3d3);
}
html .noUi-tooltip {
  background: var(--bonito-widget-bg, #fff);
  color: var(--bonito-widget-fg, #000);
  border-color: var(--bonito-widget-border, #d3d3d3);
}
html .noUi-marker {
  background: var(--bonito-widget-border, #ccc);
}
html .noUi-value {
  color: var(--bonito-widget-fg, inherit);
}
</style></div><div style="display:contents"><script type="module">Bonito.init_session("b1df0b6f-6b51-4138-a883-4250a3ac76ec", Bonito.fetch_binary('bonito/bin/3fcb41db9d44771a24e095cb2fa78c0769f880cb-11198345874736380860.bin'), "root", false);
<\/script><div></div></div></div><div data-jscall-id="subsession-application-dom" id="221e6be4-4b7d-4e77-aef7-be7c490f6d4e" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 40px;
  height: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-top: 4px solid currentColor;
  border-radius: 50%;
  animation: wglmakie-spin 1.0s linear infinite;
  z-index: 1000;
  pointer-events: none;
}
@keyframes wglmakie-spin {
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled13182845621970472226.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("221e6be4-4b7d-4e77-aef7-be7c490f6d4e", Bonito.fetch_binary('bonito/bin/7c5a22e4196961c5fdd613b2b504952611588bf9-13477297319872419222.bin'), "sub", false);
<\/script><div data-jscall-id="1" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="2" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="3" class="wglmakie-spinner"></div></div></div></div></div>`},u={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="7ce06a47-383e-4b04-9984-2e6ab62834e6" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 40px;
  height: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-top: 4px solid currentColor;
  border-radius: 50%;
  animation: wglmakie-spin 1.0s linear infinite;
  z-index: 1000;
  pointer-events: none;
}
@keyframes wglmakie-spin {
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled13182845621970472226.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("7ce06a47-383e-4b04-9984-2e6ab62834e6", Bonito.fetch_binary('bonito/bin/52b227fdceaf467aabe95a7bf4f671250afe2efe-1799025452347120830.bin'), "sub", false);
<\/script><div data-jscall-id="4" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="5" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="6" class="wglmakie-spinner"></div></div></div></div>`},C={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="416fab26-17f5-424c-89d4-bae4b213ca3d" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 40px;
  height: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-top: 4px solid currentColor;
  border-radius: 50%;
  animation: wglmakie-spin 1.0s linear infinite;
  z-index: 1000;
  pointer-events: none;
}
@keyframes wglmakie-spin {
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled13182845621970472226.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("416fab26-17f5-424c-89d4-bae4b213ca3d", Bonito.fetch_binary('bonito/bin/39a207db7b0d9473560968b6c3b52665c4915dc2-5931583611700430063.bin'), "sub", false);
<\/script><div data-jscall-id="7"><div data-jscall-id="8">z-index: <input data-jscall-id="9" step="1" type="range" min="1" max="10" oninput="" value="1" autocomplete="off" /><span data-jscall-id="10">1</span></div><div data-jscall-id="11" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="12" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="13" class="wglmakie-spinner"></div></div></div></div></div>`},b={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="6b6e57c0-fa65-4fab-aa50-fae25d4783ea" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style></div><div style="display:contents"><script type="module">Bonito.init_session("6b6e57c0-fa65-4fab-aa50-fae25d4783ea", Bonito.fetch_binary('bonito/bin/5ea48b176475175e4d737d6b116be198ecfe613a-4867556989541505168.bin'), "sub", false);
<\/script><div data-jscall-id="15">slider 1: <input data-jscall-id="16" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><p data-jscall-id="14"><span class="text-plain" style="white-space: pre-wrap">1</span></p></div></div></div>`},m={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="66816cd7-2486-49e9-963b-e594bcacb2ea" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 40px;
  height: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-top: 4px solid currentColor;
  border-radius: 50%;
  animation: wglmakie-spin 1.0s linear infinite;
  z-index: 1000;
  pointer-events: none;
}
@keyframes wglmakie-spin {
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled13182845621970472226.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("66816cd7-2486-49e9-963b-e594bcacb2ea", Bonito.fetch_binary('bonito/bin/8b00baab2fc929e5606ba9e7a25e6cff1c990e59-8272378740826661049.bin'), "sub", false);
<\/script><div data-jscall-id="17"><input data-jscall-id="18" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><input data-jscall-id="19" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><input data-jscall-id="20" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><div data-jscall-id="21" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="22" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="23" class="wglmakie-spinner"></div></div></div></div></div>`},B={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="addc4719-0cd1-45f4-8d55-31a0af733c9c" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 40px;
  height: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-top: 4px solid currentColor;
  border-radius: 50%;
  animation: wglmakie-spin 1.0s linear infinite;
  z-index: 1000;
  pointer-events: none;
}
@keyframes wglmakie-spin {
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled13182845621970472226.js" type="module"><\/script><link rel="stylesheet" type="text/css" href="bonito/css/popup15566812377123610001.css" /></div><div style="display:contents"><script type="module">Bonito.init_session("addc4719-0cd1-45f4-8d55-31a0af733c9c", Bonito.fetch_binary('bonito/bin/c80940891f7cec2c5783b37296c6c6b73d0678fd-8361654268179122499.bin'), "sub", false);
<\/script><div data-jscall-id="24"><div data-jscall-id="25" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="26" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="27" class="wglmakie-spinner"></div></div><span><div data-jscall-id="28" class="popup"></div></span></div></div></div>`},A={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="e6d5e839-5c5f-4b7a-bfd4-e02957234198" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 40px;
  height: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-top: 4px solid currentColor;
  border-radius: 50%;
  animation: wglmakie-spin 1.0s linear infinite;
  z-index: 1000;
  pointer-events: none;
}
@keyframes wglmakie-spin {
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled13182845621970472226.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("e6d5e839-5c5f-4b7a-bfd4-e02957234198", Bonito.fetch_binary('bonito/bin/7e419608c743edc8605fa660d99060002c6eee6a-8441185141689297739.bin'), "sub", false);
<\/script><div data-jscall-id="29"><div data-jscall-id="30" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="31" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="32" class="wglmakie-spinner"></div></div><span><style data-jscall-id="34">    .mytip {
        position: absolute; display: none;
        background: white; color: black;
        border: 1px solid black; border-radius: 0;
        padding: 2px 6px; font-family: sans-serif;
    }
    .mytip.show { display: block; }
</style><div data-jscall-id="33" class="mytip"></div></span></div></div></div>`},f={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="e5552490-9a0e-447e-bf01-d007476cdd25" class="bonito-fragment" style="display:contents"><div style="display:contents"><style>.bs-96288b5fc45bfb51 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-template-rows: 1fr;
  grid-gap: 10px;
  grid-template-areas: none;
  justify-content: normal;
  justify-items: legacy;
  align-content: normal;
  align-items: legacy;
  width: 100%;
  height: 100%;
}
</style></div><div style="display:contents"><script type="module">Bonito.init_session("e5552490-9a0e-447e-bf01-d007476cdd25", Bonito.fetch_binary('bonito/bin/2b144b8c2a026e28875ef7076d5d84dce7eb3e3b-17442344453524476550.bin'), "sub", false);
<\/script><div data-jscall-id="36" class=" bs-96288b5fc45bfb51" style=""><input data-jscall-id="37" step="1" type="range" min="1" max="361" oninput="" value="1" autocomplete="off" /><div data-jscall-id="35" class="h-6 w-6 p-2 m-2 rounded shadow"></div></div></div></div>`},D={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="612859c3-c186-4d2d-8005-9d74ea423003" class="bonito-fragment" style="display:contents"><div style="display:contents"><style>.bs-26025097879fbc98 {
  display: grid;
  grid-template-columns: 1fr;
  grid-template-rows: none;
  grid-gap: 10px;
  grid-template-areas: none;
  justify-content: center;
  justify-items: center;
  align-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
  grid-column: 1 / 3;
}
.bs-27a2d2aaed01f8d4 {
  position: absolute;
  width: 100%;
  height: 7.5px;
  background-color: var(--bonito-widget-muted-bg, #eee);
  border-radius: 3px;
  border: 1px solid var(--bonito-widget-border, #ccc);
}
.bs-8b80b708147c0f08 {
  position: absolute;
  width: 0px;
  height: 9.5px;
  background-color: var(--bonito-widget-border, #ddd);
  border-radius: 3px;
  border: 1px solid var(--bonito-widget-border, #ccc);
}
.bs-63372476036d9ebf {
  width: 15px;
  height: 15px;
  border-radius: 50%;
  cursor: pointer;
  position: absolute;
  border: 1px solid var(--bonito-widget-border, #ccc);
  left: -7.5px;
  background-color: var(--bonito-widget-bg, #fff);
}
.bs-c296edb68c1fa297 {
  display: grid;
  grid-template-columns: 1fr;
  grid-template-rows: 15px;
  align-items: center;
  margin: 5px;
  position: relative;
  padding-right: 9.5px;
  padding-left: 9.5px;
  background-color: transparent;
  grid-column: 1 / 3;
}
.bs-e23cb004be3f7160 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-template-rows: none;
  grid-gap: 10px;
  grid-template-areas: none;
  justify-content: normal;
  justify-items: stretch;
  align-content: normal;
  align-items: legacy;
  width: 100%;
  height: 100%;
}
.bs-786d6c2eb60d9232 {
  width: auto;
  height: auto;
  padding: 12px;
  margin: 2px;
  background-color: rgba(255.0, 255.0, 255.0, 0.2);
  border-radius: 10px;
  box-shadow: 0 4px 8px rgba(0.0, 0.0, 51.0, 0.2);
}
</style><style>.wglmakie-spinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 40px;
  height: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-top: 4px solid currentColor;
  border-radius: 50%;
  animation: wglmakie-spin 1.0s linear infinite;
  z-index: 1000;
  pointer-events: none;
}
@keyframes wglmakie-spin {
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    transform: translate(-50%, -50%) rotate(360deg);
  }
}
</style><script src="bonito/js/WGLMakie.bundled13182845621970472226.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("612859c3-c186-4d2d-8005-9d74ea423003", Bonito.fetch_binary('bonito/bin/f96cf9682dbc49c20f80daba2b8f5c146c64395e-10051713807062687816.bin'), "sub", false);
<\/script><div data-jscall-id="38"><div data-jscall-id="39" class=" bs-786d6c2eb60d9232" style=""><div data-jscall-id="40" class=" bs-e23cb004be3f7160" style=""><div data-jscall-id="41" class=" bs-26025097879fbc98" style=""><h1 data-jscall-id="42">Hello</h1></div><div data-jscall-id="43" class=" bs-c296edb68c1fa297" style=""><div data-jscall-id="44" class=" bs-27a2d2aaed01f8d4" style=""></div><div data-jscall-id="45" class=" bs-8b80b708147c0f08" style=""></div><div data-jscall-id="46" class=" bs-63372476036d9ebf" style=""></div></div><img data-jscall-id="47" src="https://julialang.org/assets/infra/logo.svg" /><div data-jscall-id="48" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="49" height="300px" data-lm-suppress-shortcuts="true" width="300px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="50" class="wglmakie-spinner"></div></div></div></div></div></div></div>`};function v(w,s,_,x,q,j){const p=k("Badge"),l=k("ClientOnly"),e=d("exec-scripts");return o(),E("div",null,[s[4]||(s[4]=a("",21)),i("details",c,[i("summary",null,[s[0]||(s[0]=i("a",{id:"WGLMakie.activate!",href:"#WGLMakie.activate!"},[i("span",{class:"jlbinding"},"WGLMakie.activate!")],-1)),s[1]||(s[1]=g()),n(p,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),s[3]||(s[3]=a("",4)),n(p,{type:"info",class:"source-link",text:"source"},{default:t(()=>[...s[2]||(s[2]=[i("a",{href:"https://github.com/MakieOrg/Makie.jl/blob/cfff9b5d4d14ff3f7eb9ff54d83d200d9d11da72/WGLMakie/src/WGLMakie.jl#L49-L58",target:"_blank",rel:"noreferrer"},"source",-1)])]),_:1})]),s[5]||(s[5]=a("",32)),n(l,null,{default:t(()=>[h(i("div",F,null,512),[[e]])]),_:1}),s[6]||(s[6]=a("",2)),n(l,null,{default:t(()=>[h(i("div",u,null,512),[[e]])]),_:1}),s[7]||(s[7]=a("",6)),n(l,null,{default:t(()=>[h(i("div",C,null,512),[[e]])]),_:1}),s[8]||(s[8]=a("",3)),n(l,null,{default:t(()=>[h(i("div",b,null,512),[[e]])]),_:1}),s[9]||(s[9]=a("",2)),n(l,null,{default:t(()=>[h(i("div",m,null,512),[[e]])]),_:1}),s[10]||(s[10]=a("",5)),n(l,null,{default:t(()=>[h(i("div",B,null,512),[[e]])]),_:1}),s[11]||(s[11]=a("",4)),n(l,null,{default:t(()=>[h(i("div",A,null,512),[[e]])]),_:1}),s[12]||(s[12]=a("",8)),n(l,null,{default:t(()=>[h(i("div",f,null,512),[[e]])]),_:1}),s[13]||(s[13]=a("",2)),n(l,null,{default:t(()=>[h(i("div",D,null,512),[[e]])]),_:1}),s[14]||(s[14]=a("",6))])}const M=r(y,[["render",v]]);export{T as __pageData,M as default};
