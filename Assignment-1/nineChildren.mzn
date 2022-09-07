include "globals.mzn";

% number of children:
int: n = 9;
% array of integers representing the children’s ages:
array[1..n] of var 0..150: Children;
% integer representing the parent's age:
var 1..150: parent;

% find solution:
solve satisfy;

% ensure children are not born at the same time:
constraint all_different(Children);
% omit symmetric solutions:
constraint forall(i in 1..n-1)(Children[i+1] > Children[i]);
% ensure uniform age gap between children:
constraint forall(i in 1..n-2)(Children[i+1] - Children[i] = Children[i+2] - Children[i+1]);
% ensure squared age of parent equals sum of squared ages of children:
constraint pow(parent,2) = sum([pow(Children[i],2) | i in 1..n]);