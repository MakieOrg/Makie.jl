using CSV
using DataFrames
using Distributed

results = begin
    df = DataFrame()

    for file in readdir("metrics", join = true)

        code = read(file, String)
        parts = split(code, r"^(?=## )"m, keepempty = false)

        local i_proc
        try
            i_proc = addprocs(1)[1]

            @everywhere i_proc begin
                using Pkg
            end

            @everywhere i_proc begin
                pkg"activate --temp"
                pkg"dev .. MakieCore GLMakie CairoMakie"
                @timed begin end
            end

            for part in parts
                partname = match(r"^## (.*)", part)[1] |> strip
                @info "executing part: $partname"
                partcode = """
                    @timed begin
                        $part
                        nothing
                    end
                """
                timing = remotecall_fetch(i_proc, partcode) do p
                    include_string(Main, p)
                end

                push!(df, (
                    juliaversion = string(Sys.VERSION),
                    name = partname,
                    time = timing.time,
                    allocations = timing.bytes,
                    gc_time = timing.gctime,
                ))
            end

        finally
            rmprocs(i_proc)
        end
    end
    df
end
