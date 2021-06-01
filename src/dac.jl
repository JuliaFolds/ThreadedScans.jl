function ThreadedScans.dac!(
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

    chunks = partitionto(xs, nchunks)
    promises = [OneWayPromise{eltype(xs)}() for _ in 1:nchunks]
    dac_spawn_foreach(1:nchunks) do i
        if i == 1
            put!(promises[1], scan!(op, chunks[1]))
        else
            local accr = foldl(op, chunks[i])
            local accl = take!(promises[i-1], spin)
            put!(promises[i], op(accl, accr))
            scan!(op, accl, chunks[i])
        end
    end

    return xs
end
