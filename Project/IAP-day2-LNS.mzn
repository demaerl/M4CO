include "globals.mzn";
include "gecode.mzn";

%%% ------ Parameters and derived parameters ------
% weights for the objective function
int: alpha = students * 15 * gamma;
int: beta = 1;
int: gamma = sum(Disappointment);

% Parameters for the LNS
int: rho = 0;
int: sigma = 80;

% enum of companies:
enum Company = {AIMMS, SAS, Keelvar, Microsoft, Google, IBM, Cadence, Quintiq, Siemens, Cosling, COSYTEC, LocalSolver, Nside, UTRCI, Zoomer};
int: companies; % #of companies
int: students; % #of students
% Preference[s, c] is the preference of student s to have interview with company c:
array[1..students, 1..companies] of 1..5: Preference;
% Disappointment[c] is disappointment cost of company c if no interview is scheduled:
array[1..companies] of int: Disappointment;
% Lower[c] is lower bound for # of interviews for company c:
array[1..companies] of int: Lower;
% Upper[c] is upper bound for # of interviews for company c:
array[1..companies] of int: Upper;

% StudentInterview[s] denotes how many interviews student s has:
array[1..students] of 0..3: StudentInterviews = [ min(sum([Preference[s,c] <= 3 | c in 1..companies]), 3) | s in 1..students];

%%% ------ Variables and constraints ------

%% ------ Interview assignments ------

% Interview[s, c] = 1 iff student s has an interview with company c; 0 otherwise:
array[1..students, 1..companies] of var 0..1: Interview;
% 1D version of interview for the LNS, each 15 elements correspond to a row in Interview
array[1..students*companies] of var 0..1: InterviewFlat = [ Interview[s, c] | s in 1..students, c in 1..companies ];

% Ensure that amount of interviews of company c is either 0 or inside bounds:
constraint forall(c in 1..companies)(sum(Interview[..,c]) in Lower[c]..Upper[c] union {0});
% Ensure that each student has the correct number of interviews:
constraint forall(s in 1..students)(sum(Interview[s,..]) = StudentInterviews[s]);
% Ensure that each student has interviews with companies according to Preference:
constraint forall(s in 1..students, c in 1..companies where Preference[s,c] >= 4)(Interview[s,c] = 0);

%% ------ Preference cost ------

% Total preference cost:
var 3*students..15*students: totalPreferenceCost :: add_to_output= sum([Preference[s,c] * Interview[s,c] | s in 1..students, c in 1..companies]);

%% ------ Day 2: Student regret ------

% PreferenceCount[s, p] is the number of times (up to 3) student s expressed preference p, with 1 <= p <= 3: 
array[1..students, 1..3] of 0..3: PrefCount = array2d(1..students, 1..3, [min(count(Preference[s, ..], p), 3) | s in 1..students, p in 1..3]);
% IdealPrefCost[s] is for student s the sum of their three best preferences that are 3 or better:
array[1..students] of 0..9: IdealPrefCost = [ PrefCount[s, 1] +
					     2*min(3-PrefCount[s, 1], PrefCount[s, 2]) +
					     3*min( max(3-PrefCount[s, 1]-PrefCount[s,2], 0), PrefCount[s, 3])
					     | s in 1..students];
% AssignedPreference[s] is the sum of the preferences of the interviews assigned to student s.
% AssignedPreference is non-mutually redundant with Interview:
array[1..students] of var 0..9: AssignedPreference = [ sum([Interview[s,c]*Preference[s,c] | c in 1..companies]) | s in 1..students];
% Regret[s] denotes the regret, i.e. the difference between best indicated preferences and assigned preferences.
% Regret is mutually redundant with AssignedPreference:
array[1..students] of var 0..6: Regret = [AssignedPreference[s] - IdealPrefCost[s] | s in 1..students];
% The maximum regret of any student
var 0..6: maxRegret :: add_to_output = max(Regret);


%% ------ Day 2: Company disappointment ------

% IncurredDisappointment[c] denotes the actual disappointment of company c:
array[1..companies] of var 0..max(Disappointment): IncurredDisappointment;

% If no interview is scheduled for company c, a disappointment cost is incurred:
constraint forall(c in 1..companies where sum(Interview[..,c]) = 0)(IncurredDisappointment[c] = Disappointment[c]);

% Calculate the total disappointment:
var 0..sum(Disappointment): totalDisappointment :: add_to_output = sum(IncurredDisappointment);


%----Objective----
% Day 2: Objective is weighted sum of regret, total student preference cost, and total company disappointment:
var int: obj = alpha * max(Regret) + beta * totalPreferenceCost + gamma * totalDisappointment;

solve
:: restart_constant(rho)
:: relax_and_reconstruct(InterviewFlat, sigma)
minimize obj; % minimize objective
