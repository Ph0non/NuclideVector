# test NV
type Decay
  name::String
  values::Vector{Float64}
end

function decay_gui(y::String, show_relnuc::Bool)
  y = parse(y)
  np = decay_correction(nvdb, nuclide_names, y ) |> nuclide_parts

  # exposed as context property
  samples_row = ["Min"; "Mittel"; "Max"; map(x->string(x), names(np)[1])]
  @qmlset qmlcontext().samples_row = samples_row

  if show_relnuc
    decay = [Decay(name, [minimum(np[:, name].array .* 100);
                        mean(np[:, name].array .* 100);
                        maximum(np[:, name].array .* 100);
                        np[:, name].array .* 100] ) for name in [rel_nuclides3[i].name for i=1:length(rel_nuclides3) ] ]
  else
    decay = [Decay(name, [minimum(np[:, name].array .* 100);
                        mean(np[:, name].array .* 100);
                        maximum(np[:, name].array .* 100);
                        np[:, name].array .* 100] ) for name in names(np)[2] ]
  end
  decayModel = ListModel(decay)

  # add roles manually:
  for (i,sample_row) in enumerate( samples_row )
    addrole(decayModel, sample_row, n -> round(n.values[i], 4))
  end
  @qmlset qmlcontext().decayModel = decayModel
  return decay
end
@qmlfunction decay_gui

samples_row = ["Min", "Mittel", "Max", "1", "2", "3"]
decay = [Decay(name, zeros(length(samples_row))) for name in ["Co60", "Cs137"] ]
decayModel = ListModel(decay)

for (i,sample_row) in enumerate( samples_row )
  addrole(decayModel, sample_row, n -> n.values[i])
end


function copy2clipboard_decay(y::String, show_relnuc::Bool)
  s = y  * "\n"

  y = parse(y)
  np = decay_correction(nvdb, nuclide_names, y ) |> nuclide_parts
  samples_row = ["Min"; "Mittel"; "Max"; map(x->string(x), names(np)[1])]

  s *= "\t"
  for i in samples_row
    s *= i * "\t"
  end
  s *= "\n"

  if show_relnuc
    rel_nuc_name = [rel_nuclides3[i].name for i=1:length(rel_nuclides3)]
    for (j, val) in enumerate(rel_nuc_name)
      s *= val * "\t" * string(minimum(np[:, val].array) .* 100) * "\t" *
                                            string(mean(np[:, val].array) .* 100) * "\t" *
                                            string(maximum(np[:, val].array) .* 100) * "\t"
      for i in names(np, 1)
        s *= replace(string(np[i, val] * 100), ".", ",") * "\t"
      end
      s *= "\n"
    end
  else
    for j=1:size(np, 2)
      s *= string(names(np)[2][j]) * "\t" * string(minimum(np.array[:, j]) .* 100) * "\t" *
                                            string(mean(np.array[:, j]) .* 100) * "\t" *
                                            string(maximum(np.array[:, j]) .* 100) * "\t"
      for i=1:size(np, 1)
        s *= replace(string(np.array[i, j] * 100), ".", ",") * "\t"
      end
      s *= "\n"
    end
  end

  clipboard(s)
  return s
end
@qmlfunction copy2clipboard_decay
