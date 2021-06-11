"""
    ThreadedScans.scan!(op, xs::AbstractVector; [basesize]) -> xs

Compute inclusive scan of a vector `xs` with an associative binary function `op`
in parallel.
"""
function ThreadedScans.scan!(op, xs; basesize::Union{Nothing,Integer} = nothing)
    if basesize === nothing
        ntasks = Threads.nthreads()
    else
        ntasks = cld(length(xs), basesize)
    end
    return ThreadedScans.partitioned_hillis_steele!(op, xs; ntasks = ntasks)
end
