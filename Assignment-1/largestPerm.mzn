include "globals.mzn";

int: n=5;

array[1..n] of var 1..n: permutation;

constraint all_different(permutation);

solve maximize(sum([ permutation[i]*permutation[i+1] | i in 1..n-1]));

output[show(sum([ permutation[i]*permutation[i+1] | i in 1..n-1])),
       show(permutation)]
