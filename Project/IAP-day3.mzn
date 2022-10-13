include "globals.mzn";

%%% ------ Parameters and derived parameters ------
% weights for the objective function
int: alpha = students * 15 * beta;
int: beta = sum(Disappointment);
int: gamma = 1;

% enum of companies:
enum Company = {AIMMS, SAS, Keelvar, Microsoft, Google, IBM, Cadence, Quintiq, Siemens, Cosling, COSYTEC, LocalSolver, Nside, UTRCI, Zoomer};
int: companies; % #of companies
int: students; % #of students
int: days = 5;
int: suites = 12;
int: slots = 20;
% Capacity[c] denotes the interview capacity of company c:
%array[1..companies] of int: Capacity;
% Preference[s, c] is the preference of student s to have interview with company c:
array[1..students, 1..companies] of 1..5: Preference;
% Slot[i, s] is the i-th slot where student s is available:
array[1..5, 1..students] of 1..20: Slot;
% Disappointment[c] is disappointment cost of company c if no interview is scheduled:
array[1..companies] of int: Disappointment;
% Lower[c] is lower bound for # of interviews for company c:
array[1..companies] of int: Lower;
% Upper[c] is upper bound for # of interviews for company c:
array[1..companies] of int: Upper;
% DailyRate[c] is the daily conference attendance cost for company c:
array[1..companies] of int: DailyRate;

% StudentInterview[s] denotes how many interviews student s has:
array[1..students] of 0..3: StudentInterviews = [ min(sum([Preference[s,c] <= 3 | c in 1..companies]), 3) | s in 1..students];

%%% ------ Variables and constraints ------

%% ------ Interview assignments ------

% Interview[s, c] = 1 iff student s has an interview with company c; 0 otherwise:
array[1..students, 1..companies] of var 0..1: Interview;

% Ensure that amount of interviews of company c is either 0 or inside bounds:
constraint forall(c in 1..companies)(sum(Interview[..,c]) in Lower[c]..Upper[c] union {0});
% Ensure that each student has the correct number of interviews:
constraint forall(s in 1..students)(sum(Interview[s,..]) = StudentInterviews[s]);
% Ensure that each student has interviews with companies according to Preference:
constraint forall(s in 1..students, c in 1..companies where Preference[s,c] >= 4)(Interview[s,c] = 0);

%% ------ Preference cost ------

% Total preference cost:
var 3*students..15*students: totalPreferenceCost = sum([Preference[s,c] * Interview[s,c] | s in 1..students, c in 1..companies]);

%% ------ Day 2: Student regret ------

% PreferenceCount[s, p] is the number of times (up to 3) student s expressed preference p, with 1 <= p <= 3: 
array[1..students, 1..3] of 0..3: PrefCount = array2d(1..students, 1..3, [min(count(Preference[s, ..], p), 3) | s in 1..students, p in 1..3]);
% IdealPrefCost[s] is for student s the sum of their three best preferences that are 3 or better:
array[1..students] of 0..9: IdealPrefCost = [ PrefCount[s, 1] +
					     2*min(3-PrefCount[s, 1], PrefCount[s, 2]) +
					     3*min( max(3-PrefCount[s, 1]-PrefCount[s,2], 0), PrefCount[s, 3])
					     | s in 1..students];
% AssignedPreference[s] is the sum of the preferences of the interviews assigned to student s:
array[1..students] of var 0..9: AssignedPreference = [ sum([Interview[s,c]*Preference[s,c] | c in 1..companies]) | s in 1..students];
% Regret[s] denotes the regret, i.e. the difference between best indicated preferences and assigned preferences:
array[1..students] of var 0..6: Regret = [AssignedPreference[s] - IdealPrefCost[s] | s in 1..students];
% The maximum regret of any student
var 0..6: maxRegret :: add_to_output = max(Regret);


%% ------ Day 2: Company disappointment ------

% IncurredDisappointment[c] denotes the actual disappointment of company c:
array[1..companies] of var 0..max(Disappointment): IncurredDisappointment;

% If no interview is scheduled for company c, a disappointment cost is incurred:
constraint forall(c in 1..companies where sum(Interview[..,c]) = 0)(IncurredDisappointment[c] = Disappointment[c]);

% Calculate the total disappointment:
var 0..sum(Disappointment): totalDisappointment = sum(IncurredDisappointment);

%% ------ Day 3------

% TODO: Decide if redundant variables and/or channelling

