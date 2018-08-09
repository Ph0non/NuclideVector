type Constraint
  name::String
  relation::String
  limit::Float64
  weight::Float64
end

global rel_nuclides3 = Array{Constraint}(0)
global additional_constraints = Array{Constraint}(0)
sizehint!(rel_nuclides3, 6)
function get_rel_nuc(nuc_name::String, rel::String, limit::String, weight::String)
  isempty(limit) ? (limit = 0) : (limit = float(limit))
  isempty(weight) ? (weight = 1) : (weight = float(weight))
  if nuc_name in nuclide_names
      push!(rel_nuclides3, Constraint(nuc_name, rel, limit, weight ) )
  else
      # [4:end-5] -> remove <b>...</b>
      push!(additional_constraints, Constraint(nuc_name[4:end-4], rel, limit, weight ) )
  end
end
@qmlfunction get_rel_nuc

function rm_rel_nuc(x::String)
    if x in nuclide_names
        deleteat!(rel_nuclides3, find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== x))
    else
        # [4:end-5] -> remove <b>...</b>
        deleteat!(additional_constraints, find( [additional_constraints[i].name for i=1:length(additional_constraints)] .== x[4:end-4] ))
    end
end
@qmlfunction rm_rel_nuc

function get_relation(nuc_name::String, rel::String)
    if nuc_name in nuclide_names
        rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== nuc_name) ][1].relation = rel
    else
        # [4:end-5] -> remove <b>...</b>
        additional_constraints[ find( [additional_constraints[i].name for i=1:length(additional_constraints)] .== nuc_name[4:end-4] ) ][1].relation = rel
    end
end
@qmlfunction get_relation

function get_limit(nuc_name::String, limit::String)
  if !(tryparse(Float64, limit) |> isnull)
    parsed = parse(limit)
    if 0 <= parsed <= 100
        if nuc_name in nuclide_names
            rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== nuc_name) ][1].limit = parsed
        else
            # [4:end-5] -> remove <b>...</b>
            additional_constraints[ find( [additional_constraints[i].name for i=1:length(additional_constraints)] .== nuc_name[4:end-4] ) ][1].limit = parsed
        end
    else
      try
        @emit isNumberFail()
      end
    end
  else
    try
      @emit isNumberFail()
    end
  end
end
@qmlfunction get_limit

function get_weight(nuc_name::String, weight::String)
  if !(tryparse(Float64, weight) |> isnull)
    parsed = parse(weight)
    if parsed > 0
        if nuc_name in nuclide_names
            rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== nuc_name) ][1].weight = parsed
        else
            # [4:end-5] -> remove <b>...</b>
            additional_constraints[ find( [additional_constraints[i].name for i=1:length(additional_constraints)] .== nuc_name[4:end-5] ) ][1].weight = parsed
        end
    else
      try
        @emit isNumberFail()
      end
    end
  else
    try
      @emit isNumberFail()
    end
  end
end
@qmlfunction get_weight
