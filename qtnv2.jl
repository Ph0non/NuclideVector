using QML
# using JLD

include("NuclideVector_v4.3_gui.jl")
# exposed as property
nv_list = SQLite.query(nvdb, "select NV from nv_summary") |> schema2arr |> nable2arr |> vec |> sort
# exposed as property
ot_list = ["measure"; "mean"; SQLite.query(nvdb, "select path from clearance_val") |> schema2arr |> nable2arr |> vec ]
# exposed as property
year1_ctx = "2016"
# exposed as property
year2_ctx = "2026"

# get data
include("nvqt2/getdata.jl")
# decay
include("nvqt2/decay.jl")
# calc nv
include("nvqt2/calcnv.jl")
# get relevant nuclides and constraints
include("nvqt2/constraints.jl")
# test NV
include("nvqt2/testnv.jl")
# clearance
include("nvqt2/clearance.jl")

# TODO look further in data save/load
# save Data
# function saveData()
#   jldopen("mydata.jld", "w") do file
#       write(file, "rel_nuclides3", rel_nuclides3)
#       write(file, "genSettings", genSettings)
#       write(file, "fmx", fmx)
#     end
# end
# @qmlfunction saveData
#
# # load Data
# function loadData()
#   global fmx = JLD.load("mydata.jld", "fmx")
#   global rel_nuclides3 = JLD.load("mydata.jld", "rel_nuclides3")
#   global genSettings = JLD.load("mydata.jld", "genSettings")
# end
# @qmlfunction loadData

@qmlapp "nvqt2/main.qml" start_cal_ctx_button years nuclidesModel nv_list ot_list year1_ctx year2_ctx sampleModel sampleModel_eoy fmx_row samples_row decayModel years_clearance clearanceModel

exec()
