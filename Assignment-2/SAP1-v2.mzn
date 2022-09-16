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
array[1..spacecrafts] of int: DueWeek = [ w | t in 1..types, w in 1..weeks, amount in 1..Order[t, w] where Order[t, w] >= 0];
% Type[s] is the type of spacecraft s:
array[1..spacecrafts] of int: Type = [ t | t in 1..types, w in 1..weeks, amount in 1..Order[t, w] where Order[t, w] >= 0];
% Schedule[t, w] is the number of spacecrafts of type t to be built by week w:
% array[1..types, 1..weeks] of int: Schedule = array2d(1..types, 1..weeks, [sum(Order[row, 1..column]) | row in 1..types, column in 1..weeks]);

%----Viewpoint 1----

%----Decision variables----

% Spacecraft[w] denotes which spacecraft (if any) to build in week w:
% 0 is used as dummy value. Therefore, Spacecraft[w] = 0 denotes that no spacecraft is built in week w.
array[1..weeks] of var 0..spacecrafts: Spacecraft;
% WeekTyped[w] denotes which type of spacecraft to build in week w:
array[1..weeks] of var 0..types: WeekType;
% If a spacecraft is assembled before its due week, a storageCost for every week it is not due incurs.
% Weeks where no spacecraft is assembled (i.e. Spacecraft[w] = 0) are ignored.
var 0..maxStorageCost: totalStorageCost = sum([(DueWeek[Spacecraft[w]] - w) * storageCost | w in 1..weeks where Spacecraft[w] != 0]);

var 0..maxSetupCost: totalSetupCost = sum([SetupCost[WeekType[w], WeekType[w+1]] | w in 1..weeks-1 ]);

%----Constraints----
% Ensure that each spacecraft is built either before it is due or in the week it is due:
constraint forall(w in 1..weeks where Spacecraft[w] != 0)(DueWeek[Spacecraft[w]] >= w);
% Ensure that each spacecraft is built (and not more than once):
constraint forall(s in 1..spacecrafts)(count(Spacecraft, s) = 1);
% Ensure that the type of spacecraft built in week w according to Spacecraft matches up with the type according to WeekType.
% In a week where no spacecraft is assembled (i.e. Spacecraft[w] = 0), it is irrelevant which value WeekType takes at index w. 
constraint forall(w in 1..weeks where Spacecraft[w] != 0)(Type[Spacecraft[w]] = WeekType[w]);

%----Objective----
%solve minimize totalStorageCost;
solve minimize totalStorageCost + totalSetupCost;

%----Output----
output [show2d(Order), "\n"];
output [show(Type), "\n"];
output [show(Spacecraft), "\n"];
output [show(WeekType), "\n"];
output [show(totalStorageCost + totalSetupCost)];
