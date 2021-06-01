module TestUtils

using Test
using ThreadedScans.Internal: partitionto

function test_partitionto()
    @testset for len in 1:100, nchunks in 1:len
        chunks = collect(partitionto(1:len, nchunks))
        @test length(chunks) == nchunks
        @test reduce(vcat, chunks) == 1:len
    end
end

end  # module
