# ThermoGradient

This is a notebook file to be used in R. It is intended to be used after completion of a seed germination experiment on a Thermo Gradient Plate (TGP). 

To use this script, you should have TGP data set up in this format: 

species, cell_x, cell_y, day, c_germination, day_temp, night_temp, viable_n, where: 

species is the plant species, 
cell_x and cell_y are the coordinates of the cell on the TGP (usually an alphanumeric grid on the TGP),
day is the day germination was checked and the number of days the experiment has been running (day 0 should be the first day of the experiment),
c_germinated is the cumulative  germination for each day
day_temp is the temperature of the cell during 'day' simulation,
night_temp is the temperature of the cell during 'night' simulation,
viable_n is the number of viable seeds in each cell - this can be determined before (with a 'global' viability) or after the experiment (via cut-tests).

You should also have 'thermo_seed_functions.R' downloaded into your working directory. 
