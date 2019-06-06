%% rg generally stands for role Gini

particip_check( I ) :-
	get_path_val( I, members, Agents ),
	%initialise_off( Agents ),
        opinion_formation_loop( Agents, I ),
	voting_protocol_rg( I, rolegini, W ),
	reassign_roles( I, W ),
	%outliers( I, LoOut, HiOut ),
	%write( [LoOut, HiOut] ), nl,
	%write( W ), nl,
	true.

voting_protocol_rg( I, rolegini, Winner ) :-
        get_path_val( I, knowcode^^participation^^roles^^chair, Chair ),
        get_path_val( I, knowcode^^participation^^roles^^franchised, A ),
        cfv_yn( A, Chair, rolegini ),
        express_preferences_rolegini( A, Issue ),
        process_preferences_role( Chair, Issue, [], Votes ),
        winner_determination( plurality, Votes, Winner ),
        declare_rg( I, Chair, Issue, Winner ).


cfv_yn( [], _, _ ).
cfv_yn( [A|Rest], C, Issue ) :-
        send_msg( C, A, cfv(Issue) ),
        cfv_yn( Rest, C, Issue ).


express_preferences_rolegini( [], _ ).
express_preferences_rolegini( [A|Rest], Issue ) :-
        read_msg( A, C, cfv(Issue) ),
        determine_preference_rolegini( A, Issue, Pref ),
        send_msg( A, C, vote(Issue,Pref) ),
        express_preferences_rolegini( Rest, Issue ).


determine_preference_rolegini( A, rolegini, Pref ) :-
        get_path_val( A, off^^opn, Gidx ),
        yn_rolegini( Gidx, Pref ).

yn_rolegini( Gidx, [yes] ) :-
        Gidx > 0.4, !.
yn_rolegini( _, [no] ).


declare_rg( I, _, rolegini, W ) :-
        member( (yes,X), W ), !,
        write( 'ra_vote: True' ),nl,
        %write( yes ), write( ' ' ), write( X ), nl,
        true.
declare_rg( I, _, rolegini, W ) :-
        member( (no,X), W ), !,
        write( 'ra_vote: False' ),nl,
        %write( no ), write( ' ' ), write( X ), nl,
        true.


reassign_roles( _, W ) :-
        member( (no,_), W ), !.
reassign_roles( I, W ) :-
        member( (yes,_), W ),
	get_path_val( I, members, M ),
	amend( I, access_control, M ),
	amend( I, resource_alloc, M ),
	amend( I, minor_claims, M ),
	amend( I, role_assign, M ),
	amend( I, participation, M ),
        true.
        %agents_inspector( I ).


amend( I, access_control, M ) :-
	get_path_val( I, knowcode^^role_assign^^call, G ),
        Goal =.. [G, I, role(axcontroller, access_control), M ],
        call( Goal ).
amend( I, resource_alloc, M ) :-
	get_path_val( I, knowcode^^role_assign^^call, G ),
        Goal =.. [G, I, role(allocator, resource_alloc), M ],
        call( Goal ).
amend( I, minor_claims, M ) :-
	get_path_val( I, knowcode^^role_assign^^call, G ),
        Goal =.. [G, I, role(judge, minor_claims), M ],
        call( Goal ).
amend( I, role_assign, M ) :-
	get_path_val( I, knowcode^^role_assign^^call, G ),
        Goal =.. [G, I, role(director, role_assign), M ],
        call( Goal ).
amend( I, participation, M ) :-
	get_path_val( I, knowcode^^role_assign^^call, G ),
        Goal =.. [G, I, role(chair, participation), M ],
        call( Goal ).
