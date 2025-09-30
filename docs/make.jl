using Documenter
using ShoelaceWidgets

makedocs(;
    modules=[ShoelaceWidgets],
    authors="Brad Carman <bradleygcarman@outlook.com>",
    sitename="ShoelaceWidgets.jl",
    format=Documenter.HTML(;
        canonical="https://bradcarman.github.io/ShoelaceWidgets.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "API Reference" => "api.md",
    ],
)

#=
using LiveServer
serve(dir="docs/build")
=#

deploydocs(;
    repo="github.com/bradcarman/ShoelaceWidgets.jl.git"
)

