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
constraint forall(i in 1..nEmployees)(exists(j in 1..nEmployees)(Succ[EndNode[i]] = StartNode[j]));

%% ------ Which node is visited by which employee (according to the tour) ------

% Each node is visited by an employee, or by the dummy employee if nobody visits it:
array[Nodes] of var EmployeesAndDummy: VisitedBy;  % non-mutually redundant with Succ

% [specify whether 1-way or 2-way] Channelling constraint: each StartNode[e] is visited by e, and each EndNode[e] is visited by e:
constraint ...;

% [specify whether 1-way or 2-way] Channelling constraint: the successor of each scooter node n is visited by the same employee as n, even if it is the end node:
constraint ...;

% [specify whether 1-way or 2-way] Channelling constraint: the successor of each start node n is visited by that employee n, even if it is the end node:
constraint ...;

% [specify whether 1-way or 2-way] Channelling constraint: the successor of each scooter node n is n if and only if node n is visited by the dummy employee:
constraint ...;

%% ------ Number of scooters serviced by each employee ------

% NumServiced[e] = number of scooters serviced by e:
array[Employees] of var 0..nScooters: NumServiced;  % non-mutually redundant with VisitedBy

% [specify whether 1-way or 2-way] Channelling constraint: NumServiced[e] is the number of scooters serviced by e:
constraint ...;

% Each employee e services either 0 or from MinNumScooters[e] to MaxNumScooters[e] scooters:
constraint ...;

%% ------ Overtime cost ------

% AccumulatedTravelTime[n] = travel time accumulated when arriving at n since its employee e departed from the start node of e:
array[Nodes] of var 0..sum(TravelTime): AccumulatedTravelTime;  % non-mutually redundant with Succ

% [specify whether 1-way or 2-way] Channelling constraint: ...:
constraint ...;

% Overtime[e] = amount of travel time of e that exceeds MaxTime[e]:
array[Employees] of var 0..sum(TravelTime): Overtime;  % non-mutually redundant with AccumulatedTravelTime

% [specify whether 1-way or 2-way] Channelling constraint: ...:
constraint ...;

var 0..sum(TravelTime): totalOvertime;  % total overtime of all the employees

constraint ...;  % ...

%% ------ Employee payment ------

% EmployeePayment[e] = payment to employee (or dummy) e for all scooters serviced by e:
array[EmployeesAndDummy] of var 0..sum(Payment): EmployeePayment;  % non-mutually redundant with VisitedBy
% Note that we only include the dummy employee here so that the indexing matches the domain of VisitedBy (in case this were useful for a global constraint).

% [specify whether 1-way or 2-way] Channelling constraint: ...:
constraint ...;

var 0..sum(Payment): totalPayment;  % total payment that all the employees receive

constraint ...;  % ...

%% ------ Priority loss ------

var 0..sum(Priority): totalPriorityLoss;  % total priority of all scooters not serviced by anyone

constraint ...;  % ...

%% ------ Objective ------

var int: obj;  % objective variable
constraint obj = alpha*totalOvertime - beta*totalPayment + gamma*totalPriorityLoss;

% include "gecode.mzn";  % only for Task B
solve
% :: restart_constant(%rho%)               % only for Task B: use only together with relax_and_reconstruct
% :: relax_and_reconstruct(Succ, %sigma%)  % only for Task B: requires including "gecode.mzn", but it will then only run on Gecode
% :: seq_search([ ... ])
minimize obj;