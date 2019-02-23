/*
** opinion formation framework
*/

/*
** Opinion Formation framework initialisation
*/
initialise_off( [] ).
initialise_off( [A|Rest] ) :-
	initialise_sc( A ),
	initialise_opn_mu( A, random ),
	initialise_wij( A ),
	initialise_off( Rest ).

initialise_sc( A ) :-
	random(X),
        SC is round(X*100)/100, 
	set_path_val( A, off^^sconf, SC ).

initialise_opn_mu( A, random ) :-
	random(X),
        OMu is round(X*100)/100, 
	set_path_val( A, off^^mu, OMu ),
	set_path_val( A, off^^opn, OMu ).
initialise_opn_mu( A, ginirole(I) ) :-
	get_path_val( I, timeinrole, TinR ),
	get_path_val( A, socnet, SN ),
	sn_in_role( [A|SN], TinR, [], SNR ),
	gini( SNR, Gidx ),
	set_path_val( A, off^^mu, Gidx ),
        set_path_val( A, off^^opn, Gidx ).

initialise_wij( A ) :-
	get_path_val( A, off^^sconf, SC ),
        get_path_val( A, socnet, SocNet ),
        length( SocNet, L ),
        AvgW is round(((1-SC) / L) * 100) / 100,
        init_wij( SocNet, AvgW, [], IW ),
        set_path_val( A, off^^wij, [(A,SC)|IW] ).

init_wij( [], _, IW, IW ).
init_wij( [H|T], W, SoFar, IW ) :-
        init_wij( T, W, [(H,W)|SoFar], IW ).


/*
** Opinion Formation Loop
*/
opinion_formation_loop( Agents, I ) :-
	initialise_om( Agents, I ),
	of_loop( Agents, 0 ).


initialise_om( [], _ ).
initialise_om( [A|Rest], I ) :-
	initialise_opn_mu( A, ginirole(I) ),
	initialise_om( Rest, I ).


of_loop( _, 100 ) :-
	!.
of_loop( Agents, N ) :-
	off_cycle( Agents ),
	N1 is N + 1,
%write( '.' ),
        of_loop( Agents, N1 ).


/*
** Opinion Formation Cycle
*/
off_cycle( Agents ) :-
	opinion_exchange( Agents ),
        process_opinions( Agents ),
        update_opinions( Agents ),
        update_affinities( Agents ),
        update_weights( Agents ).

update_weights( [] ).

update_weights( [A|T] ) :-
        update_weight( A ),
        update_weights( T ).

update_affinities( [] ).

update_affinities( [A|T] ) :-
        update_affinity( A ),
        update_affinities( T ).

update_opinions( [] ).

update_opinions( [A|T] ) :-
        update_opinion( A ),
        update_opinions( T ).

process_opinions( [] ).

process_opinions( [A|T] ) :-
        get_path_val( A, off^^opn, Opn ),
        set_path_val( A, off^^oij, [(A,Opn)] ),
        process_opinion_ji( A ),
        process_opinions( T ).

process_opinion_ji( I ) :-
        read_msg( I, _, [] ).
process_opinion_ji( I ) :-
        read_msg( I, J, inform(opinion,Opn) ),
        add_path_val( I, off^^oij, (J,Opn) ),
        process_opinion_ji( I ).


opinion_exchange( [] ).

opinion_exchange( [A|T] ) :-
        get_path_val( A, off^^opn, Opn ),
        get_path_val( A, socnet, SocNet ),
        inform_opinion( A, SocNet, Opn ),
        opinion_exchange( T ).

inform_opinion( _, [], _ ).

inform_opinion( From, [To|Rest], Opn ) :-
        send_msg( From, To, inform(opinion,Opn) ),
        inform_opinion( From, Rest, Opn ).


/*
** Each step in the cycle
*/
update_opinion( A ) :-
	get_path_val( A, socnet, Agents ),
	sum_each_opinion( A, [A|Agents], 0, NewOpinion ),
	set_path_val( A, off^^opn, NewOpinion ).


sum_each_opinion( _, [], Opinion, NewOpinion ) :-
	NewOpinion is round(Opinion * 100) / 100.

sum_each_opinion( I, [J|T], SoFar, Opinion ) :-
	get_path_val( I, off^^oij, Opinions ),
	member( (J,Ojit), Opinions ),
	get_path_val( I, off^^wij, Weights ),
	member( (J,Wijt), Weights ),
	Opnij is Wijt * Ojit,
	SoFarJ is SoFar + Opnij,
	sum_each_opinion( I, T, SoFarJ, Opinion ).


update_affinity( A ) :-
	get_path_val( A, off^^mu, Mui ),
	maxomu( Mui, MaxOMu ),
	get_path_val( A, socnet, Agents ),
	update_each_affinity( A, [A|Agents], Mui, MaxOMu, [], NewAffs ),
	set_path_val( A, off^^aij, NewAffs ).


update_each_affinity( _, [], _, _, NewAffs, NewAffs ).

