# PaPILO

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://scipopt.github.io/PaPILO.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://scipopt.github.io/PaPILO.jl/dev)
[![Build Status](https://github.com/scipopt/PaPILO.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/scipopt/PaPILO.jl/actions/workflows/CI.yml?query=branch%3Amain)

A file-based Julia wrapper for the [PaPILO](https://github.com/scipopt/papilo) library for presolving linear and mixed-integer linear optimization problems.

## Usage

```julia
using PaPILO

# 1) presolve problem from file

PaPILO.presolve_write_from_file(
    input_instance, # original MPS file
    postsolve_file, # file name where to write the postsolve information
    presolved_instance # file name where to write the presolved problem
)

# 2) solve problem from presolved_instance with an external solver
#    write solution to file reduced_sol

# 3) postsolve: compute the solution in the original problem space from
#    the solution in the reduced space

PaPILO.postsolve_from_file(
    postsolve_file, # postsolve file produced by the previous function
    reduced_sol, # .sol file of a solution that is feasible for the reduced problem
    original_sol, # file name where to write the solution to the original problem
)
```
