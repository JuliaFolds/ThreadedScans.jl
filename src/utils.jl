function debugging end
enable_debug() = @eval debugging() = true
disable_debug() = @eval debugging() = false
# enable_debug()
disable_debug()

macro _assert(args...)
    call = Expr(
        :macrocall,
        getfield(ArgCheck, Symbol("@check")),  # injecting the callable for esc
        __source__,
        args...,
    )
    ex = Expr(:block, __source__, call)
    quote
        if $debugging()
            $ex
        end
        nothing
    end |> esc
end

pause() = ccall(:jl_cpu_pause, Cvoid, ())


function halve(xs::AbstractVector)
    mid = length(xs) ÷ 2
    left = @view xs[firstindex(xs):firstindex(xs)-1+mid]
    right = @view xs[firstindex(xs)+mid:end]
    return (left, right)
end

struct Partitioned{T}
    xs::T
    nchunks::Int
    chunksize::Int
end

Base.length(p::Partitioned) = p.nchunks
Base.eachindex(p::Partitioned) = 1:length(p)

function Base.getindex(p::Partitioned, i::Integer)
    xs = p.xs
    nchunks = p.nchunks
    chunksize = p.chunksize
    nextras = length(xs) - chunksize * nchunks
    nsmalls = nchunks - nextras
    # Produce small chunks first since they are the dependencies of latter chunks:
    if i <= nsmalls
        a = chunksize * (i - 1)
        b = a + chunksize - 1
    else
        a = chunksize * nsmalls + (chunksize + 1) * (i - 1 - nsmalls)
        b = a + (chunksize + 1) - 1
    end
    @view xs[begin+a:begin+b]
end

Base.iterate(p::Partitioned, i = 1) = i <= length(p) ? (p[i], i + 1) : nothing

function partitionto(xs, nchunks::Integer)
    @argcheck length(xs) >= nchunks > 0
    chunksize = length(xs) ÷ nchunks
    return Partitioned(xs, nchunks, chunksize)
end

function consecutive(xs)
    ys = Iterators.accumulate(xs; init = ()) do acc, x
        if acc isa Tuple{Any,Any}
            (acc[2], x)
        else
            (acc..., x)
        end
    end
    return Iterators.filter(x -> x isa Tuple{Any,Any}, ys)
end

donothing() = nothing

waitall(tasks) = waitall(donothing, tasks)
function waitall(onerror, tasks)
    err = sync_end!(onerror, tasks)
    err === nothing || throw(err)
    return
end

function sync_end!(onerror, tasks, err = nothing)
    called = false
    for t in tasks
        try
            wait(t)
        catch e
            called || onerror()
            called = true
            if err === nothing
                err = CompositeException()
            end
            push!(err, e)
        end
    end
    return err
end

function dac_spawn_foreach(f::F, xs; onerror = donothing) where {F}
    function dac(xs)
        if length(xs) == 1
            try
                f(xs[1])
            catch
                onerror()
                rethrow()
            end
        else
            l, r = halve(xs)
            t = Threads.@spawn dac(r)
            try
                dac(l)
            finally
                wait(t)
            end
        end
    end
    isempty(xs) || dac(xs)
    return
end

const spawn_foreach = dac_spawn_foreach
