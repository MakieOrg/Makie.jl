const __bodyfunction__ = Dict{Method,Any}()

# Find keyword "body functions" (the function that contains the body
# as written by the developer, called after all missing keyword-arguments
# have been assigned values), in a manner that doesn't depend on
# gensymmed names.
# `mnokw` is the method that gets called when you invoke it without
# supplying any keywords.
function __lookup_kwbody__(mnokw::Method)
    function getsym(arg)
        isa(arg, Symbol) && return arg
        @assert isa(arg, GlobalRef)
        return arg.name
    end

    f = get(__bodyfunction__, mnokw, nothing)
    if f === nothing
        fmod = mnokw.module
        # The lowered code for `mnokw` should look like
        #   %1 = mkw(kwvalues..., #self#, args...)
        #        return %1
        # where `mkw` is the name of the "active" keyword body-function.
        ast = Base.uncompressed_ast(mnokw)
        if isa(ast, Core.CodeInfo) && length(ast.code) >= 2
            callexpr = ast.code[end-1]
            if isa(callexpr, Expr) && callexpr.head == :call
                fsym = callexpr.args[1]
                if isa(fsym, Symbol)
                    f = getfield(fmod, fsym)
                elseif isa(fsym, GlobalRef)
                    if fsym.mod === Core && fsym.name === :_apply
                        f = getfield(mnokw.module, getsym(callexpr.args[2]))
                    elseif fsym.mod === Core && fsym.name === :_apply_iterate
                        f = getfield(mnokw.module, getsym(callexpr.args[3]))
                    else
                        f = getfield(fsym.mod, fsym.name)
                    end
                else
                    f = missing
                end
            else
                f = missing
            end
        else
            f = missing
        end
        __bodyfunction__[mnokw] = f
    end
    return f
