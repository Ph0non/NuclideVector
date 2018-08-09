#######################################################
# load modules
using SQLite
using NamedArrays
using JuMP
using Cbc
using QML

#######################################################
# helper functions

global nvdb = SQLite.DB("nvdb-v2.sqlite")
global nuclide_names = convert(Array{String}, SQLite.query(nvdb, "pragma table_info(halflife)")[:,2]);

function travec(x::Array{Date,1})
	reshape(x, 1, length(x))
end

function nable2arr(y)
	return map(x -> x.value, y)
	# (el_i,el_j) = size(x)
	# y = Array{ typeof(x[1,1].value) }(el_i, el_j)
	# for j=1:el_j
	# 	for i=1:el_i
	# 		y[i, j] = x[i, j].value
	# 	end
	# end
	# return y
end

function fill_wzero(x)
	(el_i,el_j) = size(x)
	y = Array{ Nullable{Float64} }(el_i, el_j)
	for j=1:el_j
		for i=1:el_i
			if Missings.ismissing(x[i, j])
				y[i, j] = 0
			else
				y[i, j] = x[i, j]
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

function arr2str(nn::Array{Float64, 1})
	nn_str = string(nn[1])
	for i=2:length(nn)
		nn_str *= ", " * string(nn[i])
	end
	return nn_str
end

function schema2arr(x::DataFrames.DataFrame)
	y = Array(x)
end

function schema2arr(x)
	y = Array(x)
end

# read db table with first column as Named Array dimnames
function read_db(nvdb::SQLite.DB, tab::String)
	val = SQLite.query(nvdb, "select * from " * tab);
	val_data = schema2arr(val)[:,2:end]

	#nu_name = val.schema.header[2:end]
	nu_name = Data.schema(val[2:end]).header
	#path_names = val.data[1].values
	path_names = [val[1][i] for i=1:size(val, 1) ]
	NamedArray(val_data, (path_names, nu_name), ("path", "nuclides"))
end

function get_nuclide_types(t::String)
	 map(y -> String(y), SQLite.query(nvdb,  "select nuclide from nuclide_decayType where decayType = '" * t * "'" ) |> schema2arr )
end

function find_index_nuclide_types(t::String)
	find( [rel_nuclides[i] in get_nuclide_types(t) for i=1:length(rel_nuclides) ] )
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
	# nable2arr( schema2arr( SQLite.query(nvdb, "select " * x * " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" * genSettings.name *"'") ) )
	if genSettings.name == "ALLE"
		schema2arr( SQLite.query(nvdb, "select " * x * " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = 'A01' or NV = 'A02' or NV = 'C02' or NV = 'A04' or NV = 'A05' or NV = 'A06' or NV = 'A07' or NV = 'A08' or NV = 'B01' or NV = 'C01' or NV = 'D01' or NV = 'A10' or NV = 'NV2' or NV = 'NV3' or NV = 'NV4' or NV = 'NVA'") )
	else
		schema2arr( SQLite.query(nvdb, "select " * x * " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" * genSettings.name *"'") )
	end
end

function get_sample_info(x::String, nv_name::String)
	# nable2arr( schema2arr( SQLite.query(nvdb, "select " * x * " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" * genSettings.name *"'") ) )
	schema2arr( SQLite.query(nvdb, "select " * x * " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" * nv_name *"'") )
end

# TODO make function more general
function ListModel2NamedArray(lm::Array)
	if typeof(years) != Array{Int64,1}
  		y = map(x -> parse(x), years)
	end

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

function Z01_id(nvdb::SQLite.DB)
	SQLite.query(nvdb, "select nv_id from nv_summary where NV='Z01'")[1][1]
end

########################################################
# all hail Z01

# add NV to database for Z01
function Z01_add()
	# find position
	Z01_nvid = Z01_id(nvdb)
	# get NV from GUI
	nv = ListModel2NamedArray(nuclides)
	# get years from calculation
	y_z01 = nv.dicts[2].keys
	# add rowwise data
	for i in y_z01
		SQLite.query(nvdb, "insert into nv_data (nv_id, s_id, source, date, " * arr2str(nv.dicts[1].keys) * ") values ('" * string(Z01_nvid) * "', '" * genSettings.name * "', '" * genSettings.name * "', '01.01."* string(i) * "', " * arr2str(map(x -> "'" * string(x) * "'", nv[:,i].array)) * ")")
	end
