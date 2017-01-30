type Nuclide
  name::String
  values::Vector{Float64}
end

function start_nv_calc()
  @qmlset qmlcontext().start_cal_ctx_button = false

  # @emit killColumn(Int32(1))

  # exposed as context property
  years = map(x -> string(x), get_years()[1:end-1])
  @qmlset qmlcontext().years = years

  global nv_NamedArray = get_nv()

  global nuclides = [Nuclide(name, nv_NamedArray[name,:].array) for name in names(nv_NamedArray)[1] ]
  global nuclidesModel = ListModel(nuclides)

  # add year roles manually:
  for (i,year) in enumerate(years)
    addrole(nuclidesModel, year, n -> round(n.values[i],2))
  end
  @qmlset qmlcontext().nuclidesModel = nuclidesModel

  @qmlset qmlcontext().start_cal_ctx_button = true
  nothing
end
@qmlfunction start_nv_calc

start_cal_ctx_button = true

# function append_year()
#   global years
#   global nuclides
#   global nuclidesModel
#   newyear = length(years) > 0 ? string(parse(Int, years[end])+1) : "2016"
#   push!(years, newyear)
#   for nuc in nuclides
#     push!(nuc.values, rand())
#   end
#   @qmlset qmlcontext().years = years
#   year_idx = length(years)
#   addrole(nuclidesModel, newyear, n -> round(n.values[year_idx],2))
# end
# @qmlfunction append_year

years = map(x -> string(x), get_years()[1:end-1]) # exposed as context property
nuclides = [Nuclide(name, zeros(length(years))) for name in ["Co60", "Cs137", "Fe55", "Ni63", "Sr90", "Am241"]]
nuclidesModel = ListModel(nuclides)

# add year roles manually:
for (i,year) in enumerate(years)
  addrole(nuclidesModel, year, n -> round(n.values[i],2))
end

function copy2clipboard_nv()
  s = "\t"
  for i in collect(genSettings.year[1] : genSettings.year[2]-1)
    s *= string(i) * "\t"
  end
  s *= "\n"
  for j=1:size(nv_NamedArray, 1)
    s *= names(nv_NamedArray)[1][j] * "\t"
    for i=1:size(nv_NamedArray, 2)
      s *= replace(string(nv_NamedArray.array[j, i]), ".", ",") * "\t"
    end
    s *= "\n"
  end
  clipboard(s)
end
@qmlfunction copy2clipboard_nv
