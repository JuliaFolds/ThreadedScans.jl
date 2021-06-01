function scan!(op, xs)
    acc = xs[begin]
    for i in firstindex(xs)+1:lastindex(xs)
        acc = op(acc, @inbounds xs[i])
        @inbounds xs[i] = acc
    end
    return acc
end

function scan!(op, acc, xs)
    for i in eachindex(xs)
        acc = op(acc, @inbounds xs[i])
        @inbounds xs[i] = acc
    end
    return acc
end
