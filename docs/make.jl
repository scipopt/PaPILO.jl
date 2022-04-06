using PaPILO
using Documenter

DocMeta.setdocmeta!(PaPILO, :DocTestSetup, :(using PaPILO); recursive=true)

makedocs(;
    modules=[PaPILO],
    authors="Alexander Hoen, Mathieu Besançon, and contributors",
    repo="https://github.com/scipopt/PaPILO.jl/blob/{commit}{path}#{line}",
    sitename="PaPILO.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://scipopt.github.io/PaPILO.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/scipopt/PaPILO.jl",
    devbranch="main",
)
