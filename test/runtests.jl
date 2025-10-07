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

@testset "SLRadio" begin
    include("radio.jl")
end

@testset "SLDialog" begin
    include("dialog.jl")
end

@testset "SLTree" begin
    include("tree.jl")
end

@testset "SLCheckbox" begin
    include("checkbox.jl")
end