end
@qmlfunction Z01_add

# gather NV from DB to specific year
function Z01_get(nvdb::SQLite.DB, year::Int64)

	samples_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names)	* " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = 'Z01' and date = '01.01." * string(year) * "' ") |> fill_wzero

	sample_id = get_sample_info("s_id", "Z01") |> vec
	samples = NamedArray( get.(samples_raw), (sample_id, nuclide_names), ("samples", "nuclides"))
end

function Z01_get(nvdb::SQLite.DB, y::Array{Int64,1})
# y = get_years()[1:end-1]
	s = [Z01_get(nvdb::SQLite.DB, i) for i in y ]
	samples = NamedArray( Array{Float64}( size(s[1],1), size(s[1],2), length(y)),
	 				(s[1].dicts[1].keys, nuclide_names, y ),
					("samples", "nuclides", "year") )
	for (index, i) in enumerate(y)
		samples[:,:,i] = s[index].array
	end
	return samples
end

#######################################################
# decay correction

function decay_correction(nvdb::SQLite.DB, nuclide_names::Array{String, 1}, years::Array{Int64,1})
	hl_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names) * " from halflife");
	hl = NamedArray(schema2arr(hl_raw), ([1], nuclide_names), ("halftime", "nuclides"))

	sample_date = map(x->Date(x, "dd.mm.yyyy"), get_sample_info("date") )
	if genSettings.name == "ALLE"
		sample_id = get_sample_info("NV||'-'||s_id") |> vec
		global	samples_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names) * " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = 'A01' or NV = 'A02' or NV = 'C02' or NV = 'A04' or NV = 'A05' or NV = 'A06' or NV = 'A07' or NV = 'A08' or NV = 'B01' or NV = 'C01' or NV = 'D01' or NV = 'A10' or NV = 'NV2' or NV = 'NV3' or NV = 'NV4' or NV = 'NVA'") |> fill_wzero
	else
		sample_id = get_sample_info("s_id") |> vec
		global	samples_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names)	* " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" * genSettings.name *"'") |> fill_wzero #|> nable2arr
	end

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
		samples_korr[:,:,i] =  get.(samples.array) .* 2.^(-tday[:,i].array ./ hl);
		# Am241 and Pu241 must be in sample nuclide_names
		samples_korr[:,"Am241",i] = Array(samples_korr[:,"Am241",i]) + get.(samples[:, "Pu241"]).array .* hl[1,"Pu241"]./(hl[1,"Pu241"] - hl[1,"Am241"]) .*	(2.^(-tday[:,i].array ./ hl[1,"Pu241"]) - 2.^(-tday[:,i].array ./ hl[1,"Am241"]))
	end

	return samples_korr
end

