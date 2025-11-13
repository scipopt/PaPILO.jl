
"""
    presolve_write_from_file(problem_input::String, problem_postsolve::String, reduced_problem::String)

Given the file `problem_input` containing the original problem, presolve it,
store the presolved problem file in `reduced_problem` with the postsolve information written to `problem_postsolve` to then pass to the `postsolve_from_file` function
"""
function presolve_write_from_file(problem_input::String, problem_postsolve::String, reduced_problem::String)
    @assert isfile(problem_input)
    SCIP_PaPILO_jll.papilo() do exe
        run(`$exe presolve -f $problem_input -v $problem_postsolve -r $reduced_problem`)
    end
end

"""
    postsolve_from_file(problem_postsolve, reduced_sol, original_sol)

Arguments:
- `problem_postsolve`: postsolve file produced by the presolve command
- `reduced_sol`: solution file to the reduced problem (produced by an external solver)
- `original_sol`: file name where to write the solution to the original problem 
"""
function postsolve_from_file(problem_postsolve, reduced_sol, original_sol)
    @assert isfile(problem_postsolve)
    @assert isfile(reduced_sol)
    SCIP_PaPILO_jll.papilo() do exe
        run(`$exe postsolve -v $problem_postsolve -u $reduced_sol -l $original_sol`)
    end
end
