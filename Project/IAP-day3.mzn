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
int: slots = 4;
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
constraint forall(s in 1..students, c in 1..companies where Interview[s,c] = 1)(Preference[s,c] <= 3);

%% ------ Preference cost ------

% Total preference cost:
var 3*students..15*students: totalPreferenceCost = sum([Preference[s,c] * Interview[s,c] | s in 1..students, c in 1..companies]);

%% ------ Day 2: Student regret ------

% SortedPreference denotes the preferences of each student in sorted order: 
array[1..students, 1..companies] of var 1..5: SortedPreference;
% AssignedPreference[s] is the sum of the preferences of the interviews assigned to student s:
array[1..students] of var 0..9: AssignedPreference = [ sum([Interview[s,c]*Preference[s,c] | c in 1..companies]) | s in 1..students];
% Regret[s] denotes the regret, i.e. the difference between best indicated preferences and assigned preferences:
array[1..students] of var 0..6: Regret = [ AssignedPreference[s] - sum([ SortedPreference[s,i] | i in 1..3 where SortedPreference[s,i] < 4]) | s in 1..students];
% Sort preferences of students in ascending order:
constraint forall(s in 1..students)(sort(Preference[s,..], SortedPreference[s,..]));

var 0..6: maxRegret = max(Regret);


%% ------ Day 2: Company disappointment ------

% IncurredDisappointment[c] denotes the actual disappointment of company c:
array[1..companies] of var 0..max(Disappointment): IncurredDisappointment;

% If no interview is scheduled for company c, a disappointment cost is incurred:
constraint forall(c in 1..companies where sum(Interview[..,c]) = 0)(IncurredDisappointment[c] = Disappointment[c]);

% Calculate the total disappointment:
var 0..sum(Disappointment): totalDisappointment = sum(IncurredDisappointment);

var int: obj = alpha * max(Regret) + beta * totalPreferenceCost + gamma * totalDisappointment;

%% ------ Day 3------

% TODO: Decide if redundant variables and/or channelling
% TODO: Replace slots, days with slots of range 1..20

% StudentSchedule[sl, d , su] denotes the student that has an interview in slot sl, on day d, and in suite su:
% Non-mutually redundant with Schedule:
array[1..slots, 1..days, 1..suites] of var 0..students: StudentSchedule;
% CompanySchedule[sl, d , su] denotes the company that has an interview in slot sl, on day d, and in suite su:
% Non-mutually redundant with Schedule:
array[1..slots, 1..days, 1..suites] of var 0..companies: CompanySchedule;
% Schedule[sl, d, su, st] denotes with which company (if any) student st has an interview in slot sl on day d in suite su:
array[1..slots, 1..days, 1..suites, 1..students] of var 0..companies: Schedule;
% Ensure that interviews are scheduled according to availability of students as indicated in Slot:
%constraint forall(sl in 1..slots, su in 1..suites, st in 1..students where Schedule[sl, su, st] != 0)(count(Slot[..,st], sl) = 1);
% 1-way channelling constraint from Schedule to StudentSchedule:
constraint forall(sl in 1..slots, d in 1..days, su in 1..suites, st in 1..students where Schedule[sl, d, su, st] != 0)(StudentSchedule[sl, d, su] = st);
% 1-way channelling constraint from Schedule to CompanySchedule:
constraint forall(sl in 1..slots, d in 1..days, su in 1..suites, st in 1..students where Schedule[sl, d, su, st] != 0)(CompanySchedule[sl, d, su] = Schedule[sl, d, su, st]);
% If no student has an interview in slot sl, on day d, and in suite su, then no company has an interview in slot sl, on day d, and in suite su:
% constraint forall(sl in 1..slots, d in 1..days, su in 1..suites)(StudentSchedule[sl, d, su] = 0 <-> CompanySchedule[sl, d, su] = 0);
% Ensure that at most one interview is held in each suite during one slot:
%constraint forall(sl in 1..slots, su in 1..suites)(count(Schedule[sl, su,..], 0) >= students-1);
% Ensure that for each slot sl in the schedule, the company and student in suite su on day d have an interview (if any) scheduled according to Interview:
constraint forall(sl in 1..slots, d in 1..days, su in 1..suites where StudentSchedule[sl, d, su] != 0)(Interview[StudentSchedule[sl, d, su], CompanySchedule[sl, d, su]] = 1);
% Ensure that if an interview of student st with company c is scheduled according to Interview, the interview takes place once in Schedule:
constraint forall(st in 1..students, c in 1..companies)(Interview[st, c] = 1 <-> count(Schedule[..,..,..,st], c) = 1);
% TODO: Fix
% constraint forall(c in 1..companies)(global_cardinality(global_cardinality(), 1..students, Interview[..,c]))

% Ensure that each student only has at most one interview during one slot:
constraint forall(sl in 1..slots, d in 1..days)(global_cardinality_low_up(StudentSchedule[sl, d, ..], 0..students, [0 | i in 1..students], [1 | i in 1..students]));
% Ensure that each company has up to two interviews during one slot:
constraint forall(sl in 1..slots, d in 1..days)(global_cardinality_low_up(CompanySchedule[sl,d,..], 0..companies, [0 | i in 1..companies], [2 | i in 1..companies]));

constraint maxRegret = 1;
constraint totalDisappointment = 0;

%% Preference

%% Company attendance cost

%% Suite rental cost



%----Objective----
% Day 3: minimize max regret:, total preference cost and total disappointment:
solve minimize obj;
% Day 2: secondary objective:
%solve minimize totalPreferenceCost;

%----Output----
output [show(max(Regret)), "\n"];
output [show(totalPreferenceCost), "\n"];
output [show(totalDisappointment)];
