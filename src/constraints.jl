type Constraint
  name::String
  relation::String
  limit::Float64
  weight::Float64
end

global rel_nuclides3 = Array(Constraint, 0)
sizehint!(rel_nuclides3, 6)
function get_rel_nuc(nuc_name::String, rel::String, limit::String, weight::String)
  isempty(limit) ? (limit = 0) : (limit = float(limit))
  isempty(weight) ? (weight = 1) : (weight = float(weight))
  push!(rel_nuclides3, Constraint(nuc_name, rel, limit, weight ) )
end
@qmlfunction get_rel_nuc

function rm_rel_nuc(x::String)
  deleteat!(rel_nuclides3, find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== x))
end
@qmlfunction rm_rel_nuc

function get_relation(nuc_name::String, rel::String)
  rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== nuc_name) ][1].relation = rel
end
@qmlfunction get_relation

function get_limit(nuc_name::String, limit::String)
  if !(tryparse(Float64, limit) |> isnull)
    parsed = parse(limit)
    if 0 <= parsed <= 100
      rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== nuc_name) ][1].limit = parsed
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
      rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== nuc_name) ][1].weight = parsed
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
