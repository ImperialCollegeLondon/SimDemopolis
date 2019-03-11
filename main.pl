%
% swipl -G100g -T20g -L20g
%

:- use_module(library(lists)).

:- op( 500, xfy, ^^ ).

:- [access].   % Main graph and agent manipulation code
:- [institution].
:- [agents].
:- [pprint].
:- [network].
:- [small_world]. % This is new
:- [comms].
:- [elect].
:- [minorclaims].
:- [opframe].
:- [participation].
:- [resalloc].
:- [roleassign].
:- [gini].
:- [stats].


d :-
	make_institution( I ),
        make_agents( Agents ),
        register( I, Agents ),   % Agents are registered to institution I 
	%init_socnet( Agents, ring ),
	%init_socnet( Agents, fully_connected ),
	init_socnet2( Agents, small_world ),
	initialise_off( Agents ),
	init_timeinrole( I ),
	init_utr( I ),
	founder( I ),
	%universal_suffrage( I ),
	init_citizenship( I ),
	init_participation_chk( I, participation ),
	init_role_assignment( I, role_assign ),
	init_access_control( I, access_control ),
	init_resource_alloc( I, resource_alloc ),
	init_minor_claims( I, minor_claims ),
	%inst_inspector( I ),
	%skiver( I ),
	b_setval( tick, 0 ),
	% Third argument denotes amount of time (the number of times the test is)
	role_assign_test( I, Agents, 60 ).  
	%true.

%skiver( _ ).

skiver( I ) :-
	get_path_val( I, members, M ),
	random_member( X, M ),
	set_path_val( X, citizenship, 0 ).


role_assign_test( I, _, Stop ) :-
	b_getval( tick, Stop ),
	!, nl,
	%inst_inspector( I ),
	true.

role_assign_test( I, Agents, Stop ) :-
	b_getval( tick, T ),
        T1 is T + 1,
	%write( [tick, T1] ), nl,
        b_setval( tick, T1 ),
	resource_allocation_loop( I ),
	get_path_val( I, knowcode^^participation^^call, G ),
	Goal =.. [G,I],
	call( Goal ),
	%agent_inspectorate( Agents ),
        i_role_gini( I ),
	role_assign_test( I, Agents, Stop ).


agent_inspectorate( [] ).
agent_inspectorate( [H|T] ) :-
	agent_inspector( H ),
	agent_inspectorate( T ).


i_role_gini( I ) :-
	get_path_val( I, timeinrole, TinR ),
	gini( TinR, IG ),

	%write( IG ), nl.
	true.
