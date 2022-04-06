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

"""
    presolve_write_from_file(problem_input::String, problem_postsolve::String, reduced_problem::String)

Given the file `problem_input` containing the original problem, presolve it,
store the presolved problem file in `reduced_problem` with the postsolve file written to `problem_postsolve`.
"""
function presolve_write_from_file(problem_input::String, problem_postsolve::String, reduced_problem::String)
    @assert isfile(problem_input)
    SCIP_PaPILO_jll.papilo() do exe
        run(`$exe presolve -f $problem_input -v $problem_postsolve -r $reduced_problem`)
    end
end

end
