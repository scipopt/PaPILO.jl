# Copyright 2022 Zuse Institute Berlin

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module PaPILO

import SCIP_PaPILO_jll

# Presolve parameters required for PaPILO to store dual postsolve information in the
# postsolve archive: dual reductions are only recorded when components detection and
# linear dependency detection are switched off and none of the presolvers substitution,
# sparsify, dualinfer and doubletoneq is enabled.
const DUAL_POSTSOLVE_SETTINGS = """
substitution.enabled = 0
sparsify.enabled = 0
dualinfer.enabled = 0
doubletoneq.enabled = 0
presolve.componentsmaxint = -1
presolve.detectlindep = 0
"""

"""
    read_sol(solution_file)

Read a solution file and return a `Dict` mapping each name to its value.

This reads the files written by [`postsolve_from_file`](@ref), for which the names are the
variables of the original problem for a primal solution or the reduced costs, and its
constraints for a dual solution. Values that are zero are omitted by PaPILO, so a name
absent from the returned dictionary stands for a zero.

Header lines are skipped, which makes the function accept both the format written by
PaPILO

```
=obj=                                              10
X1                                                 3.6                  obj(1)
```

and the one written by SCIP, whose solution files PaPILO also reads

```
objective value:                                   10
X1                                                 3.6   (obj:1)
```

See [`write_sol`](@ref) for the inverse operation.
"""
function read_sol(solution_file)
    values = Dict{String,Float64}()
    for line in eachline(solution_file)
        tokens = split(line)
        # an entry is a name followed by a number, anything else is a header. That rule
        # already skips the headers SCIP writes, because their second token is not a
        # number: `objective value:  10` splits into `objective`, `value:`, `10`, and
        # `solution status: optimal` into `solution`, `status:`, `optimal`. Only `=obj=`
        # needs to be named explicitly, since its second token is the objective value.
        if length(tokens) < 2 || tokens[1] == "=obj="
            continue
        end
        value = tryparse(Float64, tokens[2])
        if value !== nothing
            values[tokens[1]] = value
        end
    end
    return values
end

"""
    write_sol(solution_file, values)

Write `values`, a mapping from names to numbers such as the one returned by
[`read_sol`](@ref), to `solution_file` in the format PaPILO reads, one `name value` pair
per line sorted by name.

This is the format the `reduced_sol` argument of [`postsolve_from_file`](@ref) expects, and
the one SCIP writes, except that no objective value header is written since it cannot be
computed from `values` alone. PaPILO ignores that header when reading.
"""
function write_sol(solution_file, values)
    open(solution_file, "w") do file
        for name in sort!(collect(keys(values)))
            println(file, rpad(name, 50), " ", values[name])
        end
    end
end

"""
    presolve_write_from_file(problem_input::String, problem_postsolve::String, reduced_problem::String; dual_postsolve::Bool=false)

Given the file `problem_input` containing the original problem, presolve it,
store the presolved problem file in `reduced_problem` with the postsolve information written to `problem_postsolve` to then pass to the `postsolve_from_file` function

If `dual_postsolve` is `true`, presolving is restricted to the presolvers that support dual
postsolve (`DominatedColumns`, `DualFix`, `ParallelCols`, `ParallelRows`, `Propagation`,
`FixContinuous`, `ColSingleton` and `SingletonStuffing`) so that `problem_postsolve` also
stores the information needed to recover dual solutions and reduced costs with
[`postsolve_from_file`](@ref). The reduced problem is then usually larger than with the
default settings.

PaPILO only stores that information for problems without integer variables. If
`problem_input` has any, the archive silently stays primal-only and
[`postsolve_from_file`](@ref) throws when duals are requested from it.
"""
function presolve_write_from_file(problem_input::String, problem_postsolve::String, reduced_problem::String; dual_postsolve::Bool=false)
    @assert isfile(problem_input)
    args = String[]
    if dual_postsolve
        settings = tempname() * ".set"
        write(settings, DUAL_POSTSOLVE_SETTINGS)
        push!(args, "-p", settings)
    end
    SCIP_PaPILO_jll.papilo() do exe
        run(`$exe presolve -f $problem_input -v $problem_postsolve -r $reduced_problem $args`)
    end
