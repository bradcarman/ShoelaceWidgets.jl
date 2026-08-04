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

# NOTE: SLTree needs more work to be done properly, will remove for now
# @testset "SLTree" begin
#     include("tree.jl")
# end

@testset "SLCheckbox" begin
    include("checkbox.jl")
end

@testset "SLAlert" begin
    include("alert.jl")
end

@testset "ListManager" begin
    include("list_manager.jl")
end

@testset "DialogManager" begin
    include("dialog_manager.jl")
end