baremodule ThreadedScans

function scan! end

function simple! end
function dac! end
function linear! end
function partitioned_hillis_steele! end

module Internal

using ArgCheck: ArgCheck, @argcheck, @check

using ..ThreadedScans: ThreadedScans

include("utils.jl")
include("promises.jl")
include("basecases.jl")
include("simple.jl")
include("dac.jl")
include("linear.jl")
include("hillis_steele.jl")
include("api.jl")

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end ThreadedScans 

end  # module Internal

end  # baremodule ThreadedScans