end

"""
    postsolve_from_file(problem_postsolve, reduced_sol, original_sol; dual_reduced_solution=nothing, costs_reduced_solution=nothing, dualsolution=nothing, reducedcosts=nothing)

Arguments:
- `problem_postsolve`: postsolve file produced by the presolve command
- `reduced_sol`: solution file to the reduced problem (produced by an external solver)
- `original_sol`: file name where to write the solution to the original problem 

Keyword arguments, named identically to the corresponding command line flags. The two
`*_reduced_solution` files describe the reduced problem and are read, the other two
describe the original problem and are written:
- `dual_reduced_solution` (`--dual-reduced-solution`): dual solution of the reduced problem
- `costs_reduced_solution` (`--costs-reduced-solution`): reduced costs of the reduced problem
- `dualsolution` (`--dualsolution`): file name where to write the dual solution to the original problem
- `reducedcosts` (`--reducedcosts`): file name where to write the reduced costs of the original problem

All four use the same format as `reduced_sol` and `original_sol`: a line `=obj=` followed
by the objective value, then one line per entry with a name, its value and the objective
coefficient, as in

```
=obj=                                              10
C2                                                 0.5                  obj(8)
C4                                                 1.5                  obj(4)
```

Entries are named after the constraints for a dual solution and after the variables for
reduced costs, and entries equal to zero are omitted.

PaPILO recovers duals and reduced costs together, so `dual_reduced_solution` and
`costs_reduced_solution` must either both be given or both be omitted, and recovering either
requires `problem_postsolve` to have been written by [`presolve_write_from_file`](@ref)
with `dual_postsolve=true`. Such an archive in turn *must* be postsolved with the duals:
passing only a primal solution to it aborts PaPILO.
"""
function postsolve_from_file(problem_postsolve, reduced_sol, original_sol; dual_reduced_solution=nothing, costs_reduced_solution=nothing, dualsolution=nothing, reducedcosts=nothing)
    @assert isfile(problem_postsolve)
    @assert isfile(reduced_sol)
    if (dual_reduced_solution === nothing) != (costs_reduced_solution === nothing)
        throw(ArgumentError("PaPILO recovers the dual solution and the reduced costs together, `dual_reduced_solution` and `costs_reduced_solution` must either both be provided or both be omitted"))
    end
    if dualsolution !== nothing && dual_reduced_solution === nothing
        throw(ArgumentError("`dualsolution` was requested but the dual solution of the reduced problem `dual_reduced_solution` is missing"))
    end
    if reducedcosts !== nothing && costs_reduced_solution === nothing
        throw(ArgumentError("`reducedcosts` was requested but the reduced costs of the reduced problem `costs_reduced_solution` are missing"))
    end
    args = String[]
    for (flag, file) in (("--dual-reduced-solution", dual_reduced_solution), ("--costs-reduced-solution", costs_reduced_solution))
        if file !== nothing
            @assert isfile(file)
            push!(args, flag, string(file))
        end
    end
    for (flag, file) in (("--dualsolution", dualsolution), ("--reducedcosts", reducedcosts))
        if file !== nothing
            # otherwise a leftover file would be mistaken for a successful run below
            if isfile(file)
                throw(ArgumentError("$file already exists, remove it before asking PaPILO to write it"))
            end
            push!(args, flag, string(file))
        end
    end
    SCIP_PaPILO_jll.papilo() do exe
        run(`$exe postsolve -v $problem_postsolve -u $reduced_sol -l $original_sol $args`)
    end
    # PaPILO exits successfully but writes no dual file when the archive does not contain
    # dual information, so the files themselves are what tells us whether it worked
    for file in (dualsolution, reducedcosts)
        if file !== nothing && !isfile(file)
            error("PaPILO did not write $file because $problem_postsolve does not contain dual information, rerun `presolve_write_from_file` with `dual_postsolve=true`")
        end
    end
end

end
