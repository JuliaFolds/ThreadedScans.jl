using Documenter
using ThreadedScans

makedocs(
    sitename = "ThreadedScans",
    format = Documenter.HTML(),
    modules = [ThreadedScans]
)

deploydocs(
    repo = "https://github.com/JuliaFolds/ThreadedScans.jl"
)
