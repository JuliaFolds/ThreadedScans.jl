module TestWithBase

using ..Utils: scan_functions_with_kwargs
using Test

function test_with_base(scan!, op, xs)
    @test scan!(op, copy(xs)) == accumulate(op, xs)
end

function test_with_base(scan!)
    @testset "length(xs) = $n" for n in [2^8, 2^8 + 1]
        xs = rand(1:2^10, n)
        @testset "$op" for op in [+, &, xor]
            test_with_base(scan!, op, xs)
        end
    end
end

function test_with_base()
    @testset "$scan!" for scan! in scan_functions_with_kwargs()
        test_with_base(scan!)
    end
end

end  # module
