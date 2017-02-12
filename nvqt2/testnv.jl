# test NV
type Overestimate
  name::String
  values::Vector{Float64}
end

function test_nv_gui(y::String, fmx_ind::Int32)
  y = parse(y)
  if y == -1
    y = genSettings.year[1]
  end
  fmx_ind += 1
  __years__ = map(x -> parse(x), years)
  append!(__years__, __years__[end]+1)
	a, ∑Co60Eq, f, ɛ = calc_factors( decay_correction(nvdb, nuclide_names, __years__ ) |> nuclide_parts, __years__ )

  if isempty(rel_nuclides3) # standard values
    rel_nuclides = ["Co60", "Cs137", "Fe55", "Ni63", "Sr90", "Am241"]
  else
    rel_nuclides = [rel_nuclides3[i].name for i=1:length(rel_nuclides3)]
  end
print("Moo")
print(rel_nuclides) # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
print("!")
  f_nv = f[:,rel_nuclides] * ListModel2NamedArray(nuclides)[:, y]
  ɛ_nv = nable2arr(ɛ[:,rel_nuclides]) * ListModel2NamedArray(nuclides)[:, y]

	list_∑Co60Eq = determine_list_∑Co60Eq()

  global ratio1 = NamedArray(Array(Float64, size(a, 1), length(fmx[fmx_ind])),
  				( map(x->string(x),names(a)[1]), fmx[fmx_ind]),
  				("name", "path"))

  global ratio2 = NamedArray(Array(Float64, size(a, 1), length(fmx[fmx_ind])),
        	( map(x->string(x),names(a)[1]), fmx[fmx_ind]),
        	("name", "path"))

	for (index, j) in enumerate(names(a)[1])
		i = 1
		for k in fmx[fmx_ind]
			ratio1[index, i] = ∑Co60Eq[j,fmx_ind,y] * a[j,k,y] * f_nv[k] ./ ɛ_nv[fmx_ind]
      ratio2[index, i] = ∑Co60Eq[j,fmx_ind,y+1] * a[j,k,y+1] * f_nv[k] ./ ɛ_nv[fmx_ind]
			i += 1
		end
	end

  # exposed as context property
  fmx_row = fmx[fmx_ind]
  @qmlset qmlcontext().fmx_row = fmx_row

  sampleOverestimate = [Overestimate(name, ratio1[name, :].array ) for name in map(x->string(x), vec(get_sample_info("s_id") ) ) ]
  sampleModel = ListModel(sampleOverestimate)
  sampleOverestimate_eoy = [Overestimate(name, ratio2[name, :].array ) for name in map(x->string(x), vec(get_sample_info("s_id") ) ) ]
  sampleModel_eoy = ListModel(sampleOverestimate_eoy)

  # add roles manually:
  for (i,fmx_) in enumerate(fmx[fmx_ind])
    addrole(sampleModel, fmx_, n -> n.values[i])
    addrole(sampleModel_eoy, fmx_, n -> n.values[i])
  end
  @qmlset qmlcontext().sampleModel = sampleModel
  @qmlset qmlcontext().sampleModel_eoy = sampleModel_eoy

end
@qmlfunction test_nv_gui

fmx_row = ["OF","1a","2a","4a","1b","2b","3b","4b","5b","6b_2c"]
sampleOverestimate = [Overestimate(name, zeros(length(fmx_row))) for name in ["1", "2", "3"] ]
sampleModel = ListModel(sampleOverestimate)
sampleOverestimate_eoy = [Overestimate(name, zeros(length(fmx_row))) for name in ["1", "2", "3"] ]
sampleModel_eoy = ListModel(sampleOverestimate_eoy)
  # add roles manually:
for (i,fmx_) in enumerate(fmx_row)
  addrole(sampleModel, fmx_, n -> n.values[i])
  addrole(sampleModel_eoy, fmx_, n -> n.values[i])
end

function copy2clipboard_testnv(y::String)
  s = "01.01." * y * "\n"
  s *= helper_copy2clipboard_testnv(ratio1)
  s *= "\n\n31.12." * y * "\n"
  s *= helper_copy2clipboard_testnv(ratio2)
  clipboard(s)
end
@qmlfunction copy2clipboard_testnv

function helper_copy2clipboard_testnv(ratio::NamedArray)
  s = "Probe \\ Pfad\t"
  for i in names(ratio)[2]
    s *= i * "\t"
  end
  s *= "\n"
  for j=1:size(ratio, 1)
    s *= names(ratio)[1][j] * "\t"
    for i=1:size(ratio, 2)
      s *= replace(string(ratio.array[j, i]), ".", ",") * "\t"
    end
    s *= "\n"
  end
  return s
end
