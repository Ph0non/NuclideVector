using FactCheck

using QML
# using JLD
include("../src/core.jl")
# exposed as property
nv_list = SQLite.query(nvdb, "select NV from nv_summary") |> schema2arr |> nable2arr |> vec |> sort
# exposed as property
ot_list = ["measure"; "mean"; SQLite.query(nvdb, "select path from clearance_val") |> schema2arr |> nable2arr |> vec ]
# exposed as property
year1_ctx = "2016"
# exposed as property
year2_ctx = "2026"

# get data
include("../src/getdata.jl")
# decay
include("../src/decay.jl")
# calc nv
include("../src/calcnv.jl")
# get relevant nuclides and constraints
include("../src/constraints.jl")
# test NV
include("../src/testnv.jl")
# clearance
include("../src/clearance.jl")


facts("basics") do
  @fact Date(2000, 1, 1):Dates.Year(1):Date(2003, 1, 1) |> collect |> travec --> [Date(2000,1,1) Date(2001,1,1) Date(2002,1,1) Date(2003,1,1)]
  @fact [2000, 2001] |> arr2str --> "2000, 2001"
  @fact ["Co60", "Cs137"] |> arr2str --> "Co60, Cs137"
  @fact get_years() --> collect(2016:2026)
  @fact get_sample_info("date")[1] --> "20.02.1995"
  @fact get_sample_info("s_id")[1] --> 11
end

facts("variables") do
  @fact convert(Array{String,1}, SQLite.query(nvdb, "pragma table_info(halflife)")[:,2])[3] --> "Co60"
end

facts("types") do
    @fact SQLite.query(nvdb, "pragma table_info(halflife)") |> typeof --> DataFrame
    @fact SQLite.query(nvdb, "select Co60 from halflife") |> schema2arr |> typeof --> Array{Nullable{Float64},2}
    @fact [Nuclide("Co60", rand(10))] |> ListModel2NamedArray |> typeof --> NamedArrays.NamedArray{Float64,2,Array{Float64,2},Tuple{DataStructures.OrderedDict{String,Int64},DataStructures.OrderedDict{Int64,Int64}}}
end