function decay_correction(nvdb::SQLite.DB, nuclide_names::Array{String, 1}, years::Int64)
	hl_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names) * " from halflife");
	hl = NamedArray(schema2arr(hl_raw), ([1], nuclide_names), ("halftime", "nuclides"))

	sample_date = map(x->Date(x, "dd.mm.yyyy"), get_sample_info("date") )
	if genSettings.name == "ALLE"
		sample_id = get_sample_info("NV||'-'||s_id") |> vec
		global	samples_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names) * " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = 'A01' or NV = 'A02' or NV = 'C02' or NV = 'A04' or NV = 'A05' or NV = 'A06' or NV = 'A07' or NV = 'A08' or NV = 'B01' or NV = 'C01' or NV = 'D01' or NV = 'A10' or NV = 'NV2' or NV = 'NV3' or NV = 'NV4' or NV = 'NVA'") |> fill_wzero
	else
		sample_id = get_sample_info("s_id") |> vec
		global	samples_raw = SQLite.query(nvdb, "select " * arr2str(nuclide_names)	* " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" * genSettings.name *"'") |> fill_wzero #|> nable2arr
	end

	samples = NamedArray( samples_raw, (sample_id, nuclide_names), ("samples", "nuclides"))

	ref_date = "1 Jan"
	date_format = Dates.DateFormat("d u");
	(month_, day_) = Dates.monthday(Dates.DateTime(ref_date, date_format))

	tday_raw = Date(years, month_, day_) .- sample_date # calculate difference in days
	tday = NamedArray(map(x -> x.value, tday_raw), (NamedArrays.names(samples, 1), [years]),  ("samples", "years") )


	samples_korr = NamedArray(get.(samples.array) .* 2.^(-vec(tday.array) ./ hl),
					(NamedArrays.names(samples, 1), nuclide_names),
					("samples", "nuclides") )
		# Am241 and Pu241 must be in sample nuclide_names
	samples_korr[:,"Am241"] = Array(samples_korr[:,"Am241"]) + get.(samples[:, "Pu241"]).array .*
														hl[1,"Pu241"]./(hl[1,"Pu241"] - hl[1,"Am241"]) .*
														(2.^(-vec(tday.array) ./ hl[1,"Pu241"]) - 2.^(-vec(tday.array) ./ hl[1,"Am241"]))

	return samples_korr
end



#######################################################
# relevant nuclides and calculations

function nuclide_parts(samples_korr::NamedArrays.NamedArray)
	samples_korr./sum(samples_korr,2)
end

function calc_factors(samples_part::NamedArrays.NamedArray)
	clearance_val = read_db(nvdb, "clearance_val");

	ɛ = read_db(nvdb, "efficiency");
	f = NamedArray( 1./clearance_val, clearance_val.dicts, clearance_val.dimnames);

	A = NamedArray(Array{Float64}(size(samples_part,1), size(clearance_val,1), size(samples_part,3)),
					(names(samples_part)[1], names(clearance_val)[1], samples_part.dicts[3].keys),
					("sample", "path", "years")); # path -> clearance path
	∑Co60Eq = NamedArray(Array{Float64}(size(samples_part,1), size(ɛ,1), size(samples_part,3)),
					(names(samples_part)[1], names(ɛ)[1], samples_part.dicts[3].keys),
					("sample", "path", "years")); # path -> fma / mc / is / como

	(fᵀ = f'; ɛᵀ = ɛ');
	for i in samples_part.dicts[3].keys
		A[:,:,i] = samples_part[:,:,i].array * fᵀ
		∑Co60Eq[:,:,i] = samples_part[:,:,i].array * ɛᵀ # sum of Co60-equiv. also contain non measureable nuclides
	end
	a = 1./A;

	return a, ∑Co60Eq, f, ɛ
end

function calc_factors(samples_part::NamedArrays.NamedArray,	__years__::Array)

	clearance_val = read_db(nvdb, "clearance_val");

	ɛ = read_db(nvdb, "efficiency");
	f = NamedArray( 1./clearance_val, clearance_val.dicts, clearance_val.dimnames);

	A = NamedArray(Array{Float64}(size(samples_part,1), size(clearance_val,1), size(samples_part,3)),
					(names(samples_part)[1], names(clearance_val)[1], __years__),
					("sample", "path", "years")); # path -> clearance path
	∑Co60Eq = NamedArray(Array{Float64}(size(samples_part,1), size(ɛ,1), size(samples_part,3)),
					(names(samples_part)[1], names(ɛ)[1], __years__),
					("sample", "path", "years")); # path -> fma / fmb / is

	(fᵀ = f'; ɛᵀ = ɛ');
	# (fᵀ = f'; ɛᵀ = nable2arr(ɛ)');
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

	isZ01 = genSettings.name == "Z01"

	if isZ01
		np = Z01_get(nvdb, get_years()[1:end-1]) |> nuclide_parts
	else
		np = decay_correction(nvdb, nuclide_names, get_years() ) |> nuclide_parts
	end
	a, ∑Co60Eq, f, ɛ = np |> calc_factors

	ymin = get_years()[1]
	ymax = get_years()[end-1]

	if isZ01
		(nv = Array{Float64}(length(rel_nuclides), size(a,3)); i = 1);
		for l in get_years()[1:end-1]
			print(l)
				(nv[:, i] = solve_nv( l, a, ∑Co60Eq, reduce_factor(f), reduce_factor(ɛ), np[:,:,l], mean_weight, isZ01 ); i += 1);
		end
	else
		(nv = Array{Float64}(length(rel_nuclides), size(a,3)-1); i = 1);
		for l in get_years()[1:end-1]
			(nv[:, i] = solve_nv( l, a, ∑Co60Eq, reduce_factor(f), reduce_factor(ɛ), np[:,:,l:l+1], mean_weight, isZ01 ); i += 1);
		end
	end
	write_result(nv)
