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
% Week[s] denotes in which week spacecraft s is built:
array[1..spacecrafts] of var 1..weeks: Week;
% FactorySetup[w] denotes which type of spacecraft the factory is set up to build in week w.
% FactorySetup is non-mutually redundant with the array of variables Week:
array[1..weeks] of var 1..types: FactorySetup;

% If a spacecraft is assembled before its due week, it will incur a storage cost (of amount storageCost) for every week that it is not due:
var 0..maxStorageCost: totalStorageCost = sum([(DueWeek[s] - Week[s]) * storageCost | s in 1..spacecrafts]);
% If the types of spacecrafts built in two consecutive weeks differ, a setup cost incurs:
var 0..maxSetupCost: totalSetupCost = sum([SetupCost[FactorySetup[w], FactorySetup[w+1]]| w in 1..weeks-1]);

%----Constraints----
% Each spacecraft is built exactly once:
constraint all_different(Week);
% Ensure that for each spacecraft s, s is assembled in a week before or in the due week:
constraint forall(s in 1..spacecrafts)(Week[s] <= DueWeek[s]);
% Ensure that for each spacecraft s, Type[s] matches with the type that the factory is set up to build for the week s is built.
% This is a one-way channelling constraint from the array of variables Week to its redundant array of variables FactorySetup:
constraint forall(s in 1..spacecrafts)(FactorySetup[Week[s]] = Type[s]);

%----Objective----
solve minimize totalStorageCost + totalSetupCost;

%----Output----
output [show(totalStorageCost + totalSetupCost)];
