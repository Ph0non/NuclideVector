#######################################################
# load modules
using SQLite: query, SQLiteDB
using NamedArrays
using JuMP
using Cbc
using YAML
using ProgressMeter

#######################################################
# helper functions

function arr2str(nn::Array{ASCIIString, 1})
	nn_str = nn[1]
	for i=2:length(nn)
		nn_str *= ", " * nn[i]
	end
	return nn_str
end

function schema2arr(x::DataStreams.Data.Table)
	y = Array(Any, x.schema.rows, x.schema.cols)
	for i=1:x.schema.cols
		y[:,i] = x.data[i].values
	end
	return y
end

# read db table with first column as Named Array dimnames
function read_db(nvdb::SQLite.DB, tab::ASCIIString)
	val = query(nvdb, "select * from " * tab);
	val_data = schema2arr(val)[:,2:end]
	nu_name = val.schema.header[2:end]
	path_names = val.data[1].values
	NamedArray(val_data, (path_names, nu_name), ("path", "nuclides"))
end

function get_years()
	if "years" in keys(settings)
		collect(settings["years"][1] : settings["years"][2])
	else
		[settings["year"], settings["year"] + 1]
	end
end

reduce_factor(q) = q[:, convert(Array{UTF8String, 1}, rel_nuclides)]

#######################################################
# decay correction

function decay_correction(nvdb::SQLite.DB, nuclide_names::Array{ASCIIString, 1}, years::Array{Int64,1})
	hl_raw = query(nvdb, "select " * arr2str(nuclide_names) * " from halflife");
	hl = NamedArray(schema2arr(hl_raw), ([1], nuclide_names), ("halftime", "nuclides"))
	
	samples_raw = query(nvdb, "select date, s_id, " * arr2str(nuclide_names) 
						* " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" 
						* settings["nv_name"] *"'");
	sample_view = map(x->Date(x, "dd.mm.yyyy"), samples_raw.data[1].values)
	samples = NamedArray(schema2arr(samples_raw)[:,3:end], (schema2arr(samples_raw)[:,2], nuclide_names), ("samples", "nuclides"))
	
	if settings["use_decay_correction"] == true
		ref_date = settings["ref_date"]
		date_format = Dates.DateFormat("d u");
		(month_, day_) = Dates.monthday(Dates.DateTime(ref_date, date_format))

		tday_raw = [Date(years[1], month_, day_):Dates.Year(1):Date(years[end], month_, day_);]' .- sample_view; # calculate difference in days
		tday = NamedArray(convert(Array{Int64,2}, tday_raw), (NamedArrays.names(samples, 1), years),  ("samples", "years") )
	else
		tday = NamedArray(zeros(size(sample_view, 1), length(years) ), (NamedArrays.names(samples, 1), years),  ("samples", "years") )
	end
	
	samples_korr = NamedArray(Array(Float64, size(tday,1), size(samples,2), size(tday,2)), 
					(NamedArrays.names(samples, 1), nuclide_names, years), 
					("samples", "nuclides", "year") );
	for i in years
		samples_korr[:,:,i] = samples.array .* 2.^(-tday[:,i].array ./ hl);
		# Am241 and Pu241 must be in sample nuclide_names
		samples_korr[:,"Am241",i] = samples_korr[:,"Am241",i].array + samples[:, "Pu241"].array .* hl[1,"Pu241"]./(hl[1,"Pu241"] - hl[1,"Am241"]) .*
											(2.^(-tday[:,i].array ./ hl[1,"Pu241"]) - 2.^(-tday[:,i].array ./ hl[1,"Am241"]))
	end
	
	return samples_korr
end

#######################################################
# relevant nuclides and calculations

function nuclide_parts(samples_korr::NamedArrays.NamedArray{Float64,3,Array{Float64,3},Tuple{Dict{Any,Int64},Dict{ASCIIString,Int64},Dict{Int64,Int64}}})
	NamedArray( samples_korr./sum(samples_korr,2), samples_korr.dicts, samples_korr.dimnames)
end

function nuclide_parts(sf::AbstractString)
	global settings = YAML.load(open(sf));
	global rel_nuclides = settings["nuclides"]
	global nvdb = SQLite.DB(settings["db_name"]);
	global nuclide_names = convert(Array{ASCIIString,1}, query(nvdb, "pragma table_info(halflife)")[:,2]);
	samples_korr = decay_correction(nvdb, nuclide_names, get_years() )
	NamedArray( samples_korr./sum(samples_korr,2), samples_korr.dicts, samples_korr.dimnames)
