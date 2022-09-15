/*
 *
 * Copyright: Pierre.Flener@it.uu.se and his teaching assistants, 2022.
 *
 * This file is part of courses 1DL442 and 1DL451 at Uppsala University
 * in Sweden.
 *
 * Permission is hereby granted only to the registered students of
 * that course to use this file, for a homework assignment.
 *
 * The copyright notice and permission notice above shall be included
 * in all copies and extensions of this file, and those are not allowed
 * to appear publicly on the internet, both during a course instance
 * and forever after.
 *
 */

include "globals.mzn";

%----Parameters----
int: weeks; % #weeks for the planning
int: types; % #types of spacecraft
% Order[t,w] = #spacecrafts of type t to assemble by end of week w:
array[1..types,1..weeks] of int: Order;
int: storageCost; % cost of storing one spacecraft during one week
% SetupCost[t1,t2] = cost of adapting factory from type t1 to t2:
array[1..types,1..types] of int: SetupCost;

%----Derived parameters----
int: spacecrafts = sum(Order); % total #spacecrafts to assemble

% DueWeek[s] is the week that spacecraft s is due:
array[1..spacecrafts] of int: DueWeek = [ column | column in 1..weeks, row in 1..types, amount in 1..Order[row, column] where Order[row, column] >= 0];
% Type[s] is the type of spacecraft s:
array[1..spacecrafts] of int: Type = [ row | column in 1..weeks, row in 1..types, amount in 1..Order[row, column] where Order[row, column] >= 0];
% Schedule[t, w] is the number of spacecrafts of type t to be built by week w:
array[1..types, 1..weeks] of int: Schedule = array2d(1..types, 1..weeks, [sum(Order[row, 1..column]) | row in 1..types, column in 1..weeks]);

%----Viewpoint 2----

%----Decision variables----
% Spacecraft[s] denotes in which week spacecraft s is built:
array[1..spacecrafts] of var 1..weeks: Spacecraft;
% If a spacecraft is assembled before its due week, it will incur a storage cost (of amount storageCost) for every week that it is not due:
var int: totalStorageCost = sum([ (DueWeek[s] - Spacecraft[s]) * storageCost | s in 1..spacecrafts where Spacecraft[s] < DueWeek[s] ]);

%----Constraints----
constraint all_different(Spacecraft);

% By week w, we have produced at least as many spacecrafts of type t as dictated by the schedule:
constraint forall(s in 1..spacecrafts)(Spacecraft[s] <= DueWeek[s]);

%----Objective----
solve minimize totalStorageCost;

%----Output----
output [show(Spacecraft), "\n"];
output [show(totalStorageCost), "\n"];
