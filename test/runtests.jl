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
rel_nuclides3 = [Constraint("Co60", "NONE", 0, 1)
                 Constraint("Cs137", ">=", 5, 1)
                 Constraint("Ni63", "==", 10, 1)
                 Constraint("Am241", "<=", 20.0, 100)]
push!(genSettings.co60eq, "is")
genSettings.target = "mean"

facts("basics") do
  @fact Date(2000, 1, 1):Dates.Year(1):Date(2003, 1, 1) |> collect |> travec --> [Date(2000,1,1) Date(2001,1,1) Date(2002,1,1) Date(2003,1,1)]
  @fact [2000, 2001] |> arr2str --> "2000, 2001"
  @fact ["Co60", "Cs137"] |> arr2str --> "Co60, Cs137"
  @fact get_years() --> collect(2016:2026)
  @fact get_sample_info("date")[1] --> "20.02.1995"
  @fact get_sample_info("s_id")[1] --> 11

  global nuclides = [Nuclide("Co60", [50, 33, 66]), Nuclide("Cs137", [50, 67, 34])]
  @fact sanity_check() --> true
  global nuclides = [Nuclide("Co60", [50, 34, 65]), Nuclide("Cs137", [50, 67, 34])]
  @fact  sanity_check() --> false
end

facts("check clearance paths") do
  temp_paths = ["OF", "1a", "2a", "3a", "4a", "1b", "2b", "3b", "4b", "5b", "6b_2c"]
  for i in temp_paths
    update_clearance_path(i, true, "fma")
  end
  @fact fmx[1] --> ["OF", "1a", "2a", "3a", "4a", "1b", "2b", "3b", "4b", "5b", "6b_2c"]
  update_clearance_path("3a", false, "fma")
  @fact fmx[1] --> ["OF", "1a", "2a", "4a", "1b", "2b", "3b", "4b", "5b", "6b_2c"]
  temp_paths = ["OF", "4a", "5b", "6b_2c"]
  for i in temp_paths
    update_clearance_path(i, true, "is")
  end
  @fact fmx[3] --> ["OF", "4a", "5b", "6b_2c"]
end

facts("calculations (with optimization target 'mean')") do
  @fact decay_correction(nvdb, ["Co60", "Pu241", "Am241"], 2016)[11,:].array --> [1606.5139600660889, 17.169121631227156, 14.606756459799302]
  @fact decay_correction(nvdb, ["Co60", "Pu241", "Am241"], [2016, 2017])[11,:,2017] --> [1408.0831273190711, 16.360099584555364, 14.610215241778892]

  @fact nuclide_parts(decay_correction(nvdb, nuclide_names, [2016, 2017] ) )[11,  ["Co60", "Pu241", "Am241"], 2016].array --> roughly([0.65704,0.00702191,0.00597394], atol=1E-6)
  @fact nuclide_parts(decay_correction(nvdb, nuclide_names, 2017 ) )[11,  ["Co60", "Pu241", "Am241"]].array --> roughly([0.630349,0.00732384,0.00654047], atol=1E-6)

  @fact calc_factors(nuclide_parts(decay_correction(nvdb, nuclide_names, get_years() ) ) )[1][1] --> 1.191405847123472
  @fact calc_factors(nuclide_parts(decay_correction(nvdb, nuclide_names, get_years() ) ) )[2][1] --> 0.6683477256399165
  @fact calc_factors(nuclide_parts(decay_correction(nvdb, nuclide_names, get_years() ) ) )[3][2,1] --> 2.5
  @fact calc_factors(nuclide_parts(decay_correction(nvdb, nuclide_names, get_years() ) ) )[4][1].value --> 0.4585

  @fact calc_factors(nuclide_parts(decay_correction(nvdb, nuclide_names, [2016] ) ), [2016] )[1][1] --> 1.191405847123472
  @fact calc_factors(nuclide_parts(decay_correction(nvdb, nuclide_names, [2016] ) ), [2016] )[2][1] --> 0.6683477256399165
  @fact calc_factors(nuclide_parts(decay_correction(nvdb, nuclide_names, [2016] ) ), [2016] )[3][2,1] --> 2.5
  @fact calc_factors(nuclide_parts(decay_correction(nvdb, nuclide_names, [2016] ) ), [2016] )[4][1].value --> 0.4585

  @fact get_nv()[:,2016].array --> [49.21,22.63,10.0,18.16]
  @fact start_nv_calc() --> nothing
  @fact nv_NamedArray[:,2017].array --> [47.91,23.17,10.0,18.92]

  @fact clearance_gui() --> nothing
  @fact clearance_year[:,2016].array --> roughly([0.394415,0.111038,0.103457,0.0430385,0.316506,3.49337,2.1928,3.64257,1.98768,4.04532,0.554731], atol=1E-5)
