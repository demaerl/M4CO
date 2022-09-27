include "globals.mzn";

%----Parameters----
% enum of companies:
enum Company = {AIMMS, SAS, Keelvar, Microsoft, Google, IBM, Cadence, Quintiq, Siemens, Cosling, COSYTEC, LocalSolver, Nside, UTRCI, Zoomer};
int: companies; % #of companies
int: students; % #of students
% Capacity[c] denotes the interview capacity of company c:
array[1..companies] of int: Capacity;
% Preference[s, c] is the preference of student s to have interview with company c:
array[1..students, 1..companies] of 1..5: Preference;
% Disappointment[c] is disappointment cost of company c if no interview is scheduled:
%array[1..companies] of int: Disappointment;
% Lower[c] is lower bound for # of interviews for company c:
%array[1..companies] of int: Lower;
% Upper[c] is upper bound for # of interviews for company c:
%array[1..companies] of int: Upper;

%----Derived parameters----
% StudentInterview[s] denotes how many interviews student s has:
%array[1..students] of 0..3: StudentInterviews = [ min(sum([Preference[s,c] <= 3 | c in 1..companies]), 3) | s in 1..students];

%----Decision variables----
% Interview[s, c] = 1 iff student s has an interview with company c; 0 otherwise:
array [1..students, 1..companies] of var 0..1: Interview;

var 3*students..15*students: PreferenceSum = sum([Preference[s,c] * Interview[s,c] | s in 1..students, c in 1..companies]);

%----Constraints----
constraint forall(s in 1..students)(sum(Interview[s,..]) = 3);
constraint forall(c in 1..companies)(sum(Interview[..,c]) <= Capacity[c]);


%----Objective----
solve minimize sum([Preference[s,c] * Interview[s,c] | s in 1..students, c in 1..companies]);

%----Output----
output [show(PreferenceSum), "\n"];
output [show(sum(Interview))];
