
/**
election_for_role( Agents, Institution, Issue ) :-
	call for votes
	express preferences
	winner determination
	set path val
*/
	
/*
voting_protocol( I, Issue, Candidates ) :-
	Issue = role^^_,
	get_path_val( I, roles^^chair, Chair ), 
	get_path_val( I, franchised, A ), 
	cfv( A, Chair, Issue, Candidates ),
	express_preferences_role( A, Issue ),
	process_preferences_role( Chair, Issue, [], Votes ),
	get_path_val( I, ruleDoF^^roleWDM, WDM ),
	winner_determination( WDM, Votes, Winner ),
	declare( I, Chair, Issue, Winner ).

voting_protocol( I, rolegini, Winner ) :-
	get_path_val( I, roles^^chair, Chair ),
        get_path_val( I, franchised, A ),
        cfv( A, Chair, rolegini ),
	express_preferences_rolegini( A, Issue ),
        process_preferences_role( Chair, Issue, [], Votes ),
        winner_determination( plurality, Votes, Winner ),
        declare( I, Chair, Issue, Winner ).
	

cfv( [], _, _ ).
cfv( [A|Rest], C, Issue ) :-
	send_msg( C, A, cfv(Issue) ),
	cfv( Rest, C, Issue ).

cfv( [], _, _, _ ).
cfv( [A|Rest], C, Issue, Candidates ) :-
	send_msg( C, A, cfv(Issue,Candidates) ),
	cfv( Rest, C, Issue, Candidates ).


express_preferences_role( [], _ ).
express_preferences_role( [A|Rest], Issue ) :-
	read_msg( A, C, cfv(Issue,Candidates) ),
	determine_preference_role( A, Issue, Candidates, Pref ),
	send_msg( A, C, vote(Issue,Pref) ),
	express_preferences_role( Rest, Issue ).

express_preferences_rolegini( [], _ ).
express_preferences_rolegini( [A|Rest], Issue ) :-
	read_msg( A, C, cfv(Issue) ),
	determine_preference_rolegini( A, Issue, Pref ),
	send_msg( A, C, vote(Issue,Pref) ),
	express_preferences_rolegini( Rest, Issue ).


determine_preference_role( A, role^^_, _, [Pref] ) :-
	get_path_val( A, socnet, SN ),
	get_path_val( i, timeinrole, TinR ),
	select_preference( SN, TinR, Pref ).
	%random_member( Pref, SN ).

select_preference( SN, _, Pref ) :-
	random( X ), 
	X > 0.5, !,
	random_member( Pref, SN ).
select_preference( [H|SN], TinR, Pref ) :-
	member( (H,T), TinR ),
	least_tinr( SN, TinR, [(H,T)], Pref ).

least_tinr( [], _, Leasts, Pref ) :-
	random_member( (Pref,_), Leasts ).
least_tinr( [H|L1], TinR, [(_,T2)|_], Pref ) :-
	member( (H,T1), TinR ),
	T1 < T2, !,
	least_tinr( L1, TinR, [(H,T1)], Pref ).
least_tinr( [H|L1], TinR, [(A,T2)|L2], Pref ) :-
        member( (H,T1), TinR ),
        T1 = T2, !,
        least_tinr( L1, TinR, [(H,T1),(A,T2)|L2], Pref ).
least_tinr( [_|T], TinR, X, Pref ) :-
	least_tinr( T, TinR, X, Pref ).


determine_preference_rolegini( A, rolegini, Pref ) :-
	get_path_val( A, off^^opn, Gidx ),
	yn_rolegini( Gidx, Pref ).

yn_rolegini( Gidx, [yes] ) :-
	Gidx > 0.4, !.
yn_rolegini( _, [no] ).

process_preferences_role( Chair, _, Votes, Votes ) :-
	peek_msgq_empty( Chair ), !.
process_preferences_role( Chair, Issue, SoFar, Votes ) :-
	read_msg( Chair, _, vote(Issue,Pref) ),
	process_preferences_role( Chair, Issue, [Pref|SoFar], Votes ).
	

declare( I, _, role^^Role, [(W,_)] ) :-
	%% only one winner
	!,
	assign_role( I, Role, W ).
declare( I, _, role^^Role, L ) :-
	%% chair casting vote
	random_member( (W,_), L ),
	assign_role( I, Role, W ).

declare( I, _, rolegini, W ) :-
	member( (yes,X), W ), !,
	write( '1,' ),
	%write( yes ), write( ' ' ), write( X ), nl,
	true.
declare( I, _, rolegini, W ) :-
	member( (no,X), W ), !,
	write( '0,' ),
	%write( no ), write( ' ' ), write( X ), nl,
	true.
*/


/*
** Winner determination methods
*/

winner_determination( plurality, VotesCast, Winners ) :-
	count_votes( VotesCast, [], [H|T] ),
	most_votes( T, [H], Winners ).

winner_determination( runoff, VotesCast, Winner ) :-
	count_votes( VotesCast, [], VoteCount ),
	round_one_runoff( VoteCount, TopTwo ),
	round_two_runoff( TopTwo, VotesCast, TwoCount ),
	most_votes( TwoCount, Winner ).

winner_determination( borda, VotesCast, Winner ) :-
	count_candidates( VotesCast, 0, NC ),
	count_borda_votes( NC, VotesCast, [], VoteCount ),
        most_votes( VoteCount, Winner ).

winner_determination( instant_ro, VotesCast, Winner ) :-
	least_candidate_elimination( VotesCast, Winner ).

