import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import mathjax3 from "markdown-it-mathjax3";
import footnote from "markdown-it-footnote";

const baseTemp = {
  base: '/previews/PR4989/',// TODO: replace this in makedocs!
}

const navTemp = {
  nav: [
{ text: 'Home', link: '/index' },
{ text: 'Reference', collapsed: false, items: [
{ text: 'Blocks', collapsed: false, items: [
{ text: 'Overview', link: '/reference/blocks/overview' },
{ text: 'Axis', link: '/reference/blocks/axis' },
{ text: 'Axis3', link: '/reference/blocks/axis3' },
{ text: 'Box', link: '/reference/blocks/box' },
{ text: 'Button', link: '/reference/blocks/button' },
{ text: 'Checkbox', link: '/reference/blocks/checkbox' },
{ text: 'Colorbar', link: '/reference/blocks/colorbar' },
{ text: 'GridLayout', link: '/reference/blocks/gridlayout' },
{ text: 'IntervalSlider', link: '/reference/blocks/intervalslider' },
{ text: 'Label', link: '/reference/blocks/label' },
{ text: 'Legend', link: '/reference/blocks/legend' },
{ text: 'LScene', link: '/reference/blocks/lscene' },
{ text: 'Menu', link: '/reference/blocks/menu' },
{ text: 'PolarAxis', link: '/reference/blocks/polaraxis' },
{ text: 'Slider', link: '/reference/blocks/slider' },
{ text: 'SliderGrid', link: '/reference/blocks/slidergrid' },
{ text: 'Textbox', link: '/reference/blocks/textbox' },
{ text: 'Toggle', link: '/reference/blocks/toggle' }]
 },
{ text: 'Plots', collapsed: false, items: [
{ text: 'Overview', link: '/reference/plots/overview' },
{ text: 'ablines', link: '/reference/plots/ablines' },
{ text: 'arc', link: '/reference/plots/arc' },
{ text: 'arrows', link: '/reference/plots/arrows' },
{ text: 'band', link: '/reference/plots/band' },
{ text: 'barplot', link: '/reference/plots/barplot' },
{ text: 'boxplot', link: '/reference/plots/boxplot' },
{ text: 'bracket', link: '/reference/plots/bracket' },
{ text: 'contour', link: '/reference/plots/contour' },
{ text: 'contour3d', link: '/reference/plots/contour3d' },
{ text: 'contourf', link: '/reference/plots/contourf' },
{ text: 'crossbar', link: '/reference/plots/crossbar' },
{ text: 'datashader', link: '/reference/plots/datashader' },
{ text: 'density', link: '/reference/plots/density' },
{ text: 'ecdfplot', link: '/reference/plots/ecdf' },
{ text: 'errorbars', link: '/reference/plots/errorbars' },
{ text: 'heatmap', link: '/reference/plots/heatmap' },
{ text: 'hexbin', link: '/reference/plots/hexbin' },
{ text: 'hist', link: '/reference/plots/hist' },
{ text: 'hlines', link: '/reference/plots/hlines' },
{ text: 'hspan', link: '/reference/plots/hspan' },
{ text: 'image', link: '/reference/plots/image' },
{ text: 'lines', link: '/reference/plots/lines' },
{ text: 'linesegments', link: '/reference/plots/linesegments' },
{ text: 'mesh', link: '/reference/plots/mesh' },
{ text: 'meshscatter', link: '/reference/plots/meshscatter' },
{ text: 'pie', link: '/reference/plots/pie' },
{ text: 'poly', link: '/reference/plots/poly' },
{ text: 'qqnorm', link: '/reference/plots/qqnorm' },
{ text: 'qqplot', link: '/reference/plots/qqplot' },
{ text: 'rainclouds', link: '/reference/plots/rainclouds' },
{ text: 'rangebars', link: '/reference/plots/rangebars' },
{ text: 'scatter', link: '/reference/plots/scatter' },
{ text: 'scatterlines', link: '/reference/plots/scatterlines' },
{ text: 'series', link: '/reference/plots/series' },
{ text: 'spy', link: '/reference/plots/spy' },
{ text: 'stairs', link: '/reference/plots/stairs' },
{ text: 'stem', link: '/reference/plots/stem' },
{ text: 'stephist', link: '/reference/plots/stephist' },
{ text: 'streamplot', link: '/reference/plots/streamplot' },
{ text: 'surface', link: '/reference/plots/surface' },
{ text: 'text', link: '/reference/plots/text' },
{ text: 'textlabel', link: '/reference/plots/textlabel' },
{ text: 'tooltip', link: '/reference/plots/tooltip' },
{ text: 'tricontourf', link: '/reference/plots/tricontourf' },
{ text: 'triplot', link: '/reference/plots/triplot' },
{ text: 'violin', link: '/reference/plots/violin' },
{ text: 'vlines', link: '/reference/plots/vlines' },
{ text: 'volume', link: '/reference/plots/volume' },
{ text: 'volumeslices', link: '/reference/plots/volumeslices' },
{ text: 'voronoiplot', link: '/reference/plots/voronoiplot' },
{ text: 'voxels', link: '/reference/plots/voxels' },
{ text: 'vspan', link: '/reference/plots/vspan' },
{ text: 'waterfall', link: '/reference/plots/waterfall' },
{ text: 'wireframe', link: '/reference/plots/wireframe' }]
 },
{ text: 'Generic Concepts', collapsed: false, items: [
{ text: 'Clip Planes', link: '/reference/generic/clip_planes' },
{ text: 'Transformations', link: '/reference/generic/transformations' },
{ text: 'space', link: '/reference/generic/space' }]
 },
{ text: 'Scene', collapsed: false, items: [
{ text: 'Lighting', link: '/reference/scene/lighting' },
{ text: 'Matcap', link: '/reference/scene/matcap' },
{ text: 'SSAO', link: '/reference/scene/SSAO' }]
 }]
 },
{ text: 'Tutorials', collapsed: false, items: [
{ text: 'Getting started', link: '/tutorials/getting-started' },
{ text: 'Aspect ratios and automatic figure sizes', link: '/tutorials/aspect-tutorial' },
{ text: 'Creating complex layouts', link: '/tutorials/layout-tutorial' },
{ text: 'A primer on Makies scene graph', link: '/tutorials/scenes' },
{ text: 'Wrapping existing recipes for new types', link: '/tutorials/wrap-existing-recipe' },
{ text: 'Pixel Perfect Rendering', link: '/tutorials/pixel-perfect-rendering' },
{ text: 'Creating an Inset Plot', link: '/tutorials/inset-plot-tutorial' }]
 },
{ text: 'Explanations', collapsed: false, items: [
{ text: 'Backends', collapsed: false, items: [
{ text: 'What is a backend', link: '/explanations/backends/backends' },
{ text: 'CairoMakie', link: '/explanations/backends/cairomakie' },
{ text: 'GLMakie', link: '/explanations/backends/glmakie' },
{ text: 'RPRMakie', link: '/explanations/backends/rprmakie' },
{ text: 'WGLMakie', link: '/explanations/backends/wglmakie' }]
 },
{ text: 'Animations', link: '/explanations/animation' },
{ text: 'Blocks', link: '/explanations/blocks' },
{ text: 'Cameras', link: '/explanations/cameras' },
{ text: 'Conversion, Transformation and Projection Pipeline', link: '/explanations/conversion_pipeline' },
{ text: 'Colors', link: '/explanations/colors' },
{ text: 'Dimension conversions', link: '/explanations/dim-converts' },
{ text: 'Events', link: '/explanations/events' },
{ text: 'Figures', link: '/explanations/figure' },
{ text: 'Frequently Asked Questions', link: '/explanations/faq' },
{ text: 'Fonts', link: '/explanations/fonts' },
{ text: 'GridLayouts', link: '/explanations/layouting' },
{ text: 'Headless', link: '/explanations/headless' },
{ text: 'Inspecting data', link: '/explanations/inspector' },
{ text: 'LaTeX', link: '/explanations/latex' },
{ text: 'Observables', link: '/explanations/observables' },
{ text: 'Plot methods', link: '/explanations/plot_method_signatures' },
{ text: 'Recipes', link: '/explanations/recipes' },
{ text: 'Scenes', link: '/explanations/scenes' },
{ text: 'SpecApi', link: '/explanations/specapi' },
{ text: 'Theming', collapsed: false, items: [
{ text: 'Themes', link: '/explanations/theming/themes' },
{ text: 'Predefined themes', link: '/explanations/theming/predefined_themes' }]
 },
{ text: 'Transparency', link: '/explanations/transparency' }]
 },
{ text: 'How-Tos', collapsed: false, items: [
{ text: 'How to match figure size, font sizes and dpi', link: '/how-to/match-figure-size-font-sizes-and-dpi' },
{ text: 'How to draw boxes around subfigures', link: '/how-to/draw-boxes-around-subfigures' },
{ text: 'How to save a figure with transparency', link: '/how-to/save-figure-with-transparency' }]
 },
{ text: 'Resources', collapsed: false, items: [
{ text: 'API', link: '/api' },
{ text: 'Changelog', link: '/changelog' },
{ text: 'Ecosystem', link: '/ecosystem' }]
 }
]
,
}

