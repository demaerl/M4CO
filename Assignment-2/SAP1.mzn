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
% The maximal possible setup cost, used to tighten the domain of totalSetupCost:
int: maxSetupCost = weeks * max(SetupCost);
% The maximal possible storage cost, used to tighten the domain of totalStorageCost:
int: maxStorageCost = (weeks*(weeks-1))*storageCost div 2;
% DueWeek[s] is the week that spacecraft s is due:
array[1..spacecrafts] of int: DueWeek = [ w | t in 1..types, w in 1..weeks, amount in 1..Order[t, w] where Order[t, w] >= 0];
% Type[s] is the type of spacecraft s:
array[1..spacecrafts] of int: Type = [ t | t in 1..types, w in 1..weeks, amount in 1..Order[t, w] where Order[t, w] >= 0];

%----Decision variables----

% Spacecraft[w] denotes which spacecraft (if any) to build in week w:
% 0 is used as dummy value. Therefore, Spacecraft[w] = 0 denotes that no spacecraft is built in week w.
array[1..weeks] of var 0..spacecrafts: Spacecraft;
% FactorySetup[w] denotes which type of spacecraft to build in week w.
% FactorySetup is non-mutually redundant with the array of variables Spacecraft:
array[1..weeks] of var 1..types: FactorySetup;
% If a spacecraft is assembled before its due week, a storageCost for every week it is not due incurs.
% Weeks where no spacecraft is assembled (i.e. Spacecraft[w] = 0) are ignored:
var 0..maxStorageCost: totalStorageCost = sum([(DueWeek[Spacecraft[w]] - w) * storageCost | w in 1..weeks where Spacecraft[w] != 0]);
% If the types of spacecrafts built in two consecutive weeks differ, a setup cost incurs:
var 0..maxSetupCost: totalSetupCost = sum([SetupCost[FactorySetup[w], FactorySetup[w+1]] | w in 1..weeks-1 ]);

%----Constraints----
% Ensure that each spacecraft is built either before it is due or in the week it is due:
constraint forall(w in 1..weeks where Spacecraft[w] != 0)(DueWeek[Spacecraft[w]] >= w);
% Ensure that each spacecraft is built (and not more than once):
constraint global_cardinality(Spacecraft, 1..spacecrafts, [ 1 | s in 1..spacecrafts]);
% Ensure that the type of spacecraft built in week w (if any) according to Spacecraft matches with the type according to WeekType.
% This is a two-way channeling constraint: 
constraint forall(w in 1..weeks where Spacecraft[w] != 0)(Type[Spacecraft[w]] = FactorySetup[w]);

%----Objective----
% Minimize the total cost, consisting of totalStorageCost and totalSetupCost:
solve minimize totalStorageCost + totalSetupCost;

%----Output----
output [show(totalStorageCost + totalSetupCost)];