winner_determination( approval, VotesCast, Winner ) :-
	count_all_votes( VotesCast, [], VoteCount ),
	most_votes( VoteCount, Winner ).


count_votes( [], VC, VC ).

count_votes( [[A|_]|T], SoFar, VC ) :-
	append( Fr, [(A,V)|Ba], SoFar ), !,
	V1 is V + 1,
	append( Fr, [(A,V1)|Ba], NewSoFar ),
	count_votes( T, NewSoFar, VC ).

count_votes( [[A|_]|T], SoFar, VC ) :-
	count_votes( T, [(A,1)|SoFar], VC ).


most_votes( [], W, W ).

most_votes( [(A,V1)|T], [(_,V2)|_], W ) :-
	V1 > V2, !,
	most_votes( T, [(A,V1)], W ).

most_votes( [(A1,V1)|T1], [(A2,V2)|T2], W ) :-
	V1 = V2, !,
	most_votes( T1, [(A1,V1),(A2,V2)|T2], W ).

most_votes( [_|T], SoFar, W ) :-
	most_votes( T, SoFar, W ).

/*
most_votes( [(A,_)], A ).

most_votes( [(A,V1), (_,V2) | T], Winner ) :-
	V1 > V2, !,
	most_votes( [(A,V1)|T], Winner ).

most_votes( [_|T], Winner ) :-
	most_votes( T, Winner ).
*/


round_one_runoff( VoteCount, TopTwo ) :- 
	sort( VoteCount, [], SortVC ),
	toptwo( SortVC, TopTwo ).

sort( [], Sort, Sort ).

sort( [H|T], SoFar, Sort ) :-
	insert( H, SoFar, NewSoFar ),
	sort( T, NewSoFar, Sort ).

insert( H, [], [H] ).

insert( (C1,V1), [(C2,V2)|T], [(C1,V1),(C2,V2)|T] ) :-
	V1 > V2, !.

insert( (C1,V1), [(C2,V2)|T1], [(C2,V2)|T2] ) :-
	insert( (C1,V1), T1, T2 ).

toptwo( [F,S|_], [F,S] ).

round_two_runoff( TwoCount, [], TwoCount ).

round_two_runoff( [(C1,V1),(C2,V2)], [V|T], TwoCount ) :-
	append( _, [C1|Ba], V ),
	append( _, [C2|_], Ba ), !,
	V11 is V1 + 1,
	round_two_runoff( [(C1,V11),(C2,V2)], T, TwoCount ).

round_two_runoff( [(C1,V1),(C2,V2)], [_|T], TwoCount ) :-
	V21 is V2 + 1,
	round_two_runoff( [(C1,V1),(C2,V21)], T, TwoCount ).

count_candidates( [], NC, NC ).

count_candidates( [H|T], SF, NC ) :-
	length( H, L ),
	L > SF, !,
	count_candidates( T, L, NC ).

count_candidates( [_|T], SF, NC ) :-
	count_candidates( T, SF, NC ).

count_borda_votes( _, [], VC, VC ).

count_borda_votes( N, [V|T], SoFar, VoteCount ) :-
	rankorder2bordapoints( V, N, BordaV ),
	add_bordapoints( BordaV, SoFar, NewSoFar ),
	count_borda_votes( N, T, NewSoFar, VoteCount ).

rankorder2bordapoints( [], _, [] ).

rankorder2bordapoints( [C|T1], N1, [(C,N1)|T2] ) :-
	N is N1 - 1,
	rankorder2bordapoints( T1, N, T2 ).

add_bordapoints( [], BordaCount, BordaCount ).

add_bordapoints( [(C,V1)|T], SoFar, BordaCount ) :-
	append( Fr, [(C,V2)|Ba], SoFar ), !,
	Vp is V1 + V2,
	append( Fr, [(C,Vp)|Ba], NewSoFar ), 
	add_bordapoints( T, NewSoFar, BordaCount ).
	
add_bordapoints( [(C,V)|T], SoFar, BordaCount ) :-
	add_bordapoints( T, [(C,V)|SoFar], BordaCount ).

count_all_votes( [], VC, VC ).

count_all_votes( [V|T], SoFar, VC ) :-
	count_each_vote( V, SoFar, NewSoFar ),
	count_all_votes( T, NewSoFar, VC ).

count_each_vote( [], SF, SF ).

count_each_vote( [C|T], SoFar, Result ) :-
	append( Fr, [(C,V)|Ba], SoFar ), !,
	V1 is V + 1,
	append( Fr, [(C,V1)|Ba], NSF ),
	count_each_vote( T, NSF, Result ).

count_each_vote( [C|T], SoFar, Result ) :-
	count_each_vote( T, [(C,1)|SoFar], Result ).
	
least_candidate_elimination( [[Winner]|_], Winner ).

least_candidate_elimination( VotesCast, Winner ) :-
	count_votes( VotesCast, [], VoteCount ),
	find_least( VoteCount, LeastC ),
	eliminate_least( LeastC, VotesCast, NewVotesCast ),
	least_candidate_elimination( NewVotesCast, Winner ).

find_least( [(Least,_)], Least ).

find_least( [(C1,V1),(_,V2)|T], Least ) :-
	V1 < V2, !,
	find_least( [(C1,V1)|T], Least ).

find_least( [_,(C2,V2)|T], Least ) :-
        find_least( [(C2,V2)|T], Least ).

eliminate_least( _, [], [] ).

eliminate_least( L, [V|T1], [NewV|T2] ) :-
	append( Fr, [L|Ba], V ),
	append( Fr, Ba, NewV ),
	eliminate_least( L, T1, T2 ).



