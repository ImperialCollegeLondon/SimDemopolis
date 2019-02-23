
gini( AgUtils, Gidx ) :-
	sum_i_A( AgUtils, AgUtils, 0, SumiA ),
	length( AgUtils, ModA ),
	ModAsqd is ModA * ModA,
	mean( AgUtils, ModA, 0, Mu ),
	compute_gini_0chk( Mu, ModAsqd, SumiA, Gidx ).

compute_gini_0chk( 0, _, _, 0 ) :- !.
compute_gini_0chk( Mu, ModAsqd, SumiA, Gidx ) :-
	Gidx is round(((1/2) * (1/Mu) * (1/ModAsqd) * SumiA) * 100) / 100.

sum_i_A( [], _, SumiA, SumiA ).

sum_i_A( [(_,Pi)|Rest], AgUtils, SF, SumiA ) :-
	sum_j_A( AgUtils, Pi, 0, SumjA ),
	NewSF is SF + SumjA,
	sum_i_A( Rest, AgUtils, NewSF, SumiA ).

sum_j_A( [], _, SumjA, SumjA ).

sum_j_A( [(_,Pj)|Rest], Pi, SF, SumjA ) :-
	gabs( Pi, Pj, AbsPiPj ),
	NewSF is SF + AbsPiPj,
	sum_j_A( Rest, Pi, NewSF, SumjA ).
	
mean( [], L, Total, Mu ) :-
	Mu is Total / L.

mean( [(_,U)|Rest], L, SF, Mu ) :-
	NewSF is SF + U,
	mean( Rest, L, NewSF, Mu ).

gabs( Pi, Pj, AbsPiPj ) :-
	Pi > Pj, !,
	AbsPiPj is Pi - Pj.
gabs( Pi, Pj, AbsPiPj ) :-
	AbsPiPj is Pj - Pi.