end

function calc_factors(samples_part::NamedArrays.NamedArray{Float64,3,Array{Float64,3},Tuple{Dict{Any,Int64},Dict{ASCIIString,Int64},Dict{Int64,Int64}}})
	#specific = read_setting(:specific, sf)
	clearance_val = read_db(nvdb, "clearance_val");

	ɛ = read_db(nvdb, "efficiency");
	f = NamedArray( 1./clearance_val, clearance_val.dicts, clearance_val.dimnames);

	A = NamedArray(Array(Float64, size(samples_part,1), size(clearance_val,1), size(samples_part,3)), 
					(allnames(samples_part)[1], allnames(clearance_val)[1], get_years()), 
					("sample", "path", "years")); # path -> clearance path
	∑Co60Eq = NamedArray(Array(Float64, size(samples_part,1), size(ɛ,1), size(samples_part,3)), 
					(allnames(samples_part)[1], allnames(ɛ)[1], get_years()), 
					("sample", "path", "years")); # path -> fma / fmb / is
	
	(fᵀ = f'; ɛᵀ = ɛ');
	for i in get_years()
		A[:,:,i] = samples_part[:,:,i] * fᵀ
		∑Co60Eq[:,:,i] = samples_part[:,:,i] * ɛᵀ # sum of Co60-equiv. also contain non measureable nuclides
	end
	a = 1./A;

	return a, ∑Co60Eq, f, ɛ
end

#######################################################
# solve problem

function get_nv(sf::AbstractString)
	global settings = YAML.load(open(sf));
	global rel_nuclides = settings["nuclides"]
	
	global nvdb = SQLite.DB(settings["db_name"]);

	global nuclide_names = convert(Array{ASCIIString,1}, query(nvdb, "pragma table_info(halflife)")[:,2]);
	
	a, ∑Co60Eq, f, ɛ = decay_correction(nvdb, nuclide_names, get_years() ) |> nuclide_parts |> calc_factors
	
	(nv = Array(Float64, length(rel_nuclides), size(a,3)-1); i = 1);
	@showprogress for l in get_years()[1:end-1] # year =1:length(get_years())-1
		 (nv[:, i] = solve_nv( l, a, ∑Co60Eq, reduce_factor(f), reduce_factor(ɛ) ); i += 1);
	end
	write_result(nv)
end

function determine_list_∑Co60Eq()
	fmx = Array(Array{Any,1}, 3)
	list_∑Co60Eq = Array(Int, 0)
	index = settings["clearance_paths"][1]
	
	for i in ["fma", "fmb", "is"]
		if !isempty( find(i .== settings["use_co60eq"]) )
			ind = find(i .== ["fma", "fmb", "is"])[1]
			fmx[ ind ] = index[i];
			push!(list_∑Co60Eq, ind)
		end
	end
	if !isdefined(fmx, 1) && !isdefined(fmx, 2) && !isdefined(fmx, 3)
		error("expected 'fma', 'fmb' or 'is' in a list in option 'use_co60eq'")
	end
	
	return fmx, list_∑Co60Eq
end

function add_user_constraints(m::JuMP.Model, x::Array{JuMP.Variable,1})
	for constr in settings["constraints"]
		constr_tmp = split(constr)
		index = find(rel_nuclides .== constr_tmp[1])[1]
		rhs = float(constr_tmp[3]) * 100
		if constr_tmp[2] == "<="
			@addConstraint(m, x[index] <= rhs)
		elseif constr_tmp[2] == ">="
			@addConstraint(m, x[index] >= rhs)
		elseif (constr_tmp[2] == "==") | (constr_tmp[2] == "=")
			@addConstraint(m, x[index] == rhs)
		else
			error("expected comparison operator (<=, >=, or ==) for constraints")
		end
	end
end

