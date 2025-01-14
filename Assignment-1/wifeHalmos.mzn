include "globals.mzn";
% Number of couples:
int: n = 5;
% Generate a column and row for each person.
% Handshakes[i,j] = 1 if person i shook person j's hand.
% Couples are represented consecutively in each array; Halmos has index 1, and his wife has index 2.
array[1..2*n, 1..2*n] of var 0..1: Handshakes;
% The number of hands Halmos's wife shook
var 0..(2*n)-2: wifeHands;

solve satisfy;

% Halmos's wife's handshake count is equal to the sum of the second row in Handshakes 
constraint wifeHands = sum(Handshakes[2,..]);
% No person shakes their own hand, therefore, diagonals contain only 0:
constraint forall(i in 1..2*n)(Handshakes[i,i] = 0);
% Ensure symmetry of Handshakes (i.e. if person j shook person i's hand, person i also shook person j's hand:
constraint forall(i,j in 1..2*n)(Handshakes[i,j] = Handshakes[j,i]);
% No person shakes their partner's hand:
constraint forall(i in 1..n)(Handshakes[2*i, 2*i-1] = 0);
% Each person shakes a different number of hands (except for Halmos):
constraint all_different([sum(Handshakes[i,..]) | i in 2..2*n]);

% Part C: Check if there is any other solution than 4
% constraint sum(Handshakes[2,..]) != 4;