end

facts("variables") do
  @fact convert(Array{String,1}, SQLite.query(nvdb, "pragma table_info(halflife)")[:,2])[3] --> "Co60"
  @fact convert(Array{String,1}, SQLite.query(nvdb, "pragma table_info(halflife)")[:,2]) --> ["Mn54","Co57","Co60","Zn65","Nb94","Ru106","Ag108m","Ag110m","Sb125","Cs134","Cs137","Ba133","Ce144","Eu152","Eu154","Eu155","Fe55","Ni63","Sr90","U234","U238","U235","Pu239Pu240","Pu238","Pu241","Am241","Cm242","Cm244","Ni59","H3","U233"]
  @fact nable2arr(read_db(nvdb, "efficiency")[:,["Mn54", "Co60"]].array)[:,1] --> roughly([0.4585,2.30769,1.0], atol=1E-5)

  @fact get_genSettings_name("A02") --> "A02"
  @fact get_genSettings_target("mean") --> "mean"
  @fact get_genSettings_co60eq("fma", false) --> ["is"]
  @fact get_genSettings_co60eq("fma", true) --> ["is", "fma"]
  @fact get_genSettings_year(["2000", "2010"]) --> nothing
end
genSettings.year = [2016, 2019]
genSettings.name = "A01"

facts("types") do
    @fact SQLite.query(nvdb, "pragma table_info(halflife)") |> typeof --> DataFrame
    @fact SQLite.query(nvdb, "select Co60 from halflife") |> schema2arr |> typeof --> Array{Nullable{Float64},2}
    @fact SQLite.query(nvdb, "select Co60 from halflife")[1] |> schema2arr |> typeof --> Array{Float64,1}
    @fact [Nuclide("Co60", rand(length(years)))] |> ListModel2NamedArray |> typeof --> NamedArrays.NamedArray{Float64,2,Array{Float64,2},Tuple{DataStructures.OrderedDict{String,Int64},DataStructures.OrderedDict{Int64,Int64}}}
end

facts("copy2clipboard") do
  @fact copy2clipboard_nv() --> "\t2016\t2017\t2018\t2019\t2020\t2021\t2022\t2023\t2024\t2025\t\nCo60\t49,21\t47,91\t46,71\t0,0\t0,0\t0,0\t0,0\t0,0\t0,0\t0,0\t\nCs137\t22,63\t23,17\t23,62\t0,0\t0,0\t0,0\t0,0\t0,0\t0,0\t0,0\t\nNi63\t10,0\t10,0\t10,0\t0,0\t0,0\t0,0\t0,0\t0,0\t0,0\t0,0\t\nAm241\t18,16\t18,92\t19,67\t0,0\t0,0\t0,0\t0,0\t0,0\t0,0\t0,0\t\n"

  @fact copy2clipboard_clearance() --> "\t2016\t2017\t2018\t2019\t2020\t2021\t2022\t2023\t2024\t2025\t\nOF / Bq/cm²\t0,3944150824327522\t0,38405407481373377\t0,3743495676262494\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n1a / Bq/g\t0,11103790834190792\t0,11063497097675928\t0,11015965806442138\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n2a / Bq/g\t0,10345689727017482\t0,10323202257340226\t0,10293537374118616\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n3a / Bq/g\t0,043038519474930065\t0,0434436318876258\t0,04382441019647944\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n4a / Bq/cm²\t0,3165057762304162\t0,3119443491281156\t0,3074132710309104\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n1b / Bq/g\t3,493368422278375\t3,421962153098587\t3,3536789858474747\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n2b / Bq/g\t2,192802127018063\t2,1843003412969284\t2,1745039412883935\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n3b / Bq/g\t3,6425670384108693\t3,56106937217499\t3,4837107491554073\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n4b / Bq/g\t1,9876764062810575\t1,9762845849802375\t1,9646365422396856\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n5b / Bq/cm²\t4,045321080505261\t4,066046142846978\t4,083479941606236\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n6b_2c / Bq/g\t0,5547306505326338\t0,5508599842454045\t0,5470928398312764\tInf\tInf\tInf\tInf\tInf\tInf\tInf\t\n"

