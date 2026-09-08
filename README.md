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

## Dual postsolve

Dual solutions and reduced costs can also be brought back to the original problem space.
This requires presolving in a dual-aware mode, which restricts PaPILO to the presolvers
that support dual postsolve, and is only available for problems without integer variables.

```julia
using PaPILO

# 1) presolve, asking PaPILO to also store dual postsolve information

PaPILO.presolve_write_from_file(
    input_instance,
    postsolve_file,
    presolved_instance;
    dual_postsolve = true,
)

# 2) solve the presolved problem with an external LP solver, writing the primal
#    solution, the dual solution and the reduced costs of the reduced problem
#    (see "Solution files" below to write them from Julia)

# 3) postsolve: recover the original-space primal solution, dual solution and
#    reduced costs

PaPILO.postsolve_from_file(
    postsolve_file,
    reduced_sol,
    original_sol;
    dual_reduced_solution = reduced_dual, # dual solution of the reduced problem
    costs_reduced_solution = reduced_costs, # reduced costs of the reduced problem
    dualsolution = original_dual, # where to write the original dual solution
    reducedcosts = original_costs, # where to write the original reduced costs
)
```

The keyword arguments are named after the PaPILO command line flags they map to
(`--dual-reduced-solution`, `--costs-reduced-solution`, `--dualsolution`,
`--reducedcosts`). PaPILO recovers duals and reduced costs together, so
`dual_reduced_solution` and `costs_reduced_solution` must both be given. Conversely, an archive written with
`dual_postsolve = true` must be postsolved with them; the default archive is primal-only
and unchanged.

## Solution files

The solution files exchanged with PaPILO can be read and written from Julia. `read_sol`
returns a `Dict` mapping each name to its value, and `write_sol` writes such a mapping back
in the format PaPILO expects:

```julia
using PaPILO

# read a solution written by PaPILO, or by a solver such as SCIP
solution = PaPILO.read_sol(original_sol)
solution["X1"]

# read the dual solution and the reduced costs, keyed by constraint and variable name
duals = PaPILO.read_sol(original_dual)
costs = PaPILO.read_sol(original_costs)

# write the solution of the reduced problem, to hand it back to `postsolve_from_file`
PaPILO.write_sol(reduced_sol, Dict("X1" => 3.6, "X2" => 0.8))
```

PaPILO omits entries whose value is zero, so a name absent from the returned dictionary
stands for a zero. `read_sol` skips header lines, so it accepts both the files PaPILO
writes and the ones SCIP writes.
