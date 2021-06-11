# ThreadedScans: parallel scan implementations

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliafolds.github.io/ThreadedScans.jl/dev)

ThreadedScans.jl provides threading-based parallel scan implementations for
Julia.  The main high-level API is `ThreadedScans.scan!(op, xs)`.
