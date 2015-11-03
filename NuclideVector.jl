#######################################################
# load modules
using SQLite: query, SQLiteDB
using NamedArrays
using FunctionalData
using JuMP
using Cbc
using YAML

#######################################################
# settings

const sf = "settings_yaml.txt";

settings = YAML.load(open(sf));

rel_nuclides = convert(Array{ASCIIString, 1}, settings["nuclides"]);

#######################################################
# helper functions

function arr2str(nn::Array{ASCIIString, 1})
	nn_str = nn[1]
	for i=2:length(nn)
		nn_str *= ", " * nn[i]
	end
	return nn_str
end

function arr2sym(nn::Array{ASCIIString, 1})
	nn_sym = Array(Symbol, length(nn))
	for i=1:length(nn)
		nn_sym[i] = Symbol(nn[i])
	end
	return nn_sym
end

function schema2arr(x::DataStreams.Data.Table)
	y = Array(Any, x.schema.rows, x.schema.cols)
	@simd for i=1:x.schema.cols
		y[:,i] = x.data[i].values
	end
	return y
end

function get_years()
	collect(settings["years"][1] : settings["years"][2])
end

#######################################################
# database

const nvdb = SQLite.DB(settings["db_name"]);

const nuclide_names = convert(Array{ASCIIString,1}, query(nvdb, "pragma table_info(halflife)")[:,2]);

# read db table with first column as Named Array dimnames
function read_db(nvdb::SQLite.DB, tab::ASCIIString)
	val = query(nvdb, "select * from " * tab);
	val_data = schema2arr(val)[:,2:end]
	nu_name = map( x-> ASCIIString(x), val.schema.header[2:end])
	path_names = map( x-> ASCIIString(x), val.data[1].values)
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
		tday = NamedArray(zeros(size(sample_view, 1), years[end] - years[1] + 1), (NamedArrays.names(samples, 1), years),  ("samples", "years") )
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

#specific = read_setting(:specific, sf)
samples_korr = decay_correction(nvdb, nuclide_names);
samples_part = NamedArray( samples_korr./sum(samples_korr,2), samples_korr.dicts, samples_korr.dimnames)
clearance_val = read_db(nvdb, "clearance_val");

eff = read_db(nvdb, "efficiency");
eff_red = eff[:, rel_nuclides];

f = NamedArray( 1./clearance_val, clearance_val.dicts, clearance_val.dimnames);
f_red = f[:, rel_nuclides];

A = NamedArray(Array(Float64, size(samples_korr,1), size(clearance_val,1), size(samples_korr,3)), 
				(allnames(samples_korr)[1], allnames(clearance_val)[1], get_years()), 
				("sample", "path", "years")); # path -> clearance path
C = NamedArray(Array(Float64, size(samples_korr,1), size(eff,1), size(samples_korr,3)), 
				(allnames(samples_korr)[1], allnames(eff)[1], get_years()), 
				("sample", "path", "years")); # path -> fma / fmab

for i in [years[1]:years[2];]
    A[:,:,i] = samples_part[:,:,i] * f'
    C[:,:,i] = samples_part[:,:,i] * eff' # sum of Co60-equiv. also contain non measureable nuclides
end
a = 1./A;

#######################################################
# solve problem

function get_nv()
	for l in get_years() # year
		 solve_nv(l)
	end
end

function solve_nv(l::Int)
	m=Model(solver = CbcSolver());
	@defVar(m, 0 <= x[1:length(rel_nuclides)] <= 10000, Int); #≤
	@setObjective(m, :Min, -x[ find(rel_nuclides .== "Co60")][1] 
						   -x[ find(rel_nuclides .== "Cs137")][1] );
	@addConstraint(m, sum(x) == 10000);

	
	for i in settings["constraints"]
		y = parse(i)
		y.args[1] = :(x[ $(find(rel_nuclides .== string(y.args[1]) ))  ])
		y.args[3] *= 10000
		#@addConstraint(m, esc(y)) <---- HERE
		#Expr(:macrocall,symbol("@addConstraint"),esc(m),esc(y)
	end
	
end
