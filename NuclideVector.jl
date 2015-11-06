#######################################################
# load modules
using SQLite: query, SQLiteDB
using NamedArrays
using JuMP
using Cbc
using YAML

#######################################################
# settings

const sf = "settings_yaml.txt";
settings = YAML.load(open(sf));

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

get_years() = collect(settings["years"][1] : settings["years"][2])

utf2ascii(y::Array{Any,1}) = map( x -> ASCIIString(x), y)

#######################################################
# database

const nvdb = SQLite.DB(settings["db_name"]);

const nuclide_names = convert(Array{ASCIIString,1}, query(nvdb, "pragma table_info(halflife)")[:,2]);

# read db table with first column as Named Array dimnames
function read_db(nvdb::SQLite.DB, tab::ASCIIString)
	val = query(nvdb, "select * from " * tab);
	val_data = schema2arr(val)[:,2:end]
	nu_name = utf2ascii( val.schema.header[2:end] )
	path_names = utf2ascii( val.data[1].values)
	NamedArray(val_data, (path_names, nu_name), ("path", "nuclides"))
end

#######################################################
# decay correction

function decay_correction(nvdb::SQLite.DB, nuclide_names::Array{ASCIIString, 1})
	hl_raw = query(nvdb, "select " * arr2str(nuclide_names) * " from halflife");
	hl = NamedArray(schema2arr(hl_raw), ([1], nuclide_names), ("halftime", "nuclides"))
	
	samples_raw = query(nvdb, "select date, s_id, " * arr2str(nuclide_names) 
						* " from nv_data join nv_summary on nv_data.nv_id = nv_summary.nv_id where NV = '" 
						* settings["nv_name"] *"'");
	sample_view = map(x->Date(x, "dd.mm.yyyy"), samples_raw.data[1].values)
	samples = NamedArray(schema2arr(samples_raw)[:,3:end], (schema2arr(samples_raw)[:,2], nuclide_names), ("samples", "nuclides"))
	
	years = get_years()
	
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

function nuclide_parts()
	samples_korr = decay_correction(nvdb, nuclide_names)
	NamedArray( samples_korr./sum(samples_korr,2), samples_korr.dicts, samples_korr.dimnames)
end

function calc_factors(samples_part::NamedArrays.NamedArray{Float64,3,Array{Float64,3},Tuple{Dict{Any,Int64},Dict{ASCIIString,Int64},Dict{Int64,Int64}}})
	#specific = read_setting(:specific, sf)
	clearance_val = read_db(nvdb, "clearance_val");

	eff = read_db(nvdb, "efficiency");
	eff_red = eff[:, rel_nuclides];

	f = NamedArray( 1./clearance_val, clearance_val.dicts, clearance_val.dimnames);
	f_red = f[:, rel_nuclides];

	A = NamedArray(Array(Float64, size(samples_part,1), size(clearance_val,1), size(samples_part,3)), 
					(allnames(samples_part)[1], allnames(clearance_val)[1], get_years()), 
					("sample", "path", "years")); # path -> clearance path
	C = NamedArray(Array(Float64, size(samples_part,1), size(eff,1), size(samples_part,3)), 
					(allnames(samples_part)[1], allnames(eff)[1], get_years()), 
					("sample", "path", "years")); # path -> fma / fmab
	
	(ft = f'; efft = eff');
	for i in get_years()
		A[:,:,i] = samples_part[:,:,i] * ft
		C[:,:,i] = samples_part[:,:,i] * efft # sum of Co60-equiv. also contain non measureable nuclides
	end
	a = 1./A;

	return a, C, f_red, eff_red
end

#######################################################
# solve problem

function get_nv()
	global settings = YAML.load(open(sf));
	global rel_nuclides = convert(Array{ASCIIString, 1}, settings["nuclides"]);
	
	a, C, f_red, eff_red = decay_correction(nvdb, nuclide_names) |> nuclide_parts |> calc_factors
	(nv = Array(Float64, size(f_red,2), size(a,3)-1); i = 1);
	for l in get_years()[1:end-1] # year =1:length(get_years())-1
		 (nv[:, i] = solve_nv(l, a, C, f_red, eff_red); i += 1);
	end
	write_result(nv)
