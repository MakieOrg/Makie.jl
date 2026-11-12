import{_ as r,C as k,ap as d,o,c as E,ao as a,j as i,a as g,E as n,w as t,a2 as h}from"./chunks/framework.CoBqyPgU.js";const T=JSON.parse('{"title":"WGLMakie","description":"","frontmatter":{},"headers":[],"relativePath":"explanations/backends/wglmakie.md","filePath":"explanations/backends/wglmakie.md","lastUpdated":null}'),y={name:"explanations/backends/wglmakie.md"},c={class:"jldocstring custom-block",open:""},F={class:"vp-raw-html",innerHTML:`<div><div data-jscall-id="root" id="69d76187-460c-46ec-a4f0-45e9b441d250" class="bonito-fragment" style="display:contents"><div style="display:contents"><script src="bonito/js/Bonito.bundled18292985539897097442.js" type="module"><\/script><style></style><style>@media (prefers-color-scheme: light) {
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
</style></div><div style="display:contents"><script type="module">Bonito.init_session("69d76187-460c-46ec-a4f0-45e9b441d250", Bonito.fetch_binary('bonito/bin/f47449f46905cf4e9bfd9c52ef7442a31b8cd7bf-18127102615483867757.bin'), "root", false);
<\/script><div></div></div></div><div data-jscall-id="subsession-application-dom" id="a1c9666c-163e-4ede-90e1-073b7892e706" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled5062892577746198837.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("a1c9666c-163e-4ede-90e1-073b7892e706", Bonito.fetch_binary('bonito/bin/f2df24db90f7f587955541dbf95b9fa92147aee2-12036182181331247374.bin'), "sub", false);
<\/script><div data-jscall-id="1" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="2" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="3" class="wglmakie-spinner"></div></div></div></div></div>`},u={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="b66cea41-ff27-456f-acd9-3aa615b07fad" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled5062892577746198837.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("b66cea41-ff27-456f-acd9-3aa615b07fad", Bonito.fetch_binary('bonito/bin/24ed13dfa989470abc19ec4061c0faf671f11fef-11698096078470016338.bin'), "sub", false);
<\/script><div data-jscall-id="4" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="5" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="6" class="wglmakie-spinner"></div></div></div></div>`},C={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="617db6c2-55a8-46c7-b7e2-8dcbd607f029" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled5062892577746198837.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("617db6c2-55a8-46c7-b7e2-8dcbd607f029", Bonito.fetch_binary('bonito/bin/3bb38bbdb59ccaf945eed07c862b6e9f8c1358f5-4926852191434892404.bin'), "sub", false);
<\/script><div data-jscall-id="7"><div data-jscall-id="8">z-index: <input data-jscall-id="9" step="1" type="range" min="1" max="10" oninput="" value="1" autocomplete="off" /><span data-jscall-id="10">1</span></div><div data-jscall-id="11" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="12" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="13" class="wglmakie-spinner"></div></div></div></div></div>`},b={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="18157920-8fe3-4d97-9fd5-d1ac8e39dc48" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style></div><div style="display:contents"><script type="module">Bonito.init_session("18157920-8fe3-4d97-9fd5-d1ac8e39dc48", Bonito.fetch_binary('bonito/bin/190f5725e2a35e5ce453c85b0317c1bd65d81681-4530065629990941546.bin'), "sub", false);
<\/script><div data-jscall-id="15">slider 1: <input data-jscall-id="16" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><p data-jscall-id="14"><span class="text-plain" style="white-space: pre-wrap">1</span></p></div></div></div>`},m={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="6ee4d6b3-a6aa-44be-bd8b-7f7539446943" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled5062892577746198837.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("6ee4d6b3-a6aa-44be-bd8b-7f7539446943", Bonito.fetch_binary('bonito/bin/b3fd5d34eeade7fed7f990736c2b7a358889c043-4337088917851895943.bin'), "sub", false);
<\/script><div data-jscall-id="17"><input data-jscall-id="18" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><input data-jscall-id="19" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><input data-jscall-id="20" step="1" type="range" min="1" max="100" oninput="" value="1" autocomplete="off" /><div data-jscall-id="21" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="22" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="23" class="wglmakie-spinner"></div></div></div></div></div>`},B={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="288552e1-d374-436e-9978-e1a346d1c7c4" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled5062892577746198837.js" type="module"><\/script><link rel="stylesheet" type="text/css" href="bonito/css/popup15566812377123610001.css" /></div><div style="display:contents"><script type="module">Bonito.init_session("288552e1-d374-436e-9978-e1a346d1c7c4", Bonito.fetch_binary('bonito/bin/037ad0455a7e5e149ee5959df6d0ee38c056a34e-3916484549865562035.bin'), "sub", false);
<\/script><div data-jscall-id="24"><div data-jscall-id="25" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="26" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="27" class="wglmakie-spinner"></div></div><span><div data-jscall-id="28" class="popup"></div></span></div></div></div>`},A={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="edf814a5-90be-4f83-97c6-2b2e926cd7cb" class="bonito-fragment" style="display:contents"><div style="display:contents"><style></style><style>.wglmakie-spinner {
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
</style><script src="bonito/js/WGLMakie.bundled5062892577746198837.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("edf814a5-90be-4f83-97c6-2b2e926cd7cb", Bonito.fetch_binary('bonito/bin/8d5bced43d9a1884d274d9b3d7cd6af07e18ce6f-15381087624259943196.bin'), "sub", false);
<\/script><div data-jscall-id="29"><div data-jscall-id="30" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="31" height="450px" data-lm-suppress-shortcuts="true" width="600px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="32" class="wglmakie-spinner"></div></div><span><style data-jscall-id="34">    .mytip {
        position: absolute; display: none;
        background: white; color: black;
        border: 1px solid black; border-radius: 0;
        padding: 2px 6px; font-family: sans-serif;
    }
    .mytip.show { display: block; }
</style><div data-jscall-id="33" class="mytip"></div></span></div></div></div>`},f={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="3dedb5a8-ca2a-417c-832d-6bb248416da1" class="bonito-fragment" style="display:contents"><div style="display:contents"><style>.bs-96288b5fc45bfb51 {
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
</style></div><div style="display:contents"><script type="module">Bonito.init_session("3dedb5a8-ca2a-417c-832d-6bb248416da1", Bonito.fetch_binary('bonito/bin/c0855c82fc22d18f2e7cde738f22e82edade4e30-15226411113273151839.bin'), "sub", false);
<\/script><div data-jscall-id="36" class=" bs-96288b5fc45bfb51" style=""><input data-jscall-id="37" step="1" type="range" min="1" max="361" oninput="" value="1" autocomplete="off" /><div data-jscall-id="35" class="h-6 w-6 p-2 m-2 rounded shadow"></div></div></div></div>`},D={class:"vp-raw-html",innerHTML:`<div data-jscall-id="subsession-application-dom" id="2280273c-57a9-4a61-b662-86e0d20b66ba" class="bonito-fragment" style="display:contents"><div style="display:contents"><style>.bs-26025097879fbc98 {
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
</style><script src="bonito/js/WGLMakie.bundled5062892577746198837.js" type="module"><\/script></div><div style="display:contents"><script type="module">Bonito.init_session("2280273c-57a9-4a61-b662-86e0d20b66ba", Bonito.fetch_binary('bonito/bin/01a52eac54ddf4d05f922ddb46cd56ff5851c6d1-17593306428659842115.bin'), "sub", false);
<\/script><div data-jscall-id="38"><div data-jscall-id="39" class=" bs-786d6c2eb60d9232" style=""><div data-jscall-id="40" class=" bs-e23cb004be3f7160" style=""><div data-jscall-id="41" class=" bs-26025097879fbc98" style=""><h1 data-jscall-id="42">Hello</h1></div><div data-jscall-id="43" class=" bs-c296edb68c1fa297" style=""><div data-jscall-id="44" class=" bs-27a2d2aaed01f8d4" style=""></div><div data-jscall-id="45" class=" bs-8b80b708147c0f08" style=""></div><div data-jscall-id="46" class=" bs-63372476036d9ebf" style=""></div></div><img data-jscall-id="47" src="https://julialang.org/assets/infra/logo.svg" /><div data-jscall-id="48" style="width: 100%; height: 100%; position: relative;"><canvas data-jscall-id="49" height="300px" data-lm-suppress-shortcuts="true" width="300px" data-jp-suppress-context-menu tabindex="0" style="display: block"></canvas><div data-jscall-id="50" class="wglmakie-spinner"></div></div></div></div></div></div></div>`};function v(w,s,_,x,q,j){const p=k("Badge"),l=k("ClientOnly"),e=d("exec-scripts");return o(),E("div",null,[s[4]||(s[4]=a("",21)),i("details",c,[i("summary",null,[s[0]||(s[0]=i("a",{id:"WGLMakie.activate!",href:"#WGLMakie.activate!"},[i("span",{class:"jlbinding"},"WGLMakie.activate!")],-1)),s[1]||(s[1]=g()),n(p,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),s[3]||(s[3]=a("",4)),n(p,{type:"info",class:"source-link",text:"source"},{default:t(()=>[...s[2]||(s[2]=[i("a",{href:"https://github.com/MakieOrg/Makie.jl/blob/03e90d90af930679e94bdd7f1508eee15cd7fe0c/WGLMakie/src/WGLMakie.jl#L49-L58",target:"_blank",rel:"noreferrer"},"source",-1)])]),_:1})]),s[5]||(s[5]=a("",32)),n(l,null,{default:t(()=>[h(i("div",F,null,512),[[e]])]),_:1}),s[6]||(s[6]=a("",2)),n(l,null,{default:t(()=>[h(i("div",u,null,512),[[e]])]),_:1}),s[7]||(s[7]=a("",6)),n(l,null,{default:t(()=>[h(i("div",C,null,512),[[e]])]),_:1}),s[8]||(s[8]=a("",3)),n(l,null,{default:t(()=>[h(i("div",b,null,512),[[e]])]),_:1}),s[9]||(s[9]=a("",2)),n(l,null,{default:t(()=>[h(i("div",m,null,512),[[e]])]),_:1}),s[10]||(s[10]=a("",5)),n(l,null,{default:t(()=>[h(i("div",B,null,512),[[e]])]),_:1}),s[11]||(s[11]=a("",4)),n(l,null,{default:t(()=>[h(i("div",A,null,512),[[e]])]),_:1}),s[12]||(s[12]=a("",8)),n(l,null,{default:t(()=>[h(i("div",f,null,512),[[e]])]),_:1}),s[13]||(s[13]=a("",2)),n(l,null,{default:t(()=>[h(i("div",D,null,512),[[e]])]),_:1}),s[14]||(s[14]=a("",6))])}const M=r(y,[["render",v]]);export{T as __pageData,M as default};
