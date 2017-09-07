#######################################################
# load modules
using SQLite
using NamedArrays
using JuMP
using Cbc
using QML

#######################################################
# helper functions

nvdb = SQLite.DB("nvdb-v2.sqlite")
global nuclide_names = convert(Array{String}, SQLite.query(nvdb, "pragma table_info(halflife)")[:,2]);

function travec(x::Array{Date,1})
	reshape(x, 1, length(x))
end

function nable2arr(x)
	(el_i,el_j) = size(x)
	y = Array{ typeof(x[1,1].value) }(el_i, el_j)
	for j=1:el_j
		for i=1:el_i
			y[i, j] = x[i, j].value
		end
	end
	return y
end

function fill_wzero(x)
	(el_i,el_j) = size(x)
	y = Array{ Nullable{Float64} }(el_i, el_j)
	for j=1:el_j
		for i=1:el_i
			if isnull(x[i, j])
				y[i, j] = 0
			else
				y[i, j] = x[i, j].value
			end
		end
	end
	return y
end

function arr2str(nn::Array{String, 1})
	nn_str = nn[1]
	for i=2:length(nn)
		nn_str *= ", " * nn[i]
	end
	return nn_str
end

function arr2str(nn::Array{Int64, 1})
	nn_str = string(nn[1])
	for i=2:length(nn)
		nn_str *= ", " * string(nn[i])
	end
	return nn_str
end

function schema2arr(x::DataFrames.DataFrame)
	y = Array(x)
end

function schema2arr(x::NullableArrays.NullableArray)
	y = Array(x)
end

# read db table with first column as Named Array dimnames
function read_db(nvdb::SQLite.DB, tab::String)
	val = SQLite.query(nvdb, "select * from " * tab);
	val_data = schema2arr(val)[:,2:end]

	#nu_name = val.schema.header[2:end]
	nu_name = Data.schema(val[2:end]).header
	#path_names = val.data[1].values
	path_names = [val[1][i].value for i=1:size(val, 1) ]
	NamedArray(val_data, (path_names, nu_name), ("path", "nuclides"))
end

function get_years()
	collect(genSettings.year[1] : genSettings.year[2])  |> sort
end

reduce_factor(q) = q[:, convert(Array{String}, rel_nuclides)]

function del_zero_from_table()
	for i in nuclide_names
		SQLite.query(nvdb, "update `nv_data` set " * i *" = null where " * i * " = 0")
	end
end

function get_sample_info(x::String)
	nable2arr( schema2arr( SQLite.query(nvdb, "select " * x * " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" * genSettings.name *"'") ) )
end

# TODO make function more general
function ListModel2NamedArray(lm::Array)
  y = map(x -> parse(x), years)

  n = Array{String}(length(lm))
  arr = Array{Float64}(length(lm), length(y) )
  for i = 1:length(lm)
    arr[i,:] = lm[i].values'
    n[i] = lm[i].name
  end
  return NamedArray(arr, (n, y), ("nuclides", "years"))
end

# check for sanity
function sanity_check()
  arr = ListModel2NamedArray(nuclides)
  san_idx = find( round.( sum(arr,1).array .- 100, 2) )
  if isempty(san_idx)
    return true
  else
		# exposed as context property
		sanity_string = arr2str(names(arr)[2][san_idx])
		@qmlset qmlcontext().sanity_string = sanity_string

		try
    	@emit sanityFail()
		end
    return false
  end
end
@qmlfunction sanity_check

function update_year_ListModel()
	# create ListModel for ComboBox in Overestimation.qml
	if isdefined(:years)
		years_model = ListModel( map(x -> parse(x), years) )
	else
		global years = map(x -> string(x), get_years()[1:end-1])
		years_model = ListModel( years )
	end
	@qmlset qmlcontext().years_model = years_model
end
@qmlfunction update_year_ListModel

#######################################################
# decay correction

