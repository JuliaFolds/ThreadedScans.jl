module Utils

using ThreadedScans

struct WithKwargs
    f::Any
    overrides::NamedTuple
end

(f::WithKwargs)(args...; kwargs...) = f.f(args...; kwargs..., f.overrides...)
with_kwargs(f; overrides...) = WithKwargs(f, (; overrides...))
with_kwargs(f::WithKwargs; overrides...) = WithKwargs(f.f, (; f.overrides..., overrides...))

unwrap_function(f) = f
unwrap_function(f::WithKwargs) = unwrap_function(f.f)

function Base.show(io::IO, f::WithKwargs)
    print(io, parentmodule(f.f), '.')
    print(io, nameof(f.f), "(...;")
    isfirst = true
    for (k, v) in pairs(f.overrides)
        if isfirst
            isfirst = false
        else
            print(io, ',')
        end
        print(io, ' ', k, " = ", v)
    end
    print(io, ')')
end

const SCAN_FUNCTIONS = Any[
    ThreadedScans.simple!,
    ThreadedScans.dac!,
    ThreadedScans.linear!,
    ThreadedScans.partitioned_hillis_steele!,
    # ...
]

function scan_functions_with_kwargs()
    fns = copy(SCAN_FUNCTIONS)
    push!(
        fns,
        with_kwargs(ThreadedScans.simple!; ntasks = 7),
        with_kwargs(ThreadedScans.dac!; ntasks = 7),
        with_kwargs(ThreadedScans.dac!; ntasks = 8),
        with_kwargs(ThreadedScans.linear!; ntasks = 7),
        with_kwargs(ThreadedScans.linear!; ntasks = 8),
        with_kwargs(ThreadedScans.partitioned_hillis_steele!; ntasks = 7),
        with_kwargs(ThreadedScans.partitioned_hillis_steele!; ntasks = 8),
    )
    for f in copy(fns)
        unwrap_function(f) === ThreadedScans.simple! && continue
        push!(fns, with_kwargs(f, spin = 100))
    end
    return fns
end

end  # module