end

function determine_list_∑Co60Eq()
	list_∑Co60Eq = Array{Int}(0)

	for i in ["fma", "mc", "como", "lb124", "is"]
		if !isempty( find(i .== genSettings.co60eq) )
			ind = find(i .== ["fma", "mc", "como", "lb124", "is"])[1]
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

function add_additional_constraints(m::JuMP.Model, x::Array{JuMP.Variable,1})
	d = Dict([ ("∑γ", "gamma"), ("∑β+ec", "beta"), ("∑α", "alpha")  ])

	for (index, i) in enumerate( [additional_constraints[j].name for j=1:length(additional_constraints) ] )
		if additional_constraints[index].relation == "<="
			@constraint(m, sum( x[ find_index_nuclide_types( d[i] ) ] ) <= additional_constraints[index].limit * 100)
		elseif additional_constraints[index].relation == ">="
			@constraint(m, sum( x[ find_index_nuclide_types( d[i] ) ] ) >= additional_constraints[index].limit * 100)
		elseif additional_constraints[index].relation == "=="
			@constraint(m, sum( x[ find_index_nuclide_types( d[i] ) ] ) == additional_constraints[index].limit * 100)
		end
	end
end

function solve_nv(l::Int, a, ∑Co60Eq, f_red, ɛ_red, np, mean_weight::Vector{Float64}, isZ01::Bool )
	m=Model(solver = CbcSolver());
	@variable(m, 0 ≤ x[1:length(rel_nuclides)] ≤ 10_000, Int);

	# determine fma / fmb / is / como
	list_∑Co60Eq = determine_list_∑Co60Eq()

	# set objectives
	if genSettings.target == "Messung FMA"
		# co60_weight = rel_nuclides3[ find( [rel_nuclides3[i].name for i=1:length(rel_nuclides3)] .== "Co60") ][1].weight
		# 		@objective(m, :Min, - co60_weight * x[ find(rel_nuclides .== "Co60")][1]
		# 						-x[ find(rel_nuclides .== "Cs137")][1] );
		@objective(m, :Min, -sum( ε_red["fma",:].array .* x ))
	elseif genSettings.target == "Messung MicroCont"
		@objective(m, :Min, -sum( ε_red["mc",:].array .* x ))
	elseif genSettings.target == "Messung CoMo"
		@objective(m, :Min, -sum( ε_red["como",:].array .* x ))
	elseif genSettings.target == "Messung LB124"
		@objective(m, :Min, -sum( ε_red["lb124",:].array .* x ))
	elseif genSettings.target == "Messung in-situ"
		@objective(m, :Min, -sum( ε_red["is",:].array .* x ))
	elseif genSettings.target in keys(read_db(nvdb, "clearance_val").dicts[1])
		@objective(m, :Min, -sum(x .* f_red[genSettings.target, :]) );
	elseif genSettings.target == "Mittelwert"
		if isZ01
			np_red = mean(np, 1)[:, rel_nuclides]
		else
			np_red = mean( mean( np, 3)[:,:,1], 1)[:, rel_nuclides]
		end
		obj_tmp = x - 10_000 * np_red.array'

		@variable(m, z[1:length(rel_nuclides)] )
		for i = 1:length(rel_nuclides)
			@constraint(m, z[i] >=  obj_tmp[i] )
			@constraint(m, z[i] >= -obj_tmp[i] )
		end
		@objective(m, :Min, sum(z .* mean_weight) )
	elseif genSettings.target == "min Overestimation"
