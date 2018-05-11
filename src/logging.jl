
# info, debug, gc, signals, performance
const log_level = RefValue((false, false, false, false, false))

function enable_ith(i, value::Bool)
    log_level[] = ntuple(j-> j == i ? value : log_level[][j], Val{5})
    value
end
log_info(value::Bool = true) = enable_ith(1, value)

const logging_io = RefValue(STDOUT)
macro info(args...)
    quote
        if log_level[][1]
            print_with_color(:light_green, STDOUT, $(esc.(args)...), "\n")
        end
    end
end
macro debug(args...)
    quote
        if log_level[][2]
            print_with_color(:red, logging_io[], $(esc.(args)...))
        end
    end
end

macro log_gc(args...)
    quote
        if log_level[][3]
            save_print(logging_io[], $(esc.(args)...))
        end
    end
end
macro log_signals(args...)
    quote
        if log_level[][4]
            save_print(logging_io[], $(esc.(args)...))
        end
    end
end
function print_stats(io::IO, elapsedtime, bytes, gctime, allocs)
    @printf(io, "%10.6f seconds", elapsedtime/1e9)
    if bytes != 0 || allocs != 0
        bytes, mb = Base.prettyprint_getunits(bytes, length(Base._mem_units), Int64(1024))
        allocs, ma = Base.prettyprint_getunits(allocs, length(Base._cnt_units), Int64(1000))
        if ma == 1
            @printf(io, " (%d%s allocation%s: ", allocs, Base._cnt_units[ma], allocs==1 ? "" : "s")
        else
            @printf(io, " (%.2f%s allocations: ", allocs, Base._cnt_units[ma])
        end
        if mb == 1
            @printf(io, "%d %s%s", bytes, Base._mem_units[mb], bytes==1 ? "" : "s")
        else
            @printf(io, "%.3f %s", bytes, Base._mem_units[mb])
        end
        if gctime > 0
            @printf(io, ", %.2f%% gc time", 100*gctime/elapsedtime)
        end
        print(io, ")")
    elseif gctime > 0
        @printf(io, ", %.2f%% gc time", 100*gctime/elapsedtime)
    end
    println(io)
end
macro log_performance(name, expr)
    quote
        if log_level[][5]
            gc_stats = Base.gc_num()
            t_stats = Base.time_ns()
            val = $(esc(expr))
            time_diff = Base.time_ns() - t_stats
            gc_diff = Base.GC_Diff(Base.gc_num(), gc_stats)
            print(logging_io[], $name, ": ")
            print_stats(
                logging_io[], time_diff, gc_diff.allocd,
                gc_diff.total_time, Base.gc_alloc_count(gc_diff)
            )
        else
            val = $(esc(expr))
        end
        return val
    end
end



const io_lock = ReentrantLock()
save_print(args...) = save_print(io, args...)
function save_print(io::IO, args...)
    @async begin
        try
            lock(io)
            lock(io_lock)
            print(io, string(args..., "\n"))
        finally
            unlock(io_lock)
            unlock(io)
        end
    end
end
