set terminal png size 1024, 768
set datafile separator ","
set logscale x 10
plot 'data/intervals_union.csv' using 6:($4/$6) with lines, \
     'data/gb_sets_union.csv' using 6:($4/$6) with lines, \
     'data/linear_intervals_union.csv' using 6:($4/$6) with lines
