using Test

@testset "SLInput" begin
    include("input.jl")
end

@testset "SLSelect" begin
    include("select.jl")
end

@testset "SLButton" begin
    include("button.jl")
end