import{_ as r,C as k,ap as d,o,c as E,ao as a,j as i,a as g,E as n,w as t,a2 as h}from"./chunks/framework.BM-VUyEI.js";const T=JSON.parse('{"title":"WGLMakie","description":"","frontmatter":{},"headers":[],"relativePath":"explanations/backends/wglmakie.md","filePath":"explanations/backends/wglmakie.md","lastUpdated":null}'),y={name:"explanations/backends/wglmakie.md"},c={class:"jldocstring custom-block",open:""},F={class:"vp-raw-html",innerHTML:`<div><div data-jscall-id="root" id="15704582-4353-4b7f-bcb1-52995ba45b8b" class="bonito-fragment" style="display:contents"><div style="display:contents"><script src="bonito/js/Bonito.bundled18292985539897097442.js" type="module"><\/script><style></style><style>@media (prefers-color-scheme: light) {
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
</style></div><div style="display:contents"><script type="module">Bonito.init_session("15704582-4353-4b7f-bcb1-52995ba45b8b", Bonito.fetch_binary('bonito/bin/a5bc2dc9605ba79be537aee5035d0a5e6a0f5e7e-4046463880862012138.bin'), "root", false);
<\/script><div></div></div></div><div data-jscall-id="subsession-application-dom" id="cc2a7b48-da5d-475b-8dbd-a084aabf5b1d" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled6407492584158908243.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("cc2a7b48-da5d-475b-8dbd-a084aabf5b1d", Bonito.fetch_binary('bonito/bin/572c8d925dc7c078f3e39ccde97a2a5e6d7ad402-4650169265435319947.bin'), "sub", false);
<\/script><div data-jscall-id="1" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="2" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="3" class="wglmakie-spinner"></div></div></div></div></div>`},u={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="f4243dd8-58e3-49bc-8ed8-716fa987f1bd" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled6407492584158908243.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("f4243dd8-58e3-49bc-8ed8-716fa987f1bd", Bonito.fetch_binary('bonito/bin/8b813e8bd33e7768ce60381285dd4ba747868418-16918776609605709143.bin'), "sub", false);
<\/script><div data-jscall-id="4" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="5" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="6" class="wglmakie-spinner"></div></div></div></div>`},C={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="8b500bad-d010-434d-a54b-17e370d61785" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled6407492584158908243.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("8b500bad-d010-434d-a54b-17e370d61785", Bonito.fetch_binary('bonito/bin/85cf63454e6b1451063aa2602e5b9e7ec1029d77-5877312892687939725.bin'), "sub", false);
<\/script><div data-jscall-id="7"><div data-jscall-id="8">z-index: <input data-jscall-id="9" step="1" type="range" min="1" max="10" oninput="" value="1" autocomplete="off" /><span data-jscall-id="10">1</span></div><div data-jscall-id="11" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="12" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="13" class="wglmakie-spinner"></div></div></div></div></div>`},b={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="33e694d2-c1de-4b27-a1ca-f2db56dc153b" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style></div><div style="display:contents"><script type="module">Bonito.init_session("33e694d2-c1de-4b27-a1ca-f2db56dc153b", Bonito.fetch_binary('bonito/bin/19585dab4482280b313724495485b17a87b9cc44-9753174695289292687.bin'), "sub", false);
<\/script><div data-jscall-id="15">slider 1: <input data-jscall-id="16" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><p data-jscall-id="14"><span class="text-plain" style="white-space: pre-wrap">1</span></p></div></div></div>`},m={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="0417769a-d79a-47ae-83b2-02763645250a" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled6407492584158908243.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("0417769a-d79a-47ae-83b2-02763645250a", Bonito.fetch_binary('bonito/bin/8b8c2039d29f61de543230bc5dadadac8d9c28bb-1591876101029290896.bin'), "sub", false);
<\/script><div data-jscall-id="17"><input data-jscall-id="18" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><input data-jscall-id="19" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><input data-jscall-id="20" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><div data-jscall-id="21" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="22" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="23" class="wglmakie-spinner"></div></div></div></div></div>`},B={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="06b4a752-2e4e-4270-b4ea-eecd553c94cd" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled6407492584158908243.js" type="module"><\/script><link rel="stylesheet" type="text/css" href="bonito/css/popup15566812377123610001.css" /></div><div style="display:contents"><script type="module">Bonito.init_session("06b4a752-2e4e-4270-b4ea-eecd553c94cd", Bonito.fetch_binary('bonito/bin/c20c90f49be2fcfc5cf34616d8b60685345f82a4-18150858798452210249.bin'), "sub", false);
<\/script><div data-jscall-id="24"><div data-jscall-id="25" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="26" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="27" class="wglmakie-spinner"></div></div><span><div data-jscall-id="28" class="popup"></div></span></div></div></div>`},A={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="13193134-8c08-4e80-947c-a8d0f12466bd" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled6407492584158908243.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("13193134-8c08-4e80-947c-a8d0f12466bd", Bonito.fetch_binary('bonito/bin/0d8e70807b3cd44424650ab6deaa4e714c81b45d-8557957547600442626.bin'), "sub", false);
<\/script><div data-jscall-id="29"><div data-jscall-id="30" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="31" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="32" class="wglmakie-spinner"></div></div><span><style data-jscall-id="34">    .mytip {
        position: absolute; display: none;
        background: white; color: black;
        border: 1px solid black; border-radius: 0;
        padding: 2px 6px; font-family: sans-serif;
    }
    .mytip.show { display: block; }
</style><div data-jscall-id="33" class="mytip"></div></span></div></div></div>`},D={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="3a190ac6-fe11-4a12-b58e-f08d2222b736" class="bonito-fragment" style="display:contents"><div style="display:contents"><style>.bs-96288b5fc45bfb51 {
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
</style></div><div style="display:contents"><script type="module">Bonito.init_session("3a190ac6-fe11-4a12-b58e-f08d2222b736", Bonito.fetch_binary('bonito/bin/d66d5558c0e39ff4efb4ebd8eb35d8062ffa604d-15193279470675194976.bin'), "sub", false);
<\/script><div data-jscall-id="36" class=" bs-96288b5fc45bfb51" style=""><input data-jscall-id="37" step="1" type="range" min="1" max="361" oninput="" value="1" autocomplete="off" /><div data-jscall-id="35" class="h-6 w-6 p-2 m-2 rounded shadow"></div></div></div></div>`},f={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="96bad1ff-4f87-454f-974b-af91a1d34ef6" class="bonito-fragment" style="display:contents"><div style="display:contents"><style>.bs-26025097879fbc98 {
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
</style><script src="bonito/js/WGLMakie.bundled6407492584158908243.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("96bad1ff-4f87-454f-974b-af91a1d34ef6", Bonito.fetch_binary('bonito/bin/04609d7fdf54550780ec2bf03d72a4703e915ace-2436260846815941768.bin'), "sub", false);
<\/script><div data-jscall-id="38"><div data-jscall-id="39" class=" bs-786d6c2eb60d9232" style=""><div data-jscall-id="40" class=" bs-e23cb004be3f7160" style=""><div data-jscall-id="41" class=" bs-26025097879fbc98" style=""><h1 data-jscall-id="42">Hello</h1></div><div data-jscall-id="43" class=" bs-c296edb68c1fa297" style=""><div data-jscall-id="44" class=" bs-27a2d2aaed01f8d4" style=""></div><div data-jscall-id="45" class=" bs-8b80b708147c0f08" style=""></div><div data-jscall-id="46" class=" bs-63372476036d9ebf" style=""></div></div><img data-jscall-id="47" src="https://julialang.org/assets/infra/logo.svg" /><div data-jscall-id="48" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="49" height="300px" data-lm-suppress-shortcuts="true" width="300px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="50" class="wglmakie-spinner"></div></div></div></div></div></div></div>`};function v(w,s,_,x,q,j){const p=k("Badge"),l=k("ClientOnly"),e=d("exec-scripts");return o(),E("div",null,[s[4]||(s[4]=a("",21)),i("details",c,[i("summary",null,[s[0]||(s[0]=i("a",{id:"WGLMakie.activate!",href:"#WGLMakie.activate!"},[i("span",{class:"jlbinding"},"WGLMakie.activate!")],-1)),s[1]||(s[1]=g()),n(p,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),s[3]||(s[3]=a("",4)),n(p,{type:"info",class:"source-link",text:"source"},{default:t(()=>[...s[2]||(s[2]=[i("a",{href:"https://github.com/MakieOrg/Makie.jl/blob/05b41c6482dbb892acbeb4e4c95b067fb5c17fb6/WGLMakie/src/WGLMakie.jl#L49-L58",target:"_blank",rel:"noreferrer"},"source",-1)])]),_:1})]),s[5]||(s[5]=a("",32)),n(l,null,{default:t(()=>[h(i("div",F,null,512),[[e]])]),_:1}),s[6]||(s[6]=a("",2)),n(l,null,{default:t(()=>[h(i("div",u,null,512),[[e]])]),_:1}),s[7]||(s[7]=a("",6)),n(l,null,{default:t(()=>[h(i("div",C,null,512),[[e]])]),_:1}),s[8]||(s[8]=a("",3)),n(l,null,{default:t(()=>[h(i("div",b,null,512),[[e]])]),_:1}),s[9]||(s[9]=a("",2)),n(l,null,{default:t(()=>[h(i("div",m,null,512),[[e]])]),_:1}),s[10]||(s[10]=a("",5)),n(l,null,{default:t(()=>[h(i("div",B,null,512),[[e]])]),_:1}),s[11]||(s[11]=a("",4)),n(l,null,{default:t(()=>[h(i("div",A,null,512),[[e]])]),_:1}),s[12]||(s[12]=a("",8)),n(l,null,{default:t(()=>[h(i("div",D,null,512),[[e]])]),_:1}),s[13]||(s[13]=a("",2)),n(l,null,{default:t(()=>[h(i("div",f,null,512),[[e]])]),_:1}),s[14]||(s[14]=a("",6))])}const M=r(y,[["render",v]]);export{T as __pageData,M as default};
