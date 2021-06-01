function ThreadedScans.scan!(op, xs; basesize::Union{Nothing,Integer} = nothing)
    if basesize === nothing
        ntasks = Threads.nthreads()
    else
        ntasks = cld(length(xs), basesize)
    end
    return ThreadedScans.partitioned_hillis_steele!(op, xs; ntasks = ntasks)
end