end

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(get_template!),String,Dict{String, String},Dict{Symbol, Any}})   # time: 0.21933882
    isdefined(GLAbstraction, Symbol("#63#68")) && Base.precompile(Tuple{getfield(GLAbstraction, Symbol("#63#68"))})   # time: 0.086304404
    Base.precompile(Tuple{typeof(gluniform),Int32,Observable{Vec{2, Float32}}})   # time: 0.06477806
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:x_repeat,), Tuple{Symbol}},Type{Texture},Vector{Float16}})   # time: 0.03858548
    Base.precompile(Tuple{typeof(signal_convert),Type,Observable{Vec2{Int32}}})   # time: 0.038141333
    Base.precompile(Tuple{typeof(gl_convert),Type{GLBuffer},Observable{Vec{2, Float32}}})   # time: 0.031721786
    Base.precompile(Tuple{typeof(toglsltype_string),GLBuffer{Point{3, Float32}}})   # time: 0.03062245
    Base.precompile(Tuple{typeof(signal_convert),Type,Observable{Float32}})   # time: 0.022515636
    Base.precompile(Tuple{typeof(compile_program),Vector{Shader},Vector{Tuple{Int64, String}}})   # time: 0.021999607
    let fbody = try __lookup_kwbody__(which(TextureParameters, (Type,Int64,))) catch missing end
        if !ismissing(fbody)
            precompile(fbody, (Symbol,Symbol,Symbol,Symbol,Symbol,Float32,Type{TextureParameters},Type,Int64,))
        end
    end   # time: 0.019532876
    Base.precompile(Tuple{typeof(gl_convert),Observable{Any}})   # time: 0.01664884
    Base.precompile(Tuple{typeof(gl_convert),Observable{Bool}})   # time: 0.0149467
    Base.precompile(Tuple{typeof(gl_convert),Observable{RGBA{Float32}}})   # time: 0.014625993
    Base.precompile(Tuple{typeof(const_lift),typeof(length),Observable{Vector{Point{2, Float32}}}})   # time: 0.014371832
    Base.precompile(Tuple{typeof(gl_convert),Type{GLBuffer},Observable{Vector{Point{3, Float32}}}})   # time: 0.01388594
    Base.precompile(Tuple{typeof(gl_convert),Observable{Int64}})   # time: 0.01345424
    Base.precompile(Tuple{typeof(const_lift),typeof(length),Observable{Vector{Point{3, Float32}}}})   # time: 0.011757969
    Base.precompile(Tuple{typeof(gl_convert),Type{GLBuffer},Observable{Vector{Vec{2, Float32}}}})   # time: 0.011719398
    isdefined(GLAbstraction, Symbol("#LazyShader#49#50")) && Base.precompile(Tuple{getfield(GLAbstraction, Symbol("#LazyShader#49#50")),Base.Iterators.Pairs{Symbol, Dict{String, String}, Tuple{Symbol}, NamedTuple{(:view,), Tuple{Dict{String, String}}}},Type{LazyShader},String,Vararg{String, N} where N})   # time: 0.010064982
    Base.precompile(Tuple{typeof(gl_convert),Type{GLBuffer},Observable{Vector{Vec{4, Float32}}}})   # time: 0.008807838
    isdefined(GLAbstraction, Symbol("#63#68")) && Base.precompile(Tuple{getfield(GLAbstraction, Symbol("#63#68"))})   # time: 0.008238689
    Base.precompile(Tuple{typeof(gl_convert),Type{GLBuffer},Observable{Vector{Point{2, Float32}}}})   # time: 0.008220657
    Base.precompile(Tuple{typeof(gl_convert),Type{GLBuffer},Observable{Vector{RGBA{Float32}}}})   # time: 0.007779626
    Base.precompile(Tuple{typeof(toglsltype_string),GLBuffer{Vec{4, Float32}}})   # time: 0.007245759
    Base.precompile(Tuple{typeof(isa_gl_struct),Observable{Int64}})   # time: 0.00689424
    Base.precompile(Tuple{typeof(toglsltype_string),Texture{Float16, 2}})   # time: 0.006558549
    Base.precompile(Tuple{typeof(gl_convert),Type{GLBuffer},Observable{Vector{Float32}}})   # time: 0.006534443
    Base.precompile(Tuple{typeof(gl_convert),SMatrix{4, 4, Float32, 16}})   # time: 0.0058618
    Base.precompile(Tuple{typeof(isa_gl_struct),Observable{Float32}})   # time: 0.005198346
    Base.precompile(Tuple{typeof(isa_gl_struct),Observable{Any}})   # time: 0.004741108
    Base.precompile(Tuple{typeof(toglsltype_string),Texture{Float16, 1}})   # time: 0.004597425
    Base.precompile(Tuple{typeof(toglsltype_string),GLBuffer{RGBA{Float32}}})   # time: 0.00437181
    Base.precompile(Tuple{typeof(isa_gl_struct),Observable{Vec2{Int32}}})   # time: 0.004354946
    Base.precompile(Tuple{typeof(isa_gl_struct),Observable{Int32}})   # time: 0.004301191
    Base.precompile(Tuple{typeof(isa_gl_struct),Observable{SMatrix{4, 4, Float32, 16}}})   # time: 0.004184706
    Base.precompile(Tuple{typeof(isa_gl_struct),Observable{Vec{3, Float32}}})   # time: 0.004105391
    Base.precompile(Tuple{typeof(isa_gl_struct),Observable{Vec{2, Float32}}})   # time: 0.004101697
    Base.precompile(Tuple{typeof(toglsltype_string),GLBuffer{Point{2, Float32}}})   # time: 0.003962705
    Base.precompile(Tuple{typeof(toglsltype_string),GLBuffer{Vec{2, Float32}}})   # time: 0.003796558
    Base.precompile(Tuple{typeof(isa_gl_struct),Observable{RGBA{Float32}}})   # time: 0.003778398
    Base.precompile(Tuple{typeof(isa_gl_struct),Observable{Bool}})   # time: 0.00368915
    Base.precompile(Tuple{typeof(isa_gl_struct),Dict{Symbol, Any}})   # time: 0.003686279
    Base.precompile(Tuple{typeof(isa_gl_struct),Nothing})   # time: 0.003181062
    Base.precompile(Tuple{typeof(isa_gl_struct),Symbol})   # time: 0.003076398
    Base.precompile(Tuple{typeof(isa_gl_struct),Bool})   # time: 0.003013663
    Base.precompile(Tuple{typeof(gl_convert),Vec{2, Float32}})   # time: 0.002978386
    Base.precompile(Tuple{typeof(mustache2replacement),String,Dict{String, String},Dict{Symbol, Any}})   # time: 0.002830558
    Base.precompile(Tuple{typeof(gluniform),Int32,Int64,Texture{RGBA{N0f8}, 2}})   # time: 0.002434047
    Base.precompile(Tuple{typeof(map_texture_paramers),Tuple{Symbol, Symbol}})   # time: 0.00121505
end