const nav = [
  ...navTemp.nav,
  {
    component: 'VersionPicker'
  }
]

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: baseTemp.base,
  title: 'Makie',
  description: 'Create impressive data visualizations with Makie, the plotting ecosystem for the Julia language. Build aesthetic plots with beautiful customizable themes, control every last detail of publication quality vector graphics, assemble complex layouts and quickly prototype interactive applications to explore your data live.',
  lastUpdated: true,
  cleanUrls: true,
  outDir: '../1', // This is required for MarkdownVitepress to work correctly...
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['script', {src: '/versions.js'}],
    ['script', {src: `${baseTemp.base}siteinfo.js`}],
    ['script', {async:'', defer:'', src:'https://api.makie.org/latest.js'}],
    ['noscript', {}, '<img alt="" referrerpolicy="no-referrer-when-downgrade" src="https://api.makie.org/noscript.gif"/>'],
  ],
  ignoreDeadLinks: true,

  markdown: {
    math: true,
    config(md) {
      md.use(tabsMarkdownPlugin),
      md.use(mathjax3),
      md.use(footnote)
    },
    theme: {
      light: "github-light",
      dark: "github-dark"}
  },
  themeConfig: {
    outline: 'deep',
    logo: { src: '/logo.png', width: 24, height: 24},
    search: {
      provider: 'local',
      options: {
        detailedView: true
      }
    },
    nav,
    sidebar: [
{ text: 'Home', link: '/index' },
{ text: 'Reference', collapsed: false, items: [
{ text: 'Blocks', collapsed: false, items: [
{ text: 'Overview', link: '/reference/blocks/overview' },
{ text: 'Axis', link: '/reference/blocks/axis' },
{ text: 'Axis3', link: '/reference/blocks/axis3' },
{ text: 'Box', link: '/reference/blocks/box' },
{ text: 'Button', link: '/reference/blocks/button' },
{ text: 'Checkbox', link: '/reference/blocks/checkbox' },
{ text: 'Colorbar', link: '/reference/blocks/colorbar' },
{ text: 'GridLayout', link: '/reference/blocks/gridlayout' },
{ text: 'IntervalSlider', link: '/reference/blocks/intervalslider' },
{ text: 'Label', link: '/reference/blocks/label' },
{ text: 'Legend', link: '/reference/blocks/legend' },
{ text: 'LScene', link: '/reference/blocks/lscene' },
{ text: 'Menu', link: '/reference/blocks/menu' },
{ text: 'PolarAxis', link: '/reference/blocks/polaraxis' },
{ text: 'Slider', link: '/reference/blocks/slider' },
{ text: 'SliderGrid', link: '/reference/blocks/slidergrid' },
{ text: 'Textbox', link: '/reference/blocks/textbox' },
{ text: 'Toggle', link: '/reference/blocks/toggle' }]
 },
{ text: 'Plots', collapsed: false, items: [
{ text: 'Overview', link: '/reference/plots/overview' },
{ text: 'ablines', link: '/reference/plots/ablines' },
{ text: 'arc', link: '/reference/plots/arc' },
{ text: 'arrows', link: '/reference/plots/arrows' },
{ text: 'band', link: '/reference/plots/band' },
{ text: 'barplot', link: '/reference/plots/barplot' },
{ text: 'boxplot', link: '/reference/plots/boxplot' },
{ text: 'bracket', link: '/reference/plots/bracket' },
{ text: 'contour', link: '/reference/plots/contour' },
{ text: 'contour3d', link: '/reference/plots/contour3d' },
{ text: 'contourf', link: '/reference/plots/contourf' },
{ text: 'crossbar', link: '/reference/plots/crossbar' },
{ text: 'datashader', link: '/reference/plots/datashader' },
{ text: 'density', link: '/reference/plots/density' },
{ text: 'ecdfplot', link: '/reference/plots/ecdf' },
{ text: 'errorbars', link: '/reference/plots/errorbars' },
{ text: 'heatmap', link: '/reference/plots/heatmap' },
{ text: 'hexbin', link: '/reference/plots/hexbin' },
{ text: 'hist', link: '/reference/plots/hist' },
{ text: 'hlines', link: '/reference/plots/hlines' },
{ text: 'hspan', link: '/reference/plots/hspan' },
{ text: 'image', link: '/reference/plots/image' },
{ text: 'lines', link: '/reference/plots/lines' },
{ text: 'linesegments', link: '/reference/plots/linesegments' },
{ text: 'mesh', link: '/reference/plots/mesh' },
{ text: 'meshscatter', link: '/reference/plots/meshscatter' },
{ text: 'pie', link: '/reference/plots/pie' },
{ text: 'poly', link: '/reference/plots/poly' },
{ text: 'qqnorm', link: '/reference/plots/qqnorm' },
{ text: 'qqplot', link: '/reference/plots/qqplot' },
{ text: 'rainclouds', link: '/reference/plots/rainclouds' },
{ text: 'rangebars', link: '/reference/plots/rangebars' },
{ text: 'scatter', link: '/reference/plots/scatter' },
{ text: 'scatterlines', link: '/reference/plots/scatterlines' },
{ text: 'series', link: '/reference/plots/series' },
{ text: 'spy', link: '/reference/plots/spy' },
{ text: 'stairs', link: '/reference/plots/stairs' },
{ text: 'stem', link: '/reference/plots/stem' },
{ text: 'stephist', link: '/reference/plots/stephist' },
{ text: 'streamplot', link: '/reference/plots/streamplot' },
{ text: 'surface', link: '/reference/plots/surface' },
{ text: 'text', link: '/reference/plots/text' },
{ text: 'textlabel', link: '/reference/plots/textlabel' },
{ text: 'tooltip', link: '/reference/plots/tooltip' },
{ text: 'tricontourf', link: '/reference/plots/tricontourf' },
{ text: 'triplot', link: '/reference/plots/triplot' },
{ text: 'violin', link: '/reference/plots/violin' },
{ text: 'vlines', link: '/reference/plots/vlines' },
{ text: 'volume', link: '/reference/plots/volume' },
{ text: 'volumeslices', link: '/reference/plots/volumeslices' },
{ text: 'voronoiplot', link: '/reference/plots/voronoiplot' },
{ text: 'voxels', link: '/reference/plots/voxels' },
{ text: 'vspan', link: '/reference/plots/vspan' },
{ text: 'waterfall', link: '/reference/plots/waterfall' },
{ text: 'wireframe', link: '/reference/plots/wireframe' }]
 },
{ text: 'Generic Concepts', collapsed: false, items: [
{ text: 'Clip Planes', link: '/reference/generic/clip_planes' },
{ text: 'Transformations', link: '/reference/generic/transformations' },
{ text: 'space', link: '/reference/generic/space' }]
 },
{ text: 'Scene', collapsed: false, items: [
{ text: 'Lighting', link: '/reference/scene/lighting' },
{ text: 'Matcap', link: '/reference/scene/matcap' },
{ text: 'SSAO', link: '/reference/scene/SSAO' }]
 }]
 },
{ text: 'Tutorials', collapsed: false, items: [
{ text: 'Getting started', link: '/tutorials/getting-started' },
{ text: 'Aspect ratios and automatic figure sizes', link: '/tutorials/aspect-tutorial' },
{ text: 'Creating complex layouts', link: '/tutorials/layout-tutorial' },
{ text: 'A primer on Makies scene graph', link: '/tutorials/scenes' },
{ text: 'Wrapping existing recipes for new types', link: '/tutorials/wrap-existing-recipe' },
{ text: 'Pixel Perfect Rendering', link: '/tutorials/pixel-perfect-rendering' },
{ text: 'Creating an Inset Plot', link: '/tutorials/inset-plot-tutorial' }]
 },
{ text: 'Explanations', collapsed: false, items: [
{ text: 'Backends', collapsed: false, items: [
{ text: 'What is a backend', link: '/explanations/backends/backends' },
{ text: 'CairoMakie', link: '/explanations/backends/cairomakie' },
{ text: 'GLMakie', link: '/explanations/backends/glmakie' },
{ text: 'RPRMakie', link: '/explanations/backends/rprmakie' },
{ text: 'WGLMakie', link: '/explanations/backends/wglmakie' }]
 },
{ text: 'Animations', link: '/explanations/animation' },
{ text: 'Blocks', link: '/explanations/blocks' },
{ text: 'Cameras', link: '/explanations/cameras' },
{ text: 'Conversion, Transformation and Projection Pipeline', link: '/explanations/conversion_pipeline' },
{ text: 'Colors', link: '/explanations/colors' },
{ text: 'Dimension conversions', link: '/explanations/dim-converts' },
{ text: 'Events', link: '/explanations/events' },
{ text: 'Figures', link: '/explanations/figure' },
{ text: 'Frequently Asked Questions', link: '/explanations/faq' },
{ text: 'Fonts', link: '/explanations/fonts' },
{ text: 'GridLayouts', link: '/explanations/layouting' },
{ text: 'Headless', link: '/explanations/headless' },
{ text: 'Inspecting data', link: '/explanations/inspector' },
{ text: 'LaTeX', link: '/explanations/latex' },
{ text: 'Observables', link: '/explanations/observables' },
{ text: 'Plot methods', link: '/explanations/plot_method_signatures' },
{ text: 'Recipes', link: '/explanations/recipes' },
{ text: 'Scenes', link: '/explanations/scenes' },
{ text: 'SpecApi', link: '/explanations/specapi' },
{ text: 'Theming', collapsed: false, items: [
{ text: 'Themes', link: '/explanations/theming/themes' },
{ text: 'Predefined themes', link: '/explanations/theming/predefined_themes' }]
 },
{ text: 'Transparency', link: '/explanations/transparency' }]
 },
{ text: 'How-Tos', collapsed: false, items: [
{ text: 'How to match figure size, font sizes and dpi', link: '/how-to/match-figure-size-font-sizes-and-dpi' },
{ text: 'How to draw boxes around subfigures', link: '/how-to/draw-boxes-around-subfigures' },
{ text: 'How to save a figure with transparency', link: '/how-to/save-figure-with-transparency' }]
 },
{ text: 'Resources', collapsed: false, items: [
{ text: 'API', link: '/api' },
{ text: 'Changelog', link: '/changelog' },
{ text: 'Ecosystem', link: '/ecosystem' }]
 }
]
,
    editLink: { pattern: "https://github.com/MakieOrg/Makie.jl/edit/master/docs/src/:path" },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/MakieOrg/Makie.jl' }
    ],
    footer: {
      message: 'Made with <a href="https://luxdl.github.io/DocumenterVitepress.jl/dev/" target="_blank"><strong>DocumenterVitepress.jl</strong></a><br>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}.`
    }
  }
})