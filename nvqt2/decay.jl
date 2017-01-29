# test NV
type Decay
  name::String
  values::Vector{Float64}
end

function decay_gui(y::String, show_relnuc::Bool)
  y = parse(y)
  np = decay_correction(nvdb, nuclide_names, get_years() ) |> nuclide_parts

  # exposed as context property
  samples_row = ["Min"; "Mittel"; "Max"; map(x->string(x), names(np)[1])]
  @qmlset qmlcontext().samples_row = samples_row

  if show_relnuc
    decay = [Decay(name, [minimum(np[:, name, y].array .* 100);
                        mean(np[:, name, y].array .* 100);
                        maximum(np[:, name, y].array .* 100);
                        np[:, name, y].array .* 100] ) for name in [rel_nuclides3[i].name for i=1:length(rel_nuclides3) ] ]
  else
    decay = [Decay(name, [minimum(np[:, name, y].array .* 100);
                        mean(np[:, name, y].array .* 100);
                        maximum(np[:, name, y].array .* 100);
                        np[:, name, y].array .* 100] ) for name in names(np)[2] ]
  end
  decayModel = ListModel(decay)

  # add roles manually:
  for (i,sample_row) in enumerate( samples_row )
    addrole(decayModel, sample_row, n -> round(n.values[i], 4))
  end
  @qmlset qmlcontext().decayModel = decayModel

end
@qmlfunction decay_gui

samples_row = ["Min", "Mittel", "Max", "1", "2", "3"]
decay = [Decay(name, zeros(length(samples_row))) for name in ["Co60", "Cs137"] ]
decayModel = ListModel(decay)

for (i,sample_row) in enumerate( samples_row )
  addrole(decayModel, sample_row, n -> n.values[i])
end
