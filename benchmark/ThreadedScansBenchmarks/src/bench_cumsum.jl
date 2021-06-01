module BenchCumsum

using BenchmarkTools
using ThreadedScans

const CACHE = Ref{Any}()

function setup(n = 2^23)
    CACHE[] = rand(-2^5:2^5, n)
    T = typeof(CACHE[])

    suite = BenchmarkGroup()
    suite["base"] = @benchmarkable(cumsum!(ys, xs), setup = begin
        xs = CACHE[]::$T
        ys = similar(xs)
    end)
    suite["simple!"] = @benchmarkable(ThreadedScans.simple!(+, xs), setup = begin
        xs = copy(CACHE[]::$T)
    end)
    suite["dac!"] = @benchmarkable(ThreadedScans.dac!(+, xs), setup = begin
        xs = copy(CACHE[]::$T)
    end)
    suite["linear!"] = @benchmarkable(ThreadedScans.linear!(+, xs), setup = begin
        xs = copy(CACHE[]::$T)
    end)
    suite["partitioned_hillis_steele!"] = @benchmarkable(
        ThreadedScans.partitioned_hillis_steele!(+, xs),
        setup = begin
            xs = copy(CACHE[]::$T)
        end
    )

    return suite
end

function clear()
    CACHE[] = nothing
end

end  # module
