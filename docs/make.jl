using PaPILO
using Documenter

DocMeta.setdocmeta!(PaPILO, :DocTestSetup, :(using PaPILO); recursive=true)

makedocs(;
    modules=[PaPILO],
    authors="Mathieu Besançon <mathieu.besancon@gmail.com> and contributors",
    repo="https://github.com/matbesancon/PaPILO.jl/blob/{commit}{path}#{line}",
    sitename="PaPILO.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://matbesancon.github.io/PaPILO.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/matbesancon/PaPILO.jl",
    devbranch="main",
)
