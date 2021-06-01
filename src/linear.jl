function ThreadedScans.linear!(
    op,
    xs;
    ntasks::Integer = Threads.nthreads() + 1,
    spin::Union{Nothing,Integer} = nothing,
)
    ntasks = min(length(xs), ntasks)
    if ntasks <= 1
        scan!(op, xs)
        return xs
    end

    it = partitionto(xs, ntasks)
    chunk0, state = iterate(it)
    y = iterate(it, state)
    if y === nothing
        scan!(op, xs)
        return xs
    end

    tasks = Task[]
    fromleft = OneWayPromise{eltype(xs)}()
    @assert !isempty(chunk0)
    t = Threads.@spawn try
        put!($fromleft, scan!(op, $chunk0))
    catch
        close($fromleft)
        rethrow()
    end
    push!(tasks, t)
    chunk, state = y
    while true
        y = iterate(it, state)
        y === nothing && break
        @assert !isempty(chunk)
        toright = OneWayPromise{eltype(xs)}()
        t = Threads.@spawn try
            local accr = foldl(op, $chunk)
            local accl = take!($fromleft, spin)
            put!($toright, op(accl, accr))
            scan!(op, accl, $chunk)
        catch
            close($fromleft)
            close($toright)
            rethrow()
        end
        push!(tasks, t)
        fromleft = toright
        chunk, state = y
    end
    try
        scan!(op, take!(fromleft, spin), chunk)
    finally
        close(fromleft)
        foreach(wait, tasks)
    end
    return xs
end
