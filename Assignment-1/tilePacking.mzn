include "globals.mzn";

% Number of tiles:
int: n;
% The side length of each tile:
array[1..n] of int: side = 1..n;
% The maximal side lengths the resulting rectangle can obtain
% is the sum of all the lengths of the tiles:
int: maxDim = sum(1..n);
var 1..maxDim: w;
var 1..maxDim: h;

% Array for the x-coordinates of the tiles:
array[1..n] of var 1..maxDim: x;
% Array for the y-coordinates of the tiles:
array[1..n] of var 1..maxDim: y;

% Ensure that no tiles are overlapping:
constraint diffn(x,y,side,side);

% For each tile of width i, it holds that the x-coordinate of the tile
% plus the width of the tile is within the width of the resulting rectangle:
constraint w = max([x[i] + i | i in 1..n]);
% The same holds for the y-coordinate of each tile
% and the height of the resulting rectangle:
constraint h = max([y[i] + i | i in 1..n]); 

% For part C:
% Place the largest tile in the lower-left quadrant of the bounding rectangle,
% in order to avoid symmetric solutions 
constraint x[n] * 2 < w;
constraint y[n] * 2 < h;

% minimize width and height of rectangle
solve minimize w*h;