function solve_nv{ T1<:NamedArrays.NamedArray{Float64,3,Array{Float64,3},Tuple{Dict{Any,Int64},Dict{UTF8String,Int64},Dict{Int64,Int64}}},
				   T2<:NamedArrays.NamedArray{Any,2,Array{Any,2},Tuple{Dict{UTF8String,Int64},Dict{UTF8String,Int64}}}}(
				   l::Int, a::T1, ∑Co60Eq::T1, f_red::T2, ɛ_red::T2 )
	m=Model(solver = CbcSolver());
	@defVar(m, 0 ≤ x[1:length(rel_nuclides)] ≤ 10_000, Int);
	#@setObjective(m, :Min, -sum( x[ find(rel_nuclides .== "Co60") | find(rel_nuclides .== "Cs137")]) ); 
	
	if settings["ot"] == "measure"
		@setObjective(m, :Min, -x[ find(rel_nuclides .== "Co60")][1] 
								-x[ find(rel_nuclides .== "Cs137")][1] );
	elseif settings["ot"] in keys(read_db(nvdb, "clearance_val").dicts[1])
		@setObjective(m, :Min, sum(x .* f_red[settings["ot"], :]) );
	else
		error("expected 'measure' or clearance path for optimization target")
	end
	@addConstraint(m, sum(x) == 10_000);

	# add user constraints
	if typeof(settings["constraints"]) != Void
		add_user_constraints(m, x)
	end
	
	# Co60-equiv for nv
	@defExpr(Co60eqnv[p=1:3], ∑{ɛ_red[p,i] * x[i], i=1:length(rel_nuclides); ɛ_red[p,i] != 0})
	
	# determine fma / fmb / is
	fmx, list_∑Co60Eq = determine_list_∑Co60Eq()
	
	for r in list_∑Co60Eq
		# lower bound
		@addConstraint(m, constr_lb[k in fmx[r], j=1:size(a,1), h=0:1], Co60eqnv[r] ≤ ∑Co60Eq[j,r,l+h] * a[j,k,l+h] * ∑{f_red[k,i] * x[i], i=1:length(rel_nuclides)} )
		# upper bound
		if settings["use_upper_bound"]
			@addConstraint(m, constr_ub[k in fmx[r], j=1:size(a,1), h=0:1], ∑Co60Eq[j,r,l+h] * a[j,k,l+h] * ∑{f_red[k,i] * x[i], i=1:length(rel_nuclides)} ≤ settings["upper_bound"] * Co60eqnv[r] )
		end
	end

	sstatus = solve(m, suppress_warnings=true);

	if (sstatus == :Infeasible)
		print_with_color(:red, string(l) * " no solution in given bounds\n")
		return zeros(length(x))
	elseif sstatus == :Optimal
		#print_with_color(:green, string(l) * " solution found.\n")
		return round(getValue(x)./100, 2)
	else
		print("Something weird happen! sstatus = " * string(sstatus) *"\n")
		return zeros(length(x))
	end
	
end

function write_result(nv::Array{Float64,2})
	NamedArray( nv, (rel_nuclides, get_years()[1:end-1]), ("nuclides", "years"))
	#writetable(nv_name * "/" * string(get_years()[l]) * "_" * clearance_paths * ".csv", nv, separator=';')
end

#######################################################
# test NV

function test_nv(tf::AbstractString)
	global settings = YAML.load(open(tf));
	global nvdb = SQLite.DB(settings["db_name"]);
	global nuclide_names = convert(Array{ASCIIString,1}, query(nvdb, "pragma table_info(halflife)")[:,2]);
	
	a, ∑Co60Eq, f, ɛ = decay_correction(nvdb, nuclide_names, get_years() ) |> nuclide_parts |> calc_factors
	
	full_list_nv = get_pre_nv()

	f_nv = f * full_list_nv
	ɛ_nv = ɛ * full_list_nv
	
	fmx, list_∑Co60Eq = determine_list_∑Co60Eq()
	
	for r in list_∑Co60Eq
		for l in get_years()
			print_with_color(:green, string(allnames(ɛ_nv)[1][r]) * ", " * string(l) * "\n")
			println( print_ratio(∑Co60Eq, a, f_nv, ɛ_nv, l, r, fmx) )
		end
	end
end

function print_ratio(∑Co60Eq, a, f_nv, ɛ_nv, l, r, fmx)
	ratio = NamedArray(Array(Float64, length(fmx[r]), size(a, 1)), 
					(fmx[r], allnames(a)[1]), 
					("path", "sample"));
	
	for j = 1:size(a, 1)
		i = 1
		for k in fmx[r]
			ratio[i, j] = ∑Co60Eq[j,r,l] * a[j,k,l] * f_nv[k] ./ ɛ_nv[r]
			i += 1
		end
	end
	ratio, 1 .<= ratio
end

function get_pre_nv()
	full_list_nv = zeros( length(nuclide_names), 1)
	for nv in settings["nuclide_vector"]
		nv_tmp = split(nv)
		full_list_nv[ find(nuclide_names .== nv_tmp[1])[1] ] = float(nv_tmp[3]) * 100
		rhs = float(nv_tmp[3]) * 100
	end
	if sum(full_list_nv) != 10_000
		error("Nuclide vector sum is not 1!")
	end
	return full_list_nv
end
