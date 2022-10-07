/*
 *
 * Copyright: Gustav.Bjordal@it.uu.se and Pierre.Flener@it.uu.se, 2022.
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

%%% ------ Parameters and derived parameters ------

int: nScooters;   % number of scooters
int: nEmployees;  % number of employees
int: dummy;       % dummy employee        
constraint assert(not (dummy in 1..nEmployees), "Dummy is not an employee");
int: nNodes = nScooters + 2*nEmployees;  % number of nodes: each employee has start and end locations

% Some of the following sets may be unnecessary and you may want to add more sets:
set of int: Scooters = 1..nScooters;
set of int: Employees = 1..nEmployees;
set of int: EmployeesAndDummy = 1..nEmployees union {dummy};
set of int: Nodes = 1..nNodes;

% TravelTime[f,t] = estimated time of travelling from f to t and servicing the scooter at t, if any:
array[Nodes, Nodes] of int: TravelTime;
% Priority[s] = priority of some employee servicing s:
array[Scooters] of int: Priority;
% Payment[s] = payment any employee would receive for servicing s:
array[Scooters] of int: Payment;   
% StartNode[e] = start node of e:
array[Employees] of int: StartNode = [n | n in (nScooters+1)..(nScooters+nEmployees)];
% EndNode[e] = end node of e:
array[Employees] of int: EndNode = [n | n in (nScooters+nEmployees+1)..(nScooters+nEmployees+nEmployees)]; 
% MinNumScooters[e] = minimum number of scooters e is willing to service:
array[Employees] of int: MinNumScooters;
% MaxNumScooters[e] = maximum number of scooters e is willing to service:
array[Employees] of int: MaxNumScooters;
% MaxTime[e] = preferred maximum total travel time of e:
array[Employees] of int: MaxTime;

int: alpha;  % weight in the objective function of the total overtime
int: beta;   % weight in the objective function of the total payment
int: gamma;  % weight in the objective function of the total priority loss

%%% ------ Variables and constraints ------

%% ------ Giant-tour formulation ------

array[Nodes] of var Nodes: Succ;  % Succ[n] is the successor node of node n
constraint subcircuit(Succ) :: domain;

% Ensure that the successor of each employee's end node is the start node of the circularly next employee:
constraint global_cardinality([Succ[EndNode[e]] | e in Employees], StartNode, [1 | e in Employees]);

%% ------ Which node is visited by which employee (according to the tour) ------

% Each node is visited by an employee, or by the dummy employee if nobody visits it:
array[Nodes] of var EmployeesAndDummy: VisitedBy;  % non-mutually redundant with Succ

% Each StartNode[e] is visited by e, and each EndNode[e] is visited by e:
constraint forall(e in Employees)(VisitedBy[StartNode[e]] = e /\ VisitedBy[EndNode[e]] = e);

% 1-way channelling constraint from Succ to its redundant array of vars VisitedBy:
% The successor of each scooter node n is visited by the same employee as n, even if it is the end node:
constraint forall(s in Scooters)(VisitedBy[s] = VisitedBy[Succ[s]]);

% 1-way channelling constraint from Succ to its redundant array of vars VisitedBy:
% The successor of each start node n is visited by that employee n, even if it is the end node:
constraint forall(n in StartNode)(VisitedBy[n] = VisitedBy[Succ[n]]);

% 2-way channelling constraint between Succ and its redundant array of vars VisitedBy:
% The successor of each scooter node n is n if and only if node n is visited by the dummy employee:
constraint forall(s in Scooters)(Succ[s] = s <-> VisitedBy[s] = dummy);

%% ------ Number of scooters serviced by each employee ------

% NumServiced[e] = number of scooters serviced by e:
array[Employees] of var 0..nScooters: NumServiced;  % non-mutually redundant with VisitedBy

% 1-way channelling constraint from VisitedBy to its redundant array of vars NumServiced:
% NumServiced[e] is the number of scooters serviced by e:
constraint global_cardinality(VisitedBy[Scooters], Employees, NumServiced);

% Each employee e services either 0 or from MinNumScooters[e] to MaxNumScooters[e] scooters:
constraint forall(e in Employees)(NumServiced[e] in MinNumScooters[e]..MaxNumScooters[e] union {0});

%% ------ Overtime cost ------

% AccumulatedTravelTime[n] = travel time accumulated when arriving at n since its employee e departed from the start node of e:
array[Nodes] of var 0..sum(TravelTime): AccumulatedTravelTime;  % non-mutually redundant with Succ

% 1-way channelling constraint from Succ to its redundant array of vars AccumulatedTravelTime:
% For two successive nodes n1 and n2 on an employee's route, the difference of accumulated travel time of node n1 and n2 corresponds to the travel time between n1 and n2:
constraint forall(n in Nodes where VisitedBy[n] = VisitedBy[Succ[n]] /\ n != EndNode[VisitedBy[n]])(AccumulatedTravelTime[n] + TravelTime[n, Succ[n]] = AccumulatedTravelTime[Succ[n]]);
% Each start node has an accumulated travel time of 0:
constraint forall(n in StartNode)(AccumulatedTravelTime[n] = 0);

% Overtime[e] = amount of travel time of e that exceeds MaxTime[e]:
array[Employees] of var 0..sum(TravelTime): Overtime;  % non-mutually redundant with AccumulatedTravelTime

% 1-way channelling constraint from AccumulatedTravelTime to its redundant array of vars Overtime:
% Overtime[e] is either 0 or the difference between the actual (accumulated) travel time and the preferred travel time of employee e:
constraint forall(e in Employees)(Overtime[e] = max(AccumulatedTravelTime[EndNode[e]] - MaxTime[e],0));

var 0..sum(TravelTime): totalOvertime = sum(Overtime);  % total overtime of all the employees

%% ------ Employee payment ------

% EmployeePayment[e] = payment to employee (or dummy) e for all scooters serviced by e:
array[EmployeesAndDummy] of var 0..sum(Payment): EmployeePayment;  % non-mutually redundant with VisitedBy
% Note that we only include the dummy employee here so that the indexing matches the domain of VisitedBy (in case this were useful for a global constraint).

% 1-way channelling constraint from VisitedBy to its redundant array of vars EmployeePayment:
% Ensure that each employee (except for the dummy employee) gets payment for each scooter that the employee services:
constraint forall(e in Employees)(sum(s in Scooters)((VisitedBy[s] = e)*Payment[s]) = EmployeePayment[e]);

var 0..sum(Payment): totalPayment = sum(EmployeePayment[Employees]);  % total payment that all the employees receive

%% ------ Priority loss ------

var 0..sum(Priority): totalPriorityLoss;  % total priority of all scooters not serviced by anyone

% The total priority loss consists of the sum of the priorities of all scooters that are visited by the dummy employee:
constraint sum(s in Scooters where VisitedBy[s] = dummy)(Priority[s]) = totalPriorityLoss;

%% ------ Objective ------

var int: obj;  % objective variable
constraint obj = alpha*totalOvertime - beta*totalPayment + gamma*totalPriorityLoss;

% include "gecode.mzn";  % only for Task B
solve
:: int_search(Overtime, first_fail, indomain_min)
minimize obj;
