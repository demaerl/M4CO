include "globals.mzn";
array[1..9] of var 0..150: Children;
var 1..150: Parent;

solve satisfy;

constraint all_different(Children);
constraint forall(i in 1..7)(Children[i+1] - Children[i] = Children[i+2] - Children[i+1]);
constraint pow(Parent,2) = sum([pow(Children[i],2) | i in 1..9]);