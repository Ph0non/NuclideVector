type Constraint
  name::String
  relation::String
  limit::Float64
  weight::Float64
end

global rel_nuclides3 = Array(Constraint, 0)
sizehint!(rel_nuclides3, 6)
function get_rel_nuc(nuc_name::String, rel::String, limit::String, weight::String)
  if isempty(limit) limit = 0
  else limit = float(limit)
  end
  if isempty(weight) weight = 1
  else weight = float(weight)
  end
  push!(rel_nuclides3, Constraint(nuc_name, rel, limit, weight ) )
  print(rel_nuclides3)
end
@qmlfunction get_rel_nuc

function rm_rel_nuc(x::String)
  deleteat!(rel_nuclides3, find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== x))
  # print(rel_nuclides3)
end
@qmlfunction rm_rel_nuc

function get_relation(nuc_name::String, rel::String)
  rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== nuc_name) ][1].relation = rel
  # print(rel_nuclides3)
end
@qmlfunction get_relation

function get_limit(nuc_name::String, limit::String)
  rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== nuc_name) ][1].limit = float(limit)
  # print(rel_nuclides3)
end
@qmlfunction get_limit

function get_weight(nuc_name::String, weight::String)
  rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== nuc_name) ][1].weight = float(weight)
  # print(rel_nuclides3)
end
@qmlfunction get_weight