% StudentSchedule[sl, su] denotes the student that has an interview in slot sl, and in suite su:
array[1..slots, 1..suites] of var 0..students: StudentSchedule; % non-mutually redundant with Schedule:
% CompanySchedule[sl, su] denotes the company that has an interview in slot sl, and in suite su:
array[1..slots, 1..suites] of var 0..companies: CompanySchedule; % non-mutually redundant with Schedule:
% Schedule[sl, d, su, st] denotes with which company (if any) student st has an interview in slot sl on day d in suite su:
array[1..slots, 1..suites, 1..students] of var 0..companies: Schedule;
% array[1..students] of var set of int: StudentSuites;
% Ensure that interviews are scheduled according to availability of students as indicated in Slot:
% constraint forall(sl in 1..slots, su in 1..suites where StudentSchedule[sl, su] != 0)(count(Slot[..,StudentSchedule[sl,su]], sl) = 1);
constraint forall(sl in 1..slots, su in 1..suites, st in 1..students where Schedule[sl, su, st] != 0)(count(Slot[..,st], sl) = 1);
% 1-way channelling constraint from Schedule to StudentSchedule:
constraint forall(sl in 1..slots, su in 1..suites, st in 1..students where Schedule[sl,su, st] != 0)(StudentSchedule[sl, su] = st);
% 1-way channelling constraint from Schedule to CompanySchedule:
constraint forall(sl in 1..slots, su in 1..suites, st in 1..students where Schedule[sl, su, st] != 0)(CompanySchedule[sl, su] = Schedule[sl, su, st]);
% If no student has an interview in slot sl, on day d, and in suite su, then no company has an interview in slot sl, on day d, and in suite su:
% constraint forall(sl in 1..slots, d in 1..days, su in 1..suites)(StudentSchedule[sl, d, su] = 0 <-> CompanySchedule[sl, d, su] = 0);
% Ensure that at most one interview is held in each suite during one slot:
constraint forall(sl in 1..slots, su in 1..suites)(count(Schedule[sl, su,..], 0) >= students-1);
% Ensure that for each slot sl in the schedule, the company and student on day d in suite su have an interview scheduled according to Interview:
constraint forall(sl in 1..slots, d in 1..days, su in 1..suites where StudentSchedule[sl, su] != 0)(Interview[StudentSchedule[sl, su], CompanySchedule[sl, su]] = 1);
% Ensure that if an interview of student st with company c is scheduled according to Interview, the interview takes place once in Schedule:
constraint forall(st in 1..students, c in 1..companies)(Interview[st, c] = 1 <-> count(Schedule[.., .. , st], c) = 1);
% TODO: Fix
% constraint forall(c in 1..companies)(global_cardinality(global_cardinality(), 1..students, Interview[..,c]))

% Ensure that each student only has at most one interview during one slot:
constraint forall(sl in 1..slots)(global_cardinality_low_up(StudentSchedule[sl, ..], 1..students, [0 | i in 1..students], [1 | i in 1..students]));
% Ensure that each company has up to two interviews during one slot:
constraint forall(sl in 1..slots)(global_cardinality_low_up(CompanySchedule[sl, ..], 1..companies, [0 | i in 1..companies], [2 | i in 1..companies]));

constraint maxRegret = 1;
constraint totalDisappointment = 0;

%% Symmetry Breaking
% Make sure that suite s is used before suite s+1:
constraint symmetry_breaking_constraint(forall(sl in 1..slots, su in 1..suites-1)((StudentSchedule[sl,su] = 0 /\ StudentSchedule[sl,su+1] = 0) \/ (StudentSchedule[sl,su] > 0 /\ StudentSchedule[sl,su+1] >= 0)));
% Make sure that the student in suite su has a higher identifier than the student in suite su+1
constraint symmetry_breaking_constraint(forall(sl in 1..slots)(decreasing(StudentSchedule[sl,..])));

%% Preference

%% Company attendance cost
% Attendance[c] denotes the number of days company c attends the conference:
%array[1..companies] of var 0..5: Attendance;
%array[1..companies] of var 0..20: CompanyFirstSlot;
%array[1..companies] of var 0..20: CompanyLastSlot;
%constraint forall(c in 1..companies)(not(c in CompanySchedule[1..CompanyFirstSlot[c]-1,..]));
%constraint forall(c in 1..companies)();
%array[1..companies] of var 0..5*max(DailyRate): AttendanceCost;

array[1..suites] of var {0,200}: SuiteRentalCost; % suite rental cost
% For each suite where an interview is scheduled in (according to StudentSchedule), the rental coste is incurred for that suite:
constraint forall(su in 1..suites where count(StudentSchedule[..,su], 0) < slots)(SuiteRentalCost[su] = 200);

var 0..2400: totalRentalCost = sum(SuiteRentalCost); % total suite rental cost

var int: obj = totalPreferenceCost + totalRentalCost;

%----Objective----
% Day 3: minimize max regret:, total preference cost and total disappointment:
solve minimize obj;
% Day 2: secondary objective:
%solve minimize totalPreferenceCost;

%----Output----
output [show(max(Regret)), "\n"];
output [show(totalPreferenceCost), "\n"];
output [show(totalDisappointment)];
