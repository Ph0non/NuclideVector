using FactCheck

cd("../src")

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

years = ["2016", "2017", "2018"]
nuclides = [Nuclide("Co60", [50, 33, 66]), Nuclide("Cs137", [50, 67, 34])]

facts("basics") do
  @fact Date(2000, 1, 1):Dates.Year(1):Date(2003, 1, 1) |> collect |> travec --> [Date(2000,1,1) Date(2001,1,1) Date(2002,1,1) Date(2003,1,1)]
  @fact [2000, 2001] |> arr2str --> "2000, 2001"
  @fact ["Co60", "Cs137"] |> arr2str --> "Co60, Cs137"
  @fact get_years() --> collect(2016:2026)
  @fact get_sample_info("date")[1] --> "20.02.1995"
  @fact get_sample_info("s_id")[1] --> 11
  @fact sanity_check() --> true
end

facts("calculations") do
  @fact decay_correction(nvdb, ["Co60", "Pu241", "Am241"], 2016)[11,:].array --> [1606.5139600660889, 17.169121631227156, 14.606756459799302]
  @fact decay_correction(nvdb, ["Co60", "Pu241", "Am241"], [2016, 2017])[11,:,2017] --> [1408.0831273190711, 16.360099584555364, 14.610215241778892]

  @fact nuclide_parts(decay_correction(nvdb, nuclide_names, [2016, 2017] ) )[11,  ["Co60", "Pu241", "Am241"], 2016].array --> roughly([0.65704,0.00702191,0.00597394], atol=1E-6)
  @fact nuclide_parts(decay_correction(nvdb, nuclide_names, 2017 ) )[11,  ["Co60", "Pu241", "Am241"]].array --> roughly([0.630349,0.00732384,0.00654047], atol=1E-6)
end

facts("variables") do
  @fact convert(Array{String,1}, SQLite.query(nvdb, "pragma table_info(halflife)")[:,2])[3] --> "Co60"
  @fact convert(Array{String,1}, SQLite.query(nvdb, "pragma table_info(halflife)")[:,2]) --> ["Mn54","Co57","Co60","Zn65","Nb94","Ru106","Ag108m","Ag110m","Sb125","Cs134","Cs137","Ba133","Ce144","Eu152","Eu154","Eu155","Fe55","Ni63","Sr90","U234","U238","U235","Pu239Pu240","Pu238","Pu241","Am241","Cm242","Cm244","Ni59","H3","U233"]
end

facts("types") do
    @fact SQLite.query(nvdb, "pragma table_info(halflife)") |> typeof --> DataFrame
    @fact SQLite.query(nvdb, "select Co60 from halflife") |> schema2arr |> typeof --> Array{Nullable{Float64},2}
    @fact [Nuclide("Co60", rand(length(years)))] |> ListModel2NamedArray |> typeof --> NamedArrays.NamedArray{Float64,2,Array{Float64,2},Tuple{DataStructures.OrderedDict{String,Int64},DataStructures.OrderedDict{Int64,Int64}}}
end
