function ThreadedScans.simple!(
    op,
    xs;
    ntasks::Integer = Threads.nthreads(),
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

    chunks = partitionto(xs, ntasks + 1)
    accs = similar(xs, ntasks)
    spawn_foreach(1:ntasks) do i
        if i == 1
            accs[i] = scan!(op, chunks[i])
        else
            accs[i] = foldl(op, chunks[i])
        end
    end
    scan!(op, accs)
    spawn_foreach(1:ntasks) do i
        scan!(op, accs[i], chunks[i+1])
    end

    return xs
end
