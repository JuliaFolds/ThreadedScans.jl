try
    using ThreadedScansTests
    true
catch
    false
end || begin
    let path = joinpath(@__DIR__, "ThreadedScansTests")
        path in LOAD_PATH || push!(LOAD_PATH, path)
    end
    using ThreadedScansTests
end