function decay_correction(nvdb::SQLite.DB, nuclide_names::Array{String, 1}, years::Array{Int64,1})
	hl_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names) * " from halflife");
	hl = NamedArray(schema2arr(hl_raw), ([1], nuclide_names), ("halftime", "nuclides"))
	## Workaround Typänderung SQLite
	hl = NamedArray(convert(Array{Float64, 2}, [hl.array[i].value for i = 1:length(hl) ]'), ([1], nuclide_names), ("halftime", "nuclides") )

	sample_date = map(x->Date(x, "dd.mm.yyyy"), get_sample_info("date") )
	sample_id = get_sample_info("s_id") |> vec

	global	samples_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names)	* " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" * genSettings.name *"'") |> fill_wzero |> nable2arr

	samples = NamedArray( samples_raw, (sample_id, nuclide_names), ("samples", "nuclides"))

	ref_date = "1 Jan"
	date_format = Dates.DateFormat("d u");
	(month_, day_) = Dates.monthday(Dates.DateTime(ref_date, date_format))

	tday_raw = travec([Date(years[1], month_, day_):Dates.Year(1):Date(years[end], month_, day_);]) .- sample_date; # calculate difference in days
	tday = NamedArray(map(x -> x.value, tday_raw), (NamedArrays.names(samples, 1), years),  ("samples", "years") )


	samples_korr = NamedArray(Array{Float64}(size(tday,1), size(samples,2), size(tday,2)),
					(NamedArrays.names(samples, 1), nuclide_names, years),
					("samples", "nuclides", "year") );
	for i in years
		samples_korr[:,:,i] =  samples.array .* 2.^(-tday[:,i].array ./ hl);
		# Am241 and Pu241 must be in sample nuclide_names
		samples_korr[:,"Am241",i] = Array(samples_korr[:,"Am241",i]) + Array(samples[:, "Pu241"]) .* hl[1,"Pu241"]./(hl[1,"Pu241"] - hl[1,"Am241"]) .*
											(2.^(-tday[:,i].array ./ hl[1,"Pu241"]) - 2.^(-tday[:,i].array ./ hl[1,"Am241"]))
	end

	return samples_korr
end

function decay_correction(nvdb::SQLite.DB, nuclide_names::Array{String, 1}, years::Int64)
	hl_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names) * " from halflife");
	hl = NamedArray(schema2arr(hl_raw), ([1], nuclide_names), ("halftime", "nuclides"))
	## Workaround Typänderung SQLite
	hl = NamedArray(convert(Array{Float64, 2}, [hl.array[i].value for i = 1:length(hl) ]'), ([1], nuclide_names), ("halftime", "nuclides") )

	sample_date = map(x->Date(x, "dd.mm.yyyy"), get_sample_info("date") )
	sample_id = get_sample_info("s_id") |> vec

	global	samples_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names)	* " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" * genSettings.name *"'") |> fill_wzero |> nable2arr

	samples = NamedArray( samples_raw, (sample_id, nuclide_names), ("samples", "nuclides"))

	ref_date = "1 Jan"
	date_format = Dates.DateFormat("d u");
	(month_, day_) = Dates.monthday(Dates.DateTime(ref_date, date_format))

	tday_raw = Date(years, month_, day_) .- sample_date # calculate difference in days
	tday = NamedArray(map(x -> x.value, tday_raw), (NamedArrays.names(samples, 1), [years]),  ("samples", "years") )


	samples_korr = NamedArray(samples.array .* 2.^(-vec(tday.array) ./ hl),
					(NamedArrays.names(samples, 1), nuclide_names),
					("samples", "nuclides") )
		# Am241 and Pu241 must be in sample nuclide_names
	samples_korr[:,"Am241"] = Array(samples_korr[:,"Am241"]) + Array(samples[:, "Pu241"]) .*
														hl[1,"Pu241"]./(hl[1,"Pu241"] - hl[1,"Am241"]) .*
														(2.^(-vec(tday.array) ./ hl[1,"Pu241"]) - 2.^(-vec(tday.array) ./ hl[1,"Am241"]))

	return samples_korr
end

#######################################################
# relevant nuclides and calculations

function nuclide_parts(samples_korr::NamedArrays.NamedArray{Float64,3,Array{Float64,3},
															Tuple{DataStructures.OrderedDict{Int64,Int64},
															DataStructures.OrderedDict{String,Int64},
															DataStructures.OrderedDict{Int64,Int64}}})
	samples_korr./sum(samples_korr,2)
end

