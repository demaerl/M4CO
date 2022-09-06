include "globals.mzn";

% The length of the permutation:
int: n;

% Array containing the permutation:
array[1..n] of var 1..n: Permutation;

% Each integer in the range 1..n appears exactly once on the permutation:
constraint all_different(Permutation);

% Maximize the sum of all pairs of successive values:
solve maximize sum([ Permutation[i] * Permutation[i+1] | i in 1..n-1]);

% Output the (maximized) sum as well as the permutation:
output[show(sum([ Permutation[i] * Permutation[i+1] | i in 1..n-1])),
       show(Permutation)];
