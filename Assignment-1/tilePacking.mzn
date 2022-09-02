include "globals.mzn";

int: n;
array[1..n] of int: side = 1..n;
int: maxDim = sum(1..n);
var 1..maxDim: w;
var 1..maxDim: h;

array[1..n] of var 1..maxDim: x;
array[1..n] of var 1..maxDim: y;

constraint diffn(x,y,side,side);

constraint forall(i in 1..n)(x[i] + i <= w);
constraint forall(i in 1..n)(y[i] + i <= h);

solve minimize w*h;
