
"""
    copy_presolve_model(dest::MOI.ModelLike, original_model::MOI.ModelLike)

Presolves the `original_model` with PaPILO and copies the reduced model into `dest`.
Returns a function `map_reduced_solution_to_original(reduced_solution) -> original_solution`
that maps back solutions in the reduced space to the original space.
Solutions must be complete (one value for each variable).
"""
function copy_presolve_model(dest::MOI.ModelLike, original_model::MOI.ModelLike)
    if !MOI.is_empty(dest)
        error("Destination should be empty")
    end
    original_file = tempname() * ".mps"
    MOI.write_to_file(original_model, original_file)
    reduced_file = tempname() * ".mps"
    postsolve_file = tempname() * ".post"
    presolve_write_from_file(original_file, postsolve_file, reduced_file)
    MOI.read_from_file(dest, reduced_file)
    function map_reduced_solution_to_original(reduced_solution::Dict)
        reduced_solfile = tempname() * ".sol"
        original_solfile = tempname() * ".sol"
        open(reduced_solfile, "w") do f
            for (vidx, value) in reduced_solution
                v_name = MOI.get(dest, MOI.VariableName(), vidx)
                println(f, "$v_name            $value")
            end
        end
        postsolve_from_file(postsolve_file, reduced_solfile, original_solfile)
        solution_dict = Dict{MOI.VariableIndex, Float64}()
        # starting with zero values for all variables
        for v_idx in MOI.get(original_model, MOI.ListOfVariableIndices())
            solution_dict[v_idx] = 0
        end
        solution_lines = open(original_file, "w") do f
             readlines(f)
        end
        for line in solution_lines
            split_line = split(line)
            # ignore line without two blocks
            if length(split_line) < 2
                continue
            end
            # if first element is not a valid variable name, ignore
            v_idx = get(original_model, MOI.VariableIndex, split_line[1])
            if v_idx === nothing
                continue
            end
            value = tryparse(Float64, split_line[2])
            if value === nothing
                error("Parsing error from solver: $(split_line[2]) is not a numerical value")
            end
            solution_dict[v_idx] = value
        end
        return solution_dict
    end
    return map_reduced_solution_to_original
end