function nuclide_parts(samples_korr::NamedArrays.NamedArray{Float64,2,Array{Float64,2},
															Tuple{DataStructures.OrderedDict{Int64,Int64},
															DataStructures.OrderedDict{String,Int64}}})
	samples_korr./sum(samples_korr,2)
end

function calc_factors(samples_part::NamedArrays.NamedArray{Float64,3,Array{Float64,3},
												Tuple{DataStructures.OrderedDict{Int64,Int64},
												DataStructures.OrderedDict{String,Int64},
												DataStructures.OrderedDict{Int64,Int64}}})
	clearance_val = read_db(nvdb, "clearance_val");

	ɛ = read_db(nvdb, "efficiency");
	f = NamedArray( 1./nable2arr(clearance_val), clearance_val.dicts, clearance_val.dimnames);

	A = NamedArray(Array{Float64}(size(samples_part,1), size(clearance_val,1), size(samples_part,3)),
					(names(samples_part)[1], names(clearance_val)[1], get_years()),
					("sample", "path", "years")); # path -> clearance path
	∑Co60Eq = NamedArray(Array{Float64}(size(samples_part,1), size(ɛ,1), size(samples_part,3)),
					(names(samples_part)[1], names(ɛ)[1], get_years()),
					("sample", "path", "years")); # path -> fma / fmb / is

	(fᵀ = f'; ɛᵀ = nable2arr(ɛ)');
	for i in get_years()
		A[:,:,i] = samples_part[:,:,i].array * fᵀ
		∑Co60Eq[:,:,i] = samples_part[:,:,i].array * ɛᵀ # sum of Co60-equiv. also contain non measureable nuclides
	end
	a = 1./A;

	return a, ∑Co60Eq, f, ɛ
end

function calc_factors(samples_part::NamedArrays.NamedArray{Float64,3,Array{Float64,3},
												Tuple{DataStructures.OrderedDict{Int64,Int64},
												DataStructures.OrderedDict{String,Int64},
												DataStructures.OrderedDict{Int64,Int64}}}, __years__::Array)

	clearance_val = read_db(nvdb, "clearance_val");

	ɛ = read_db(nvdb, "efficiency");
	f = NamedArray( 1./nable2arr(clearance_val), clearance_val.dicts, clearance_val.dimnames);

	A = NamedArray(Array{Float64}(size(samples_part,1), size(clearance_val,1), size(samples_part,3)),
					(names(samples_part)[1], names(clearance_val)[1], __years__),
					("sample", "path", "years")); # path -> clearance path
	∑Co60Eq = NamedArray(Array{Float64}(size(samples_part,1), size(ɛ,1), size(samples_part,3)),
					(names(samples_part)[1], names(ɛ)[1], __years__),
					("sample", "path", "years")); # path -> fma / fmb / is

	(fᵀ = f'; ɛᵀ = nable2arr(ɛ)');
	for i in __years__
		A[:,:,i] = samples_part[:,:,i].array * fᵀ
		∑Co60Eq[:,:,i] = samples_part[:,:,i].array * ɛᵀ # sum of Co60-equiv. also contain non measureable nuclides
	end
	a = 1./A;

	return a, ∑Co60Eq, f, ɛ
end

#######################################################
# solve problem

function get_nv()
	global rel_nuclides = [rel_nuclides3[i].name for i=1:length(rel_nuclides3) ]
	global mean_weight = [rel_nuclides3[i].weight for i=1:length(rel_nuclides3) ]
	global nvdb = SQLite.DB("nvdb-v2.sqlite");

	np = decay_correction(nvdb, nuclide_names, get_years() ) |> nuclide_parts
	a, ∑Co60Eq, f, ɛ = np |> calc_factors

	(nv = Array{Float64}(length(rel_nuclides), size(a,3)-1); i = 1);


	ymin = get_years()[1]
	ymax = get_years()[end-1]

	for l in get_years()[1:end-1]
			(nv[:, i] = solve_nv( l, a, ∑Co60Eq, reduce_factor(f), reduce_factor(ɛ), np[:,:,l:l+1], mean_weight ); i += 1);
		end
	write_result(nv)
end

