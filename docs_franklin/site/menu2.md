@def title = "More goodies"
@def hascode = true
@def rss = "A short description of the page which would serve as **blurb** in a `RSS` feed; you can use basic markdown here but the whole description string must be a single line (not a multiline string). Like this one for instance. Keep in mind that styling is minimal in RSS so for instance don't expect maths or fancy styling to work; images should be ok though: ![](https://upload.wikimedia.org/wikipedia/en/b/b0/Rick_and_Morty_characters.jpg)"
@def rss_title = "More goodies"
@def rss_pubdate = Date(2019, 5, 1)

@def tags = ["syntax", "code", "image"]

# More goodies

\toc

## More markdown support

The Julia Markdown parser in Julia's stdlib is not exactly complete and Franklin strives to bring useful extensions that are either defined in standard specs such as Common Mark or that just seem like useful extensions.

* indirect references for instance [like so]

[like so]: http://existentialcomics.com/

or also for images

![][some image]

some people find that useful as it allows referring multiple times to the same link for instance.

[some image]: https://upload.wikimedia.org/wikipedia/commons/9/90/Krul.svg

* un-qualified code blocks are allowed and are julia by default, indented code blocks are not supported by default (and there support will disappear completely in later version)

```
a = 1
b = a+1
```

you can specify the default language with `@def lang = "julia"`.
If you actually want a "plain" code block, qualify it as `plaintext` like

```plaintext
so this is plain-text stuff.
```

## A bit more highlighting

Extension of highlighting for `pkg` an `shell` mode in Julia:

```julia-repl
(v1.4) pkg> add Franklin
shell> blah
julia> 1+1
(Sandbox) pkg> resolve
```

you can tune the colouring in the CSS etc via the following classes:

* `.hljs-meta` (for `julia>`)
* `.hljs-metas` (for `shell>`)
* `.hljs-metap` (for `...pkg>`)

## More customisation

Franklin, by design, gives you a lot of flexibility to define how you want stuff be done, this includes doing your own parsing/processing and your own HTML generation using Julia code.

In order to do this, you can define two types of functions in a `utils.jl` file which will complement your `config.md` file:

* `hfun_*` allow you to plug custom-generated HTML somewhere
* `lx_*` allow you to do custom parsing of markdown and generation of HTML

The former (`hfun_*`) is most likely to be useful.

### Custom "hfun"

If you define a function `hfun_bar` in the `utils.jl` then you have access to a new template function `{{bar ...}}`. The parameters are passed as a list of strings, for instance variable names but it  could just be strings as well.

For instance:

```julia
function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end
```

~~~
.hf {background-color:black;color:white;font-weight:bold;}
~~~

Can be called with `{{bar 4}}`: **{{bar 4}}**.

Usually you will want to pass variable name (either local or global) and collect their value via one of `locvar`, `globvar` or `pagevar` depending on your use case.
Let's have another toy example:

```julia
function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("menu1", var)
end
```

Which you can use like this `{{m1fill title}}`: **{{m1fill title}}**. Of course  in this specific case you could also have used `{{fill title menu1}}`: **{{fill title menu1}}**.

Of course these examples are not very useful, in practice you might want to use it to generate actual HTML in a specific way using Julia code.
For instance you can use it to customise how [tag pages look like](/menu3/#customising_tag_pages).

A nice example of what you can do is in the [SymbolicUtils.jl manual](https://juliasymbolics.github.io/SymbolicUtils.jl/api/) where they use a `hfun_` to generate HTML encapsulating the content of code docstrings, in a way doing something similar to what Documenter does. See [how they defined it](https://github.com/JuliaSymbolics/SymbolicUtils.jl/blob/website/utils.jl).

**Note**: the  output **will not** be reprocessed by Franklin, if you want to generate markdown which should be processed by Franklin, then use `return fd2html(markdown, internal=true)` at the end.

### Custom "lx"

These commands will look the same as latex commands but what they do with their content is now entirely controlled by your code.
You can use this to do your own parsing of specific chunks of your content if you so desire.

The definition of `lx_*` commands **must** look like this:

```julia
function lx_baz(com, _)
  # keep this first line
  brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
  return uppercase(brace_content)
end
```

You can call the above with `\baz{some string}`: \baz{some string}.

**Note**: the output **will be** reprocessed by Franklin, if you want to avoid this, then escape the output by using `return "~~~" * s * "~~~"` and it will be plugged  in as is in the HTML.
