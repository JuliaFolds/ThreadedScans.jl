module ThreadedScansTests

using Test

include("utils.jl")

function include_tests(m = @__MODULE__, dir = @__DIR__)
    for file in readdir(dir)
        if match(r"^test_.*\.jl$", file) !== nothing
            Base.include(m, joinpath(dir, file))
        end
    end
end

include_tests()

function collect_modules(root::Module)
    modules = Module[]
    for n in names(root, all = true)
        m = getproperty(root, n)
        m isa Module || continue
        m === root && continue
        startswith(string(nameof(m)), "Test") || continue
        push!(modules, m)
    end
    return modules
end

collect_modules() = collect_modules(@__MODULE__)

function runtests(modules = collect_modules())
    @testset "$(nameof(m))" for m in modules
        tests = map(names(m, all = true)) do n
            n == :test || startswith(string(n), "test_") || return nothing
            f = getproperty(m, n)
            f !== m || return nothing
            parentmodule(f) === m || return nothing
            applicable(f) || return nothing  # removed by Revise?
            return f
        end
        filter!(!isnothing, tests)
        @testset "$f" for f in tests
            @debug "Testing $m.$f"
            f()
        end
    end
end

end  # module ThreadedScansTests