# round errors on CI system, so only roundabout check for characters and no literal comparison
  @fact copy2clipboard_decay("2016", false) |> length --> greater_than(12600)

  global rel_nuclides3 = [Constraint("Co60", "NONE", 0, 1)]
  @fact copy2clipboard_decay("2016", true) |> length --> greater_than(800)
end

rel_nuclides3 = [Constraint("Co60", "NONE", 0, 100)
                 Constraint("Cs137", ">=", 5, 1)
                 Constraint("Ni63", "==", 10, 1)
                 Constraint("Am241", "NONE", 0, 1)]

facts("check NV test") do
  test_nv_gui("2016", Int32(0))
  @fact ratio1[11,:].array --> roughly([3.20493,1.65464,1.58198,2.29313,2.62537,1.60292,2.833,1.53379,1.3137,1.466], atol=1E-4)
  @fact ratio2[11,:].array --> roughly([3.11605,1.66144,1.58688,2.29877,2.59052,1.60218,2.78695,1.51405,1.31453,1.434], atol=1E-4)
  test_nv_gui("-1", Int32(0))
  @fact ratio1[1,:].array --> roughly([3.54587,1.50695,1.46578,2.02017,2.65911,1.49107,2.92208,1.68278,1.26246,1.75563], atol=1E-4)
  @fact ratio2[1,:].array --> roughly([3.45319,1.49744,1.45775,1.99627,2.6173,1.4776,2.86991,1.67206,1.25719,1.73787], atol=1E-4)

  @fact copy2clipboard_testnv("2016") |> length --> greater_than(13300)
end

genSettings.target = "measure"
facts("calculations (with optimization target 'measure')") do
   @fact get_nv()[:,2016].array --> [59.23,5.0,10.0,25.77]
end

genSettings.target = "2a"
facts("calculations (with optimization target '2a')") do
   @fact get_nv()[:,2016].array --> [0.01,51.95,10.0,38.04]
end

# make MILP :Infeasible
rel_nuclides3 = [Constraint("Co60", "==", 0, 0)
                 Constraint("Cs137", "<=", 5, 0)
                 Constraint("Ni63", "==", 10, 0)
                 Constraint("Am241", "==", 0.0, 100)]
facts("check infeasible problem") do
  @fact get_nv() .== 0 --> all
end

import Base.==
function ==(a::Constraint, b::Constraint)
  all([a.name == b.name,
  a.relation == b.relation,
  a.limit == b.limit,
  a.weight == b.weight])
end

rel_nuclides3 = Array(Constraint, 0)
facts("check constraints") do
  @fact get_rel_nuc("Co60", "NONE", "", "")[end] --> Constraint("Co60", "NONE", 0, 1)
  @fact get_rel_nuc("Cs137", "<=", "10.5", "100")[end] --> Constraint("Cs137", "<=", 10.5, 100)

  @fact rm_rel_nuc("Co60") --> [Constraint("Cs137", "<=", 10.5, 100)]
  @fact get_relation("Cs137", ">=") --> ">="
  @fact get_limit("Cs137", "-5") --> nothing
  @fact get_limit("Cs137", "Moo!") --> nothing
  @fact get_limit("Cs137", "5.25") --> 5.25
  @fact get_weight("Cs137", "Moo") --> nothing
  @fact get_weight("Cs137", "0") --> nothing
  @fact get_weight("Cs137", "1") --> 1
end


facts("check decay in GUI") do
 @fact decay_gui("2016", false)[3].values --> roughly([2.17126,19.2886,65.704,65.704,54.8536,8.7432,7.80501,16.2632,9.02581,10.0237,8.99121,16.0416,15.6949,14.3573,26.3572,11.985,17.4069,11.9369,13.26,32.206,17.3881,31.3681,16.3125,17.276,18.5308,16.2812,26.287,13.2258,10.3071,10.997,9.32392,7.80048,10.9485,33.2787,43.9202,24.248,24.7811,2.17126], atol=1E-3)

 @fact decay_gui("2016", true)[1].values --> roughly([0.0,8.75678,34.5242,0.405064,0.579306,0.192689,0.0745387,1.63187,12.699,1.28165,4.93129,6.83424,4.35439,7.05811,34.5242,6.95792,23.8322,0.443472,0.516782,0.0,0.915992,0.785621,0.14679,15.0089,11.0844,10.0883,28.438,30.0111,12.0304,15.8691,4.26695,18.6339,9.99118,8.07875,15.8334,0.0,18.7271,0.260975], atol=1E-3)
end

# workspace()
# using LastMain.FactCheck
# using LastMain.QML
# facts("check generation of global 'year'-variable if not defined")
#  update_year_ListModel()
# end


exitstatus()
