# Server Functions goes here.
# Don't forget to register neccessary functions with API.

# function df2dict(x::DataFrame)
#     return Dict(cn => x[row,cn] for cn in x.columns[1])
# end

function schema2vec(x)
    x |> schema2arr |> nable2arr |> vec
end

function __getNvList__()
    SQLite.query(nvdb, "select NV from nv_summary") |> schema2vec
end

function __getNuclidesList__(decayType::String)
	SQLite.query(nvdb, "select nuclide from nuclide_decayType where decayType = '" * decayType *"'") |> schema2vec
end

function __getPath__()
    SQLite.query(nvdb, "select path from clearance_val") |> schema2vec
end

function __getFmx__()
    ["FMA", "FMB", "IS"]
end

function __getTarget__()
    [SQLite.query(nvdb, "select path from clearance_val") |> schema2vec; "mean"; "measure"]
end

function getParameters()
    return Dict(
            "listNv" => __getNvList__(),
            "listNuclides" => Dict(
                "alpha" => __getNuclidesList__("alpha"),
                "beta" => __getNuclidesList__("beta"),
                "gamma" => __getNuclidesList__("gamma")
                ),
            "listPath" => __getPath__(),
            "listFmx" => __getFmx__(),
            "listTarget" => __getTarget__(),
            )
end


# function getNvList()
#     q = __getNvList__()
#     return Dict(i => q[i] for i=1:length(q))
# end
#
# function getNvListRaw()
#     __getNvList__()
# end
#
# function getNvListDict()
#     q = __getNvList__()
#     return [Dict("id" => i, "body" => q[i]) for i=1:length(q)]
# end
#
# function getArray()
#     return rand(2,2)
# end
