# NuclideVector

julia-release: [![Build Status](https://travis-ci.org/Ph0non/NuclideVector.svg?branch=master)](https://travis-ci.org/Ph0non/NuclideVector) [![Build status](https://ci.appveyor.com/api/projects/status/d97d0jnxrx9r50bn/branch/master?svg=true)](https://ci.appveyor.com/project/Ph0non/nuclidevector/branch/master) [![codecov](https://codecov.io/gh/Ph0non/NuclideVector/branch/master/graph/badge.svg)](https://codecov.io/gh/Ph0non/NuclideVector) 


This package provides a comfortable way to calculate conservative nuclide vectors in accordance with the german Radiation Protection Ordinance.

## Main Features
- Store samples in a SQLite database
- automatic decay correction
- various optimization methods (measure: high Co60 and Cs137, weightable mean: lowest square deviation from the sample mean or optimize to a specific clearance path)
- various clearance path
- various clearance methods
- constraints and optional weights for radionuclides

It's written for the EWN Entsorgungswerk für Nuklearanlagen GmbH (former Energiewerke Nord GmbH).

<<<<<<< HEAD
### THIS IS NOT A MODULE!
=======
## How to start
>>>>>>> master
To run the application run
```
using NuclideVector
run_nv()
```

<<<<<<< HEAD
### Attention
Temporaly is coin-or.org down, so no Cbc package. I will fix this in `REQUIRE` and `core.jl` immediately coin-or.org is up again.
=======
Notice: This application is designed for x64. There will be maybe a x86 version in the future.
>>>>>>> master
