include "globals.mzn";
% Generate a column and row for each person.
% Handshakes[i,j] = 1 if person i shook person j's hand.
% Couples are represented consecutively in each array; Halmos has index 1, and his wife has index 2.
array[1..10, 1..10] of var 0..1: Handshakes;

solve satisfy;

% No person shakes their own hand, therefore, diagonals contain only 0:
constraint forall(i in 1..10)(Handshakes[i,i] = 0);
% Ensure symmetry of Handshakes (i.e. if person j shook person i's hand, person i also shook person j's hand:
constraint forall(i,j in 1..10)(Handshakes[i,j] = Handshakes[j,i]);
% No person shakes their partner's hand:
constraint forall(i in 1..5)(Handshakes[2*i, 2*i-1] = 0);
% Each person shakes a different number of hands (except for Halmos):
constraint all_different([sum(Handshakes[i,..]) | i in 2..10]);

var 0..8: shakes;
constraint shakes = sum(Handshakes[2,..]);

% Part C: Check if there is any other solution than 4
% constraint sum(Handshakes[2,..]) != 4;

