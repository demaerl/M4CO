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

%----Decision variables----
% Spacecraft[s] denotes in which week spacecraft s is built:
array[1..spacecrafts] of var 1..weeks: Spacecraft;
% Week[w] denotes which type of spacecraft to build in week w:
array[1..weeks] of var 0..types: Week;

% If a spacecraft is assembled before its due week, it will incur a storage cost (of amount storageCost) for every week that it is not due:
var 0..maxStorageCost: totalStorageCost = sum([ (DueWeek[s] - Spacecraft[s]) * storageCost | s in 1..spacecrafts]);
% 
var 0..maxSetupCost: totalSetupCost = sum([ SetupCost[Week[w], Week[w+1]]| w in 1..weeks-1]);

%----Constraints----
% Each spacecraft is built exactly once:
constraint all_different(Spacecraft);
% Ensure that for each spacecraft s, s is assembled in a week before or in the due week:
constraint forall(s in 1..spacecrafts)(Spacecraft[s] <= DueWeek[s]);
% Ensure that for each spacecraft s, the type of s (Type[s]) matches up with the type that is built in the week in which s is built (Week[Spacecraft[s]]):
constraint forall(s in 1..spacecrafts)( Week[Spacecraft[s]] = Type[s]);

%----Objective----
solve minimize totalStorageCost + totalSetupCost;

%----Output----
output [show(totalStorageCost + totalSetupCost)];
