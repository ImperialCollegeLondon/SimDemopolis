
rap_protocol( I, Issue, Candidates ) :-
	%Issue = role(chair,participation),
	get_path_val( I, knowcode^^role_assign^^roles^^director, Dir ), 
	get_path_val( I, knowcode^^role_assign^^roles^^racomm, Comm ), 
	cfv( Comm, Dir, Issue, Candidates ),
	express_preferences_role( Comm, Issue ),
        process_preferences_role( Dir, Issue, [], Votes ),
        get_path_val( I, knowcode^^role_assign^^dof^^wdm, WDM ),
        winner_determination( WDM, Votes, Winner ),
        declare( I, Dir, Issue, Winner ).
	
/*
rap_protocol( I, Issue, Candidates ) :-
	Issue = role(director,role_assign),
	get_path_val( I, knowcode^^role_assign^^roles^^director, Dir ), 
	get_path_val( I, knowcode^^role_assign^^roles^^racomm, Comm ), 
	cfv( Comm, Dir, Issue, Candidates ),
	express_preferences_role( Comm, Issue ),
        process_preferences_role( Dir, Issue, [], Votes ),
        get_path_val( I, knowcode^^role_assign^^dof^^wdm, WDM ),
        winner_determination( WDM, Votes, Winner ),
        declare( I, Dir, Issue, Winner ).
*/

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


determine_preference_role( A, role(_,_), _, [Pref] ) :-
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


process_preferences_role( Chair, _, Votes, Votes ) :-
        peek_msgq_empty( Chair ), !.
process_preferences_role( Chair, Issue, SoFar, Votes ) :-
        read_msg( Chair, _, vote(Issue,Pref) ),
        process_preferences_role( Chair, Issue, [Pref|SoFar], Votes ).

/*
declare( I, _, role(Role,Rule), [(W,_)] ) :-
        %% only one winner
        !,
	set_path_val( I, knowcode^^Rule^^roles^^Role, W ).
declare( I, _, role(Role,Rule), L ) :-
        %% chair casting vote
        random_member( (W,_), L ),
	set_path_val( I, knowcode^^Rule^^roles^^Role, W ).
*/


declare( I, D, role(Role,Rule), L ) :-
        %% only one winner
        random_member( (W,_), L ),
	get_path_val( I, knowcode^^Rule^^roles^^Role, C ),
	nonvar( C ), !,
	send_msg( D, C, invite(resign,Role,Rule) ),
	process_invitation_to_resign( C ),
	read_msg( D, C, Reply ),
	invite_to_serve( I, D, C, W, (Role,Rule), Reply ).
declare( I, _, role(Role,Rule), L ) :-
        %% chair casting vote
        random_member( (W,_), L ),
        set_path_val( I, knowcode^^Rule^^roles^^Role, W ).
	
invite_to_serve( I, _, C, W, (Role,Rule), refuse ) :-
	get_path_val( I, knowcode^^minor_claims^^call, G ),
	Goal =.. [G, I, C, W, refuse, resign, (Role,Rule)],
	call( Goal ).
invite_to_serve( I, D, _, W, (Role,Rule), resign ) :-
	send_msg( D, W, invite(serve,Role,Rule) ),
	process_invitation_to_serve( W ),
	read_msg( D, W, Reply ),
	make_final_assign( I, W, Reply, (Role,Rule) ).

make_final_assign( I, W, accept, (Role,Rule) ) :-
	set_path_val( I, knowcode^^Rule^^roles^^Role, W ).
make_final_assign( I, W, refuse,  (Role,Rule) ) :-
	get_path_val( I, knowcode^^minor_claims^^call, G ),
        Goal =.. [G, I, W, refuse, serve, (Role,Rule)],
        call( Goal ).

process_invitation_to_resign( C ) :-
	read_msg( C, D, invite(resign,Role,Rule) ),
	generate_reply2resign( C, Reply ),
	send_msg( C, D, Reply ).
	
process_invitation_to_serve( W ) :-
	read_msg( W, D, invite(serve,Role,Rule) ),
	generate_reply2serve( W, Reply ),
	send_msg( W, D, Reply ).

generate_reply2resign( A, Reply ) :-
	random( X ),
	get_path_val( A, citizenship, C ),
	X < C -> Reply=resign ; Reply=refuse.

generate_reply2serve( A, Reply ) :-
	random( X ),
	get_path_val( A, citizenship, C ),
	X < C -> Reply=accept ; Reply=refuse.
	

