include("library.jl")

function filestring(entry)
    string(entry.file, ':', first(entry.file_range))
end

function eval_entry(::MIME"text/markdown", entry)
    source = string(entry.toplevel, "\n", entry.source)
    result = eval_string(source, filestring(entry))
    string_result = eval(Main, :(sprint(show, MIME"text/html"(), $result)))
    """
    ```Julia
        $source
    ```
    ```@raw html
        $string_result
    ```
    """
end

function preprocess
end
