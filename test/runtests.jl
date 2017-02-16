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
rel_nuclides3 = [Constraint("Co60", "NONE", 0, 0)
                 Constraint("Cs137", ">=", 5, 0)
                 Constraint("Ni63", "==", 10, 0)
                 Constraint("Am241", "NONE", 0, 100)]
push!(genSettings.co60eq, "is")
genSettings.target = "mean"

facts("basics") do
  @fact Date(2000, 1, 1):Dates.Year(1):Date(2003, 1, 1) |> collect |> travec --> [Date(2000,1,1) Date(2001,1,1) Date(2002,1,1) Date(2003,1,1)]
  @fact [2000, 2001] |> arr2str --> "2000, 2001"
  @fact ["Co60", "Cs137"] |> arr2str --> "Co60, Cs137"
  @fact get_years() --> collect(2016:2026)
  @fact get_sample_info("date")[1] --> "20.02.1995"
  @fact get_sample_info("s_id")[1] --> 11

  nuclides = [Nuclide("Co60", [50, 33, 66]), Nuclide("Cs137", [50, 67, 34])]
  @fact sanity_check() --> true
end

facts("calculations") do
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

  @fact get_nv()[:,2016].array --> [84.81,5.0,10.0,0.19]
  @fact start_nv_calc() --> nothing
  @fact nv_NamedArray[:,2017].array --> [84.8,5.0,10.0,0.2]

  @fact clearance_gui() --> nothing
  @fact clearance_year[:,2016].array --> roughly([1.08921,0.116018,0.104312,0.0342838,0.462032,6.74491,2.31321,7.80891,2.25921,3.46818,0.665258], atol=1E-5)
end

facts("variables") do
  @fact convert(Array{String,1}, SQLite.query(nvdb, "pragma table_info(halflife)")[:,2])[3] --> "Co60"
  @fact convert(Array{String,1}, SQLite.query(nvdb, "pragma table_info(halflife)")[:,2]) --> ["Mn54","Co57","Co60","Zn65","Nb94","Ru106","Ag108m","Ag110m","Sb125","Cs134","Cs137","Ba133","Ce144","Eu152","Eu154","Eu155","Fe55","Ni63","Sr90","U234","U238","U235","Pu239Pu240","Pu238","Pu241","Am241","Cm242","Cm244","Ni59","H3","U233"]
  @fact nable2arr(read_db(nvdb, "efficiency")[:,["Mn54", "Co60"]].array)[:,1] --> roughly([0.4585,2.30769,1.0], atol=1E-5)
end

facts("types") do
    @fact SQLite.query(nvdb, "pragma table_info(halflife)") |> typeof --> DataFrame
    @fact SQLite.query(nvdb, "select Co60 from halflife") |> schema2arr |> typeof --> Array{Nullable{Float64},2}
    @fact [Nuclide("Co60", rand(length(years)))] |> ListModel2NamedArray |> typeof --> NamedArrays.NamedArray{Float64,2,Array{Float64,2},Tuple{DataStructures.OrderedDict{String,Int64},DataStructures.OrderedDict{Int64,Int64}}}
end

facts("copy2clipboard") do
  @fact copy2clipboard_nv() --> "\t2016\t2017\t2018\t2019\t2020\t2021\t2022\t2023\t2024\t2025\t\nCo60\t84,81\t84,8\t84,79\t84,78\t84,77\t84,76\t84,76\t84,75\t84,74\t84,73\t\nCs137\t5,0\t5,0\t5,0\t5,0\t5,0\t5,0\t5,0\t5,0\t5,0\t5,0\t\nNi63\t10,0\t10,0\t10,0\t10,0\t10,0\t10,0\t10,0\t10,0\t10,0\t10,0\t\nAm241\t0,19\t0,2\t0,21\t0,22\t0,23\t0,24\t0,24\t0,25\t0,26\t0,27\t\n"

  @fact copy2clipboard_clearance() --> "\t2016\t2017\t2018\t2019\t2020\t2021\t2022\t2023\t2024\t2025\t\nOF / Bq/cm²\t1,0892059688487092\t1,0881392818280742\t1,0870746820306556\t1,0860121633362294\t1,084951719648476\t1,0838933448948622\t1,0838933448948622\t1,0828370330265296\t1,0817827780181741\t1,0807305738679347\t\n1a / Bq/g\t0,11601825353855673\t0,11600479486485442\t0,11599133931333126\t0,11597788688290102\t0,11596443757247778\t0,11595099138097632\t0,11595099138097632\t0,11593754830731179\t0,11592410835039994\t0,11591067150915695\t\n2a / Bq/g\t0,10431154381084841\t0,10430187279807157\t0,10429220357838138\t0,1042825361512792\t0,10427287051626657\t0,10426320667284522\t0,10426320667284522\t0,10425354462051711\t0,10424388435878429\t0,10423422588714908\t\n3a / Bq/g\t0,034283755213987764\t0,034285714285714274\t0,034287673581347496\t0,03428963310092581\t0,03429159284448762\t0,034293552812071325\t0,034293552812071325\t0,03429551300371535\t0,034297473419458095\t0,03429943405933802\t\n4a / Bq/cm²\t0,46203248088340604\t0,4618724308346035\t0,46171249163146105\t0,46155266315886645\t0,46139294530186636\t0,46123333794566673\t0,46123333794566673\t0,46107384097563225\t0,46091445427728617\t0,4607551777363098\t\n1b / Bq/g\t6,7449075947659525\t6,741118576275757\t6,7373338124326265\t6,733553296074338\t6,729777020054736\t6,726004977243683\t6,726004977243683\t6,7222371605270235\t6,7184735628065315\t6,714714176999866\t\n2b / Bq/g\t2,313208420078649\t2,3129409043598934\t2,3126734505087883\t2,3124060585038735\t2,3121387283236996\t2,311871459946827\t2,311871459946827\t2,311604253351826\t2,311337108517278\t2,31107002542177\t\n3b / Bq/g\t7,808912199937901\t7,803688915231501\t7,7984726134352815\t7,793263280555622\t7,788060902636259\t7,782865465758171\t7,782865465758171\t7,777676956039459\t7,7724953596352115\t7,767320662737389\t\n4b / Bq/g\t2,2592062655320433\t2,2589510937088213\t2,2586959795211565\t2,258440922949524\t2,2581859239744078\t2,257930982576299\t2,257930982576299\t2,2576760987357014\t2,2574212724331244\t2,2571665036490858\t\n5b / Bq/cm²\t3,4681780215778475\t3,4681780215778475\t3,4681780215778475\t3,4681780215778475\t3,4681780215778475\t3,4681780215778475\t3,4681780215778475\t3,4681780215778475\t3,468178021577848\t3,4681780215778475\t\n6b_2c / Bq/g\t0,6652577984845426\t0,6651840453389445\t0,665110308544672\t0,6650365880962884\t0,6649628839883586\t0,6648891962154506\t0,6648891962154506\t0,6648155247721343\t0,6647418696529825\t0,6646682308525699\t\n"
end
