%
% swipl -G100g -T20g -L20g
%

%debug.
:- use_module(library(lists)).
:- use_module(library(optparse)).
:- use_module(library(random)).

:- op( 500, xfy, ^^ ).

:- [access].   % Main graph and agent manipulation code
:- [institution]. % Set up institution
:- [agents]. % Set up agents
:- [pprint]. % pretty printing
:- [network]. % Code for constructing social networks
:- [comms].
:- [elect].
:- [minorclaims].
:- [opframe].
:- [participation].
:- [resalloc].
:- [roleassign].
:- [gini].
:- [stats]. % Compute various statistics about SimDemopolis

run :-
    %spy(opinion_formation_loop),
        get_args( Args ),
        subset( [
            agent_num(N),
            net_top(Socnet_Type),
            net_prob(P),
            sw_k(K),
            sf_m(M),
            has_skiver(Skiver_state),
            tick_num(Ticks)], Args ),
        make_institution( I ),
        make_agents( Agents, N ),
        register( I, Agents ),   % Agents are registered to institution I
	init_socnet( Agents, Socnet_Type, [P,K,M] ),
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
	inst_inspector( I ),
	skiver( I , Skiver_state ),
        b_setval( tick, 0 ),
        write_socnet( Agents, Ticks ),
        % Third argument denotes amount of time (the number of times the test is)
	role_assign_test( I, Agents, Ticks ).
	%true.

%% obtain command line arguments
get_args(Opts) :-
    current_prolog_flag(argv, Cl_Args),
    % TODO: add proper unicode to help
    % specification for command line options
    OptsSpec =
    [[opt(net_top), type(atom), default('random'),
      shortflags([s]), longflags([socnet,sn]),
      help([ 'social network topology, one of'
             , '  ring'
             , '  fully_connected: each node connects to all the others'
             , '  random: randomly generated, erdos-renyi network'
             , '  small_world: Watts–Strogatz network, demonstrates small world property'
             , '  scale_free: Barabasi-Albert network, demonstrates a scale-free property.'])]

     ,[opt(tick_num), type(integer), default(60),
      shortflags(['T']), longflags([ticks]),
      help(['Number of "ticks" (time units) the role assignment process runs for.'])],
     [opt(has_skiver), type(boolean), default(false),
      shortflags(['f']), longflags(['skiver', 'free_rider']),
      help('Is there a \'Skiver\' among the agents, who has a propensity to freeride? (chosen randomly)')],
     [opt(net_prob), type(float), default(0.25),
     shortflags(['P']), longflags(['probability']),
     help(['Social network probability: '
          , ' For a random network, this is the probability that a link is made between two nodes.'
         , '  For a small-world network, this is the probability that a link from the ring network is reassigned.'])],
    [opt(sw_k), type(integer), default(1),
     shortflags(['K']), longflags(['small_world_connections','small_world_k'
                                   ,'swk']),
     help(['Number of links made to each node in the small world network.'
          , '(often referred to as k)'])],
    [opt(agent_num), type(integer), default(30),
     shortflags(['N']), longflags(['agent_number', 'agent_num']),
     help('Total number of Agents in SimDemopolis')],
    [opt(sf_m), type(integer), default(1),
     shortflags(['m']), longflags(['scale_free_links', 'scale_free_km', 'sfm']),
     help(['Number of new links added per new node in the scale-free network'
          , '(often referred to as m)'])]
    ],
    opt_parse( OptsSpec, Cl_Args, Opts, PosArgs ).

%skiver( _ ).

skiver( I, true ) :-
	get_path_val( I, members, M ),
	random_member( X, M ),
	set_path_val( X, citizenship, 0 ).
skiver( _, false ).

role_assign_test( I, _, Stop ) :-
	b_getval( tick, Stop ),
	!, nl,
	inst_inspector( I ),
	true.

role_assign_test( I, Agents, Stop ) :-
    prolog_current_frame(F), format('~d~n',[F]),
        write("NEW ROUND"),nl,
	b_getval( tick, T ),
        T1 is T + 1,
	write( [tick, T1] ), nl,
        b_setval( tick, T1 ),
	resource_allocation_loop( I ),
	get_path_val( I, knowcode^^participation^^call, G ),
	Goal =.. [G,I],
	call( Goal ),
        %nl, % makes the output easier to parse
        write('Begin Agent Inspection'), nl,
	agent_inspectorate( Agents ),
        write('End Agent Inspection'), nl,
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

% If the number of ticks is 0, print Agent information. This allows a social
% network to be generated in less computing time
write_socnet( Agents, 0 ):-
    write("NEW ROUND"), nl,
    write('[tick,1]'), nl,
    write('ra_vote: False'),
    write('Begin Agent Inspection'), nl,
    inspect_each_agent( Agents ),
    write('End Agent Inspection'), nl.
write_socnet( _,_ ).
