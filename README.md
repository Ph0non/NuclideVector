<<<<<<< HEAD
[![Build Status](https://travis-ci.org/Ph0non/NuclideVector.svg?branch=master)](https://travis-ci.org/Ph0non/NuclideVector)
  [![codecov](https://codecov.io/gh/Ph0non/NuclideVector/branch/master/graph/badge.svg)](https://codecov.io/gh/Ph0non/NuclideVector)
=======
# NuclideVector

[![Build Status](https://travis-ci.org/Ph0non/NuclideVector.svg?branch=master)](https://travis-ci.org/Ph0non/NuclideVector)
  [![codecov](https://codecov.io/gh/Ph0non/NuclideVector/branch/master/graph/badge.svg)](https://codecov.io/gh/Ph0non/NuclideVector)

This package provides a comfortable way to calculate conservative nuclide vectors in accordance with the german Radiation Protection Ordinance.

## Main Features
- Store samples in a SQLite database
- automatic decay correction
- various optimization methods (measure: high Co60 and Cs137, weightable mean: lowest square deviation from the sample mean or optimize to a specific clearance path)
- various clearance path
- various clearance methods
- constraints and optional weights for radionuclides

It's written for the EWN Entsorgungswerk für Nuklearanlagen GmbH (former Energiewerke Nord GmbH).

### THIS IS NOT A MODULE!
To run the application run `src/NuclideVector.jl`

### Attention
Temporaly is coin-or.org down, so no Cbc package. I Will fix this in `REQUIRE` and `core.jl` immediately coin-or.org is up again.
>>>>>>> 79a632db948db8c330c9f23f24b26c20550fb152
