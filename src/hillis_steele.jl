"""
    ThreadedScans.partitioned_hillis_steele!(op, xs::AbstractVector) -> xs

Compute inclusive scan.  Intermediate reductions for `ntasks` chunks are
computed in parallel and then merged using prefix sum algorithm by Hillis and
Steele.  It is marginally better than other methods especially when the number
of worker threads is large.

# Keyword arguments
* `ntasks = Threads.nthreads()`: number of tasks
"""
function ThreadedScans.partitioned_hillis_steele!(
    op,
    xs;
    ntasks::Integer = Threads.nthreads(),
    spin::Union{Nothing,Integer} = nothing,
)
    if length(xs) <= 2
        if length(xs) == 2
            xs[begin+1] = op(xs[begin], xs[begin+1])
        end
        return xs
    end
    if ntasks < 2
        scan!(op, xs)
        return xs
    end
    nchunks = min(length(xs), ntasks + 1)
    ntasks = nchunks - 1
    @assert ntasks > 1

    npromises = ntasks + foldl_hillis_steele!((_, x) -> x.stop, nothing, ntasks)::Int
    promises = OneWayPromise{eltype(xs)}[OneWayPromise{eltype(xs)}() for _ in 1:npromises]

    chunks = partitionto(xs, ntasks + 1)
    @assert length(chunks) == ntasks + 1
    onerror() = foreach(close, promises)
    spawn_foreach(1:ntasks; onerror = onerror) do i
        _partitioned_hillis_steele!(op, chunks, i, ntasks, promises, spin)
    end

    return xs
end

function foldl_hillis_steele!(rf, acc, ntasks::Integer)
    stop = 0
    nright = 1   # number of non-take!-ing tasks
    while nright < ntasks
        offset = stop
        stop = stop + ntasks - nright
        # `rf` manipulates `promises[offset+1:stop]`:
        acc = rf(acc, (pow2 = nright, offset = offset, stop = stop))
        nright *= 2
    end
    return acc
end

function _partitioned_hillis_steele!(op, chunks, i, ntasks, promises, spin)
    if i == 1
        accr = scan!(op, chunks[i])
    else
        accr = foldl(op, chunks[i])
    end
    put!(promises[i], accr)

    # Hillis-Steele prefix scan for the "left lane":
    il = if i == 1
        ntasks  # == length(chunks) - 1
    else
        i - 1
    end

    accl = foldl_hillis_steele!(take!(promises[il]), ntasks) do accl, x
        if il <= ntasks - x.pow2
            put!(promises[ntasks+x.offset+il], accl)
        end
        j = il - x.pow2
        if j > 0
            accl = op(accl, take!(promises[ntasks+x.offset+j], spin))
        end
        accl
    end

    scan!(op, accl, chunks[il+1])
    return
end