function determine_list_∑Co60Eq()
	list_∑Co60Eq = Array{Int}(0)

	for i in ["fma", "fmb", "is"]
		if !isempty( find(i .== genSettings.co60eq) )
			ind = find(i .== ["fma", "fmb", "is"])[1]
			push!(list_∑Co60Eq, ind)
		end
	end

	return list_∑Co60Eq
end

function add_user_constraints_GUI(m::JuMP.Model, x::Array{JuMP.Variable,1})
	for i=1:length(rel_nuclides3)
		if rel_nuclides3[i].relation == "<="
			@constraint(m, x[i] <= rel_nuclides3[i].limit * 100)
		elseif rel_nuclides3[i].relation == ">="
			@constraint(m, x[i] >= rel_nuclides3[i].limit * 100)
		elseif rel_nuclides3[i].relation == "=="
			@constraint(m, x[i] == rel_nuclides3[i].limit * 100)
		end
	end
end


function solve_nv{ T1<:NamedArrays.NamedArray{Float64,3,Array{Float64,3},
									Tuple{DataStructures.OrderedDict{Int64,Int64},
									DataStructures.OrderedDict{String,Int64},
									DataStructures.OrderedDict{Int64,Int64}}},
				   T2<:NamedArrays.NamedArray{Float64,2,Array{Float64,2},
									Tuple{DataStructures.OrderedDict{String,Int64},
									DataStructures.OrderedDict{String,Int64}}},
				   T3<:NamedArrays.NamedArray{Nullable,2,Array{Nullable,2},
									Tuple{DataStructures.OrderedDict{String,Int64},
									DataStructures.OrderedDict{String,Int64}}} }(
				   l::Int, a::T1, ∑Co60Eq::T1, f_red::T2, ɛ_red::T3, np::T1, mean_weight::Vector{Float64} )
	ɛ_red = nable2arr(ɛ_red);
	m=Model(solver = CbcSolver());
	@variable(m, 0 ≤ x[1:length(rel_nuclides)] ≤ 10_000, Int);

	# set objectives
	if genSettings.target == "measure"
		co60_weight = rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== "Co60") ][1].weight
				@objective(m, :Min, - co60_weight * x[ find(rel_nuclides .== "Co60")][1]
								-x[ find(rel_nuclides .== "Cs137")][1] );
	elseif genSettings.target in keys(read_db(nvdb, "clearance_val").dicts[1])
		@objective(m, :Min, sum(x .* f_red[genSettings.target, :]) );
	elseif genSettings.target == "mean"
		np_red = mean( mean( np, 3)[:,:,1], 1)[:, rel_nuclides]
		obj_tmp = x - 10_000 * np_red.array'

		@variable(m, z[1:length(rel_nuclides)] )
		for i = 1:length(rel_nuclides)
			@constraint(m, z[i] >=  obj_tmp[i] )
			@constraint(m, z[i] >= -obj_tmp[i] )
		end
		@objective(m, :Min, sum(z .* mean_weight) )
	end
	@constraint(m, sum(x) == 10_000);

	# add user constraints
	add_user_constraints_GUI(m, x)

	# Co60-equiv for nv
	@expression(m, Co60eqnv[p=1:3], sum(ɛ_red[p,i] * x[i] for i = 1:length(rel_nuclides) if ɛ_red[p,i] != 0))

	# determine fma / fmb / is
	list_∑Co60Eq = determine_list_∑Co60Eq()

	for r in list_∑Co60Eq
		# lower bound
		@constraint(m, constr_lb[k in fmx[r], j in keys(a.dicts[1]), h=0:1], Co60eqnv[r] ≤ ∑Co60Eq[j,r,l+h] * a[j,k,l+h] * sum(f_red[k,i] * x[i] for i=1:length(rel_nuclides) ) )
	end

	sstatus = solve(m, suppress_warnings=true);

	if sstatus == :Infeasible
		return zeros(length(x))
	elseif sstatus == :Optimal
		return round.(getvalue(x)./100, 2)
	end

end

function write_result(nv::Array{Float64,2})
	NamedArray( nv, (rel_nuclides, get_years()[1:end-1]), ("nuclides", "years"))
	#writetable(nv_name * "/" * string(get_years()[l]) * "_" * clearance_paths * ".csv", nv, separator=';')
end
