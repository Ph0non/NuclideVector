# test NV
type Clearance
  name::String
  values::Vector{Float64}
end

#                    OF       1a      2a      3a      4a        1b      2b       3b     4b      5b       6b_2c
clearance_unit = ["Bq/cm²", "Bq/g", "Bq/g", "Bq/g", "Bq/cm²", "Bq/g", "Bq/g", "Bq/g", "Bq/g", "Bq/cm²", "Bq/g" ]

function clearance_gui()
  np = decay_correction(nvdb, nuclide_names, get_years() ) |> nuclide_parts

  update_year_ListModel()
  nv = ListModel2NamedArray(nuclides)

  clearance_val = read_db(nvdb, "clearance_val")
  f = NamedArray( 1./nable2arr(clearance_val), clearance_val.dicts, clearance_val.dimnames)
  global clearance_year = 1./(f[:, names(nv)[1]] * nv./100)

  clearance = [Clearance(name * " / " * clearance_unit[i], clearance_year[name, :].array) for (i, name) in enumerate( names(clearance_year)[1]) ]
  clearanceModel = ListModel(clearance)

  # add roles manually:
  for (i,year_clearance) in enumerate( years )
    addrole(clearanceModel, year_clearance, n -> round(n.values[i], 2))
  end
  @qmlset qmlcontext().clearanceModel = clearanceModel

end
@qmlfunction clearance_gui

years_clearance = map(x -> string(x), get_years()[1:end-1])
clearance = [Clearance(name, zeros(length(years_clearance))) for name in SQLite.query(nvdb, "select path from clearance_val") |> nable2arr |> vec ]
clearanceModel = ListModel(clearance)

for (i,year_clearance) in enumerate( years_clearance )
  addrole(clearanceModel, year_clearance, n -> round(n.values[i], 2))
end

function copy2clipboard_clearance()
  nv = ListModel2NamedArray(nuclides)

  s = "\t"
  for i in names(nv)[2]
    s *= string(i) * "\t"
  end
  s *= "\n"
  for j=1:size(clearance_year, 1)
    s *= names(clearance_year)[1][j] * " / " * clearance_unit[j] * "\t"
    for i=1:size(clearance_year, 2)
      s *= replace(string(clearance_year.array[j, i]), ".", ",") * "\t"
    end
    s *= "\n"
  end
  clipboard(s)
end
@qmlfunction copy2clipboard_clearance