#		ratio1_obj = Array{Any}(length(list_∑Co60Eq),1)
#		ratio2_obj = Array{Any}(length(list_∑Co60Eq),1)
#		for (index, i) in enumerate(list_∑Co60Eq)
#			ratio1_obj[index] = NamedArray(Array{Any}(size(a, 1), length(fmx[i])),
#				( map(x->string(x),names(a)[1]), fmx[i]),
#				("name", "path"))
#			ratio2_obj[index] = NamedArray(Array{Any}(size(a, 1), length(fmx[i])),
#				( map(x->string(x),names(a)[1]), fmx[i]),
#				("name", "path"))
#		end

		f_nv = f_red * x
		ɛ_nv = NamedArray( convert(Array{Float64}, ε_red.array), (ε_red.dicts[1].keys, ε_red.dicts[2].keys), ε_red.dimnames ) * x
		obj_sum = 0
		for (fmx_enum, fmx_ind) in enumerate(list_∑Co60Eq)
			for (index, j) in enumerate(names(a)[1])
				i = 1
				for k in fmx[fmx_ind]
					#ratio1_obj[index, i] = ∑Co60Eq[index,fmx_ind,l] * a[index,k,l] * f_nv[k] ./ ɛ_nv[fmx_ind]
					#ratio2_obj[index, i] = ∑Co60Eq[index,fmx_ind,l+1] * a[index,k,l+1] * f_nv[k] ./ ɛ_nv[fmx_ind]

					println("k=" , k)
					println("i=" , i)
					println("j=" , j)
					println("index=" , index)
					println("fmx_ind=" , fmx_ind)
					println("fmx_enum=" , fmx_enum)

				#	ratio1_obj[fmx_enum][index, i] = ∑Co60Eq[index,fmx_ind,l] * a[index,k,l] * f_nv[k]
				#	ratio2_obj[fmx_enum][index, i] = ∑Co60Eq[index,fmx_ind,l+1] * a[index,k,l+1] * f_nv[k]

					obj_sum += ∑Co60Eq[index,fmx_ind,l] * a[index,k,l] * f_nv[k] + ∑Co60Eq[index,fmx_ind,l+1] * a[index,k,l+1] * f_nv[k]
					i += 1
				end
			end
		end
		@objective(m, :Min, sum(obj_sum))
	end
	@constraint(m, sum(x) == 10_000);

	# add user constraints
	add_user_constraints_GUI(m, x)
	add_additional_constraints(m, x)

	# Co60-equiv for nv
	@expression(m, Co60eqnv[p=1:length(ε_red.dicts[1].keys)], sum(ɛ_red[p,i] * x[i] for i = 1:length(rel_nuclides) if ɛ_red[p,i] != 0))

	if isZ01
		for r in list_∑Co60Eq
			# lower bound
			@constraint(m, constr_lb[k in fmx[r], j = 1:size(a,1)], Co60eqnv[r] ≤ ∑Co60Eq[j,r,l] * a[j,k,l] * sum(f_red[k,i] * x[i] for i=1:length(rel_nuclides) ) )
		end
	else
		for r in list_∑Co60Eq
			# lower bound
			@constraint(m, constr_lb[k in fmx[r], j = 1:size(a,1), h=0:1], Co60eqnv[r] ≤ ∑Co60Eq[j,r,l+h] * a[j,k,l+h] * sum(f_red[k,i] * x[i] for i=1:length(rel_nuclides) ) )
		end
	end
		#@constraint(m, constr_lb[k in fmx[r], j in keys(a.dicts[1]), h=0:1], Co60eqnv[r] ≤ ∑Co60Eq[j,r,l+h] * a[j,k,l+h] * sum(f_red[k,i] * x[i] for i=1:length(rel_nuclides) ) )

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
