type Nuclide
  name::String
  values::Vector{Float64}
end

function start_nv_calc()
  @qmlset qmlcontext().start_cal_ctx_button = false

  # @emit killColumn(Int32(1))

  # exposed as context property
  global years = map(x -> string(x), get_years()[1:end-1])
  @qmlset qmlcontext().years = years

  global nv_NamedArray = get_nv()

  global nuclides = [Nuclide(name, nv_NamedArray[name,:].array) for name in names(nv_NamedArray)[1] ]
  global nuclidesModel = ListModel(nuclides)

  # add year roles manually:
  for (i,year) in enumerate(years)
    addrole(nuclidesModel, year, n -> round(n.values[i],2), (n, newval, row) -> n[row].values[i] = newval)
    # n is the list of nuclides, row the row in the table (converted to 1-based) and newval is the value for the role, which is one of the years here and so I guess a Float64.
    # see https://github.com/barche/QML.jl/issues/35#issuecomment-278986931
  end
  @qmlset qmlcontext().nuclidesModel = nuclidesModel

  @qmlset qmlcontext().start_cal_ctx_button = true
  nothing
end
@qmlfunction start_nv_calc

start_cal_ctx_button = true

years = map(x -> string(x), get_years()[1:end-1]) # exposed as context property
nuclides = [Nuclide(name, zeros(length(years))) for name in ["Co60", "Cs137", "Fe55", "Ni63", "Sr90", "Am241"]]
nuclidesModel = ListModel(nuclides)

# add year roles manually:
for (i,year) in enumerate(years)
  addrole(nuclidesModel, year, n -> round(n.values[i],2), (n, newval, row) -> n[row].values[i] = newval)
end

function copy2clipboard_nv()
  nv = ListModel2NamedArray(nuclides)

  s = "\t"
  for i in names(nv)[2]
    s *= string(i) * "\t"
  end
  s *= "\n"
  for j=1:size(nv, 1)
    s *= names(nv)[1][j] * "\t"
    for i=1:size(nv, 2)
      s *= replace(string(nv.array[j, i]), ".", ",") * "\t"
    end
    s *= "\n"
  end
  clipboard(s)
end
@qmlfunction copy2clipboard_nv
