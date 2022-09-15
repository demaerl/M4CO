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
% the maximal possible setup cost, used to tighten the domains for totalSetupCost:
int: maxSetupCost = weeks * max(SetupCost);
% the maximal possible storage cost, used to tighten the domains of totalStorageCost:
int: maxStorageCost = (weeks*(weeks-1))*storageCost div 2;

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
% TypeSorted[i] denotes the type of the i'th (i.e. 1st, 2nd, 3d, 4th, etc.) spacecraft to be built, or in other words:
% Arrange Type such that the spacecrafts in SortedType are in chronological order of their assembly:
array[1..spacecrafts] of var 1..types: TypeSorted = [Type[s] | s in arg_sort(Spacecraft)];
% If a spacecraft is assembled before its due week, it will incur a storage cost (of amount storageCost) for every week that it is not due:
var 0..maxStorageCost: totalStorageCost = sum([ (DueWeek[s] - Spacecraft[s]) * storageCost | s in 1..spacecrafts where Spacecraft[s] < DueWeek[s] ]);
% 
var 0..maxSetupCost: totalSetupCost = sum([ SetupCost[TypeSorted[s], TypeSorted[s+1]]| s in 1..spacecrafts-1]);

%----Constraints----
constraint all_different(Spacecraft);

% By week w, we have produced at least as many spacecrafts of type t as dictated by the schedule:
constraint forall(s in 1..spacecrafts)(Spacecraft[s] <= DueWeek[s]);

%----Objective----
solve minimize totalStorageCost + totalSetupCost;

%----Output----
%output [show(Spacecraft), "\n"];
%output [show(totalStorageCost), "\n"];
%output [show(SortedType)];
output [show(totalStorageCost + totalSetupCost)];
