using Documenter
using ThreadedScans

makedocs(
    sitename = "ThreadedScans",
    format = Documenter.HTML(),
    modules = [ThreadedScans]
)

deploydocs(
    repo = "github.com/JuliaFolds/ThreadedScans.jl",
    push_preview = true,
)
