include "globals.mzn";

%----Parameters----
% enum of companies:
enum Company = {AIMMS, SAS, Keelvar, Microsoft, Google, IBM, Cadence, Quintiq, Siemens, Cosling, COSYTEC, LocalSolver, Nside, UTRCI, Zoomer};
int: companies; % #of companies
int: students; % #of students
% Capacity[c] denotes the interview capacity of company c:
%array[1..companies] of int: Capacity;
% Preference[s, c] is the preference of student s to have interview with company c:
array[1..students, 1..companies] of 1..5: Preference;
% Disappointment[c] is disappointment cost of company c if no interview is scheduled:
array[1..companies] of int: Disappointment;
% Lower[c] is lower bound for # of interviews for company c:
array[1..companies] of int: Lower;
% Upper[c] is upper bound for # of interviews for company c:
array[1..companies] of int: Upper;
% IncurredDisappointment[c] denotes the actual disappointment of company c:
array[1..companies] of var 0..max(Disappointment): IncurredDisappointment;

%----Derived parameters----
% StudentInterview[s] denotes how many interviews student s has:
array[1..students] of 0..3: StudentInterviews = [ min(sum([Preference[s,c] <= 3 | c in 1..companies]), 3) | s in 1..students];

%----Decision variables----
% Interview[s, c] = 1 iff student s has an interview with company c; 0 otherwise:
array[1..students, 1..companies] of var 0..1: Interview;
array[1..students, 1..companies] of var 1..5: SortedPreference;
%array[1..students] of var 0..9: IdealPreference = [ [arg_sort(Preference[s,..])[1..3] | s in 1..students ] |  ]
% AssignedPreference[s] is the sum of the preferences of the interviews assigned to student s:
array[1..students] of var 0..9: AssignedPreference = [ sum([Interview[s,c]*Preference[s,c] | c in 1..companies]) | s in 1..students];
% Regret[s] denotes the regret, i.e. the difference between best indicated preferences and assigned preferences:
array[1..students] of var 0..6: Regret = [ AssignedPreference[s] - sum([ SortedPreference[s,i] | i in 1..3 where SortedPreference[s,i] < 4]) | s in 1..students];
% Total preference cost:
var 3*students..15*students: totalPreferenceCost = sum([Preference[s,c] * Interview[s,c] | s in 1..students, c in 1..companies]);


%----Constraints----
% Ensure that amount of interviews of company c is either 0 or inside bounds:
constraint forall(c in 1..companies)(sum(Interview[..,c]) in Lower[c]..Upper[c] union {0});
% Ensure that each student has the correct number of interviews:
constraint forall(s in 1..students)(sum(Interview[s,..]) = StudentInterviews[s]);
% Ensure that each student has interviews with companies according to Preference:
constraint forall(s in 1..students, c in 1..companies where Interview[s,c] = 1)(Preference[s,c] <= 3);
% If no interview is scheduled for company c, a disappointment cost is incurred:
constraint forall(c in 1..companies where sum(Interview[..,c]) = 0)(IncurredDisappointment[c] = Disappointment[c]);

constraint forall(s in 1..students)(sort(Preference[s,..], SortedPreference[s,..]));

%---Calculations----
var 0..sum(Disappointment): totalDisappointment = sum(IncurredDisappointment);


%----Objective----
% minimize max regret:
solve minimize max(Regret);
% Day 2: secondary objective:
%solve minimize totalPreferenceCost;

%----Output----
%output [show(Regret), "\n"];
%output [show(AssignedPreference), "\n"];
%output [show(sum(Interview))];
