type GenSettings
  name::String
  year::Array{Int64}
  co60eq::Array{String}
  target::String
end

# TODO try with context properties of composite types
global genSettings = GenSettings("A01", [2016, 2026], ["fma"], "")
function get_genSettings_name(name::String)
  genSettings.name = name
end
@qmlfunction get_genSettings_name
function get_genSettings_year( year::Array{Any})
  genSettings.year = map(x -> parse(Int64, x), year)
end
@qmlfunction get_genSettings_year
function get_genSettings_co60eq( co60eq::String, checked::Bool)# target::String)
  if checked
    push!(genSettings.co60eq, co60eq)
  else
    deleteat!(genSettings.co60eq, find( [genSettings.co60eq .== co60eq][1] )  )
  end
end
@qmlfunction get_genSettings_co60eq
function get_genSettings_target(target::String)
  genSettings.target = target
end
@qmlfunction get_genSettings_target


global fmx = [Array(String,0), Array(String,0), Array(String,0)]
function update_clearance_path(x::String, checked::Bool, id::String)
  if checked
    push!(fmx[ find( id .== ["fma","fmb","is"] )[1] ], x)
  else
    deleteat!(fmx[ find( id .== ["fma","fmb","is"] )[1] ],
        find( fmx[ find( id .== ["fma","fmb","is"] )[1] ] .== x) )
  end
end
@qmlfunction update_clearance_path