update_each_affinity( A, [J|T], Mui, MaxOMu, Affs, NewAffs ) :-
	get_path_val( A, off^^oij, Opinions ),
        member( (J,Ojt), Opinions ),
	absolute( Ojt, Mui, OMuDiff ),
	AffIJ is round((1 - (OMuDiff / MaxOMu)) * 100) / 100,
	update_each_affinity( A, T, Mui, MaxOMu, [(J,AffIJ)|Affs], NewAffs ).

maxomu( Mui, MaxOMu ) :-
	Mui < 0.5, !,
	MaxOMu is round((1-Mui) * 100) / 100.
maxomu( Mui, Mui ).
	

update_weight( A ) :-
	get_path_val( A, off^^wij, Weights ),
	get_path_val( A, off^^aij, Affinities ),
	sum_all_weights( Weights, Affinities, 0, SumWK ),
	calc_new_weights( Weights, Affinities, SumWK, [], NewWeights ),
	normalise_weights( NewWeights,  FinalWeights ),
	set_path_val( A, off^^wij, FinalWeights ).

normalise_weights( NewWeights, FinalWeights ) :-
	sum_weights( NewWeights, 0, SumW ),
	normalise_each_weight( NewWeights, SumW, [], FinalWeights ).

sum_weights( [], Sum, Sum ).

sum_weights( [(_,W)|T], SoFar, Sum ) :-
	NewSoFar is round((SoFar + W) * 100) / 100,
	sum_weights( T, NewSoFar, Sum ).

normalise_each_weight( [], _, L, L ).

normalise_each_weight( [(A,W)|T], Sum, SoFar, FinalWeights ) :-
	NormalW is round((W / Sum) * 100) / 100,
	normalise_each_weight( T, Sum, [(A,NormalW)|SoFar], FinalWeights ).


calc_new_weights( [], _, _, NewWeights, NewWeights ).
	
calc_new_weights( [(A,Wgh)|T], Affinities, SumWIJ, SoFar, NewWeights ) :-
	member( (A,Aff), Affinities ),
	NewWgh is round(((Wgh + (Wgh*Aff)) / SumWIJ) * 100) / 100,
	calc_new_weights( T, Affinities, SumWIJ, [(A,NewWgh)|SoFar], NewWeights ).

	
sum_all_weights( [], _, SumWK, SumWK ).

sum_all_weights( [(A,Wgh)|T], Affinities, SoFar, SumWK ) :-
	member( (A,Aff), Affinities ),
	NewSoFar is round((SoFar + (Wgh + (Wgh*Aff))) * 100) / 100,
	sum_all_weights( T, Affinities, NewSoFar, SumWK ).


/*
** Miscellaneous
*/
absolute( A, B, D ) :-
	A > B, !,
	D is A - B.
absolute( A, B, D ) :-
	D is B - A.

max( A, B, A ) :-
	A > B, !.
max( _, B, B ).

/*
** find and set anchor
*/

find_and_set_anchor( A ) :-
	b_getval( hub, H ),
	get_path_val( H, agt^^sn, Clique ),
	pick_outsider( A, Clique, Anchor ),
	set_path_val( Anchor, off^^sconf, 1.0 ).

pick_outsider( [H|_], Clique, H ) :-
	\+ member( H, Clique ), !.
pick_outsider( [_|T], Clique, H ) :-
	pick_outsider( T, Clique, H ).

/*
init_sc( A ) :-
        get_path_val( A, agt^^sn, SN ),
        get_mus( SN, [], Mus ),
        get_path_val( A, off^^mu, Mui ),
        compare_mui_mujs( Mui, Mus, SC ),
        set_path_val( A, off^^sconf, SC ).

compare_mui_mujs( Mui, Mus, SC ) :-
        Mui > 0.5, !,
        count_mus( Mus, 0, 0, Over, _ ),
        length( Mus, L ),
        SC is round( (Over/L)*100 ) / 100.
compare_mui_mujs( _, Mus, SC ) :-
        count_mus( Mus, 0, 0, _, Under ),
        length( Mus, L ),
        SC is round( (Under/L)*100 ) / 100.

count_mus( [], Over, Under, Over, Under ).
count_mus( [H|T], O, U, Over, Under ) :-
        H > 0.5, !,
        O1 is O + 1,
        count_mus( T, O1, U, Over, Under ).
count_mus( [_|T], O, U, Over, Under ) :-
        U1 is U + 1,
        count_mus( T, O, U1, Over, Under ).

get_mus( [], Mus, Mus ).
get_mus( [H|T], SoFar, Mus ) :-
        get_path_val( H, off^^mu, Muj ),
        get_mus( T, [Muj|SoFar], Mus ).
*/

sn_in_role( [], _, L, L ).

sn_in_role( [A|Rest], TinR, SoFar, L ) :-
	member( (A,T), TinR ),
	sn_in_role( Rest, TinR, [(A,T)|SoFar], L ).
