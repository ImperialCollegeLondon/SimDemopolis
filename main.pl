%
% swipl -G100g -T20g -L20g
%

debug.
:- use_module(library(lists)).
:- use_module(library(optparse)).

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

run :-
        % spy(current_prolog_flag ),
        get_args( Args ),
        make_institution( I ),
        make_agents( Agents ),
        register( I, Agents ),   % Agents are registered to institution I
	%init_socnet( Agents, ring ),
	%init_socnet( Agents, fully_connected ),
        %trace,
        member( net_top(Socnet_Type), Args ),
	init_socnet( Agents, Socnet_Type ),
        initialise_off( Agents ),
        inspect_each_agent( Agents ),
        %notrace,
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
	inst_inspector( I ),
	%skiver( I ),
	b_setval( tick, 0 ),
	% Third argument denotes amount of time (the number of times the test is)
        % TODO: Used to be 60. Change this later, or find a way to reduce memory usage
        member( tick_num(Ticks), Args ),
	role_assign_test( I, Agents, Ticks ).
	%true.

%% obtain command line arguments
get_args(Opts) :-
    current_prolog_flag(argv, Cl_Args),
    % TODO: add proper unicode to help
    % specification for command line options
    OptsSpec =
    [[opt(net_top), type(atom), default('random'),
      shortflags([s]), longflags([socnet]),
      help([ 'social network topology, one of'
             , '  ring'
             , '  fully_connected: each node connects to all the others'
             , '  random: randomly generated, erdos-renyi network'
             , '  small_world: Watts–Strogatz network, demonstrates small world property'
             , '  scale_free: Barabasi-Albert network, demonstrates a scale-free property.'])]

     ,[opt(tick_num), type(integer), default(60),
      shortflags(['T']), longflags([ticks]),
      help(['Number of "ticks" (time units) the role assignment process runs for.'])]
    ],
    opt_parse( OptsSpec, Cl_Args, Opts, PosArgs ).

%skiver( _ ).

skiver( I ) :-
	get_path_val( I, members, M ),
	random_member( X, M ),
	set_path_val( X, citizenship, 0 ).


role_assign_test( I, _, Stop ) :-
	b_getval( tick, Stop ),
	!, nl,
	inst_inspector( I ),
	true.

role_assign_test( I, Agents, Stop ) :-
	b_getval( tick, T ),
        T1 is T + 1,
	write( [tick, T1] ), nl,
        b_setval( tick, T1 ),
	resource_allocation_loop( I ),
	get_path_val( I, knowcode^^participation^^call, G ),
	Goal =.. [G,I],
	call( Goal ),
	agent_inspectorate( Agents ),
        i_role_gini( I ),
	role_assign_test( I, Agents, Stop ).


agent_inspectorate( [] ).
agent_inspectorate( [H|T] ) :-
	agent_inspector( H ),
	agent_inspectorate( T ).


i_role_gini( I ) :-
	get_path_val( I, timeinrole, TinR ),
	gini( TinR, IG ),

	write( IG ), nl,
	true.