end

function determine_fmx()
	fmx = Array(Any,2)
	if (settings["use_fmab"] == "fma")
		fmx[1] = utf2ascii( settings["clearance_paths"][1]["fma"]  )
		(p = 1; q = 1);
	elseif (settings["use_fmab"] == "fmb")
		fmx[2] = utf2ascii( settings["clearance_paths"][1]["fmb"] )
		(p = 2; q = 2);
	elseif (settings["use_fmab"] == "fmab")
		fmx[1] = utf2ascii( settings["clearance_paths"][1]["fma"] )
		fmx[2] = utf2ascii( settings["clearance_paths"][1]["fmb"] )
		(p = 1; q = 2);
	else
		error("expected 'fma', 'fmb' or 'fmab' in option 'use_fmab'")
	end
	return fmx, p, q
end

function add_user_constraints(m::JuMP.Model, x::Array{JuMP.Variable,1})
	for constr in settings["constraints"]
		constr_tmp = split(constr)
		if constr_tmp[2] == "<="
			@addConstraint(m, x[find(rel_nuclides .== constr_tmp[1])][1] <= float(constr_tmp[3]) * 100)
		elseif constr_tmp[2] == ">="
			@addConstraint(m, x[find(rel_nuclides .== constr_tmp[1])][1] >= float(constr_tmp[3]) * 100)
		elseif constr_tmp[2] == "=="
			@addConstraint(m, x[find(rel_nuclides .== constr_tmp[1])][1] == float(constr_tmp[3]) * 100)
		else
			error("expected comparison operator (<=, >=, or ==) for constraints")
		end
	end
end

function solve_nv{ T1<:NamedArrays.NamedArray{Float64,3,Array{Float64,3},Tuple{Dict{Any,Int64},Dict{ASCIIString,Int64},Dict{Int64,Int64}}},
				   T2<:NamedArrays.NamedArray{Any,2,Array{Any,2},Tuple{Dict{ASCIIString,Int64},Dict{ASCIIString,Int64}}}}(
				   l::Int, a::T1, C::T1, f_red::T2, eff_red::T2 )
	m=Model(solver = CbcSolver());
	@defVar(m, 0 ≤ x[1:length(rel_nuclides)] <= 10_000, Int); #≤
	#@setObjective(m, :Min, -sum( x[ find(rel_nuclides .== "Co60") | find(rel_nuclides .== "Cs137")]) ); 
	@setObjective(m, :Min, -x[ find(rel_nuclides .== "Co60")][1] 
						   -x[ find(rel_nuclides .== "Cs137")][1] );
	@addConstraint(m, sum(x) == 10_000);

	# add user constraints
	if typeof(settings["constraints"]) != Void
		add_user_constraints(m, x)
	end
	
	# Co60-equiv for nv
	@defExpr(Co60eqnv[p=1:2], ∑{eff_red[p,i] * x[i], i=1:length(rel_nuclides); eff_red[p,i] != 0}) # ∑
	
	# determine fma / fmb / fmab
	fmx, p, q = determine_fmx()
	
	for r = p:q
		# lower bound
		@addConstraint(m, constr_lb[k in fmx[r], j=1:size(a,1), h=0:1], Co60eqnv[r] ≤ C[j,r,l+h] * a[j,k,l+h] * ∑{f_red[k,i] * x[i], i=1:length(rel_nuclides)} )
		if settings["use_upper_bound"]
		# upper bound
			@addConstraint(m, constr_ub[k in fmx[r], j=1:size(a,1), h=0:1], C[j,r,l+h] * a[j,k,l+h] * ∑{f_red[k,i] * x[i], i=1:length(rel_nuclides)} ≤ settings["upper_bound"] * Co60eqnv[r] )
		end
	end

	sstatus = solve(m, suppress_warnings=true);

	if (sstatus == :Infeasible)
		print_with_color(:red, string(l) * " no solution in given bounds\n")
		return zeros(length(x))
	elseif sstatus == :Optimal
		print_with_color(:green, string(l) * " solution found.\n")
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
