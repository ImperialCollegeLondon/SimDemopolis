
%% pretty-print institution

inst_inspector( I ) :-
        get_path_val( I, inst, Name ),
        get_path_val( I, members, M ), 
        get_path_val( I, players, P ), 
        get_path_val( I, timeinrole, TinR ), 
        get_path_val( I, rolehistory, RH ), 
        get_path_val( I, timeinrole, TinR ), 
        get_path_val( I, rolehistory, RH ), 
        get_path_val( I, immutable_rules, IR ), 
        get_path_val( I, mutable_rules, MR ), 
        get_path_val( I, knowcode^^participation, LegPar ), 
        get_path_val( I, knowcode^^role_assign, LegRole ), 
        get_path_val( I, knowcode^^access_control, LegAcc ), 
        get_path_val( I, knowcode^^resource_alloc, LegAll ), 
        get_path_val( I, knowcode^^minor_claims, LegMC ), 

        pp( inst, Name, 0 ),
        pp( members, M, 4 ),
        pp( players, P, 4 ),

        pp( timeinrole, TinR, 4 ), 
        pp( rolehistory, RH, 4 ), 

	pp( immutable_rules, IR, 4 ),
	pp( mutable_rules, MR, 4 ),

	pp( participation, LegPar, 8 ),
	pp( role_assignment, LegRole, 8 ),
	pp( access_control, LegAcc, 8 ),
	pp( resource_alloc, LegAll, 8 ),
	pp( minor_claims, LegMC, 8 ),
        true.

%% pretty-print agent/agents

agents_inspector( I ) :-
	get_path_val( I, members, M ),
	inspect_each_agent( M ).

inspect_each_agent( [] ).
inspect_each_agent( [A|T] ) :-
	agent_inspector( A ),
	inspect_each_agent( T ).


agent_inspector( A ) :-
	get_path_val( A, agt, Name ),
        get_path_val( A, msgq, MsgQ ),
        get_path_val( A, socnet, SN ), 
        get_path_val( A, off^^opn, Opinion ), 
        get_path_val( A, off^^sconf, SelfConf ), 
        get_path_val( A, off^^mu, Mu ), 
        get_path_val( A, off^^wij, WeightIJ ), 
        get_path_val( A, off^^aij, AffinityIJ ), 
        get_path_val( A, off^^oij, OpinionIJ ), 
	pp( agent, Name, 0 ),
        pp( 'message queue', MsgQ, 4 ),
        pp( 'social network', SN, 4 ),
	pp( 'opinion formation', " ", 4 ),
	pp( selfconf, SelfConf, 8 ),
	pp( mu, Mu, 8 ),
	pp( opinion, Opinion, 8 ),
	pp( weight_ij, WeightIJ, 8 ),
	pp( affinity_ij, AffinityIJ, 8 ),
	pp( opinion_ij, OpinionIJ, 8 ),
	true.
	

pp( Field, Value, Tab ) :-
        pp_onoff( Field, on ), !,
        tab( Tab ),
        write( Field ), write( ': ' ), write( Value ),
        nl.

pp( Field, _, _ ) :-
	pp_onoff( Field, off ).


pp_onoff( inst, on ).
pp_onoff( members, on ).
pp_onoff( players, on ).
pp_onoff( timeinrole, on ).
pp_onoff( rolehistory, on ). 
pp_onoff( immutable_rules, on ).
pp_onoff( mutable_rules, on ).
pp_onoff( participation, on ).
pp_onoff( role_assignment, on ).
pp_onoff( access_control, on ).
pp_onoff( resource_alloc, on ).
pp_onoff( minor_claims, on ).


pp_onoff( agent, on ).
pp_onoff( 'message queue', off ).
pp_onoff( 'social network', on ).
pp_onoff( 'opinion formation', off ).
pp_onoff( selfconf, off ).
pp_onoff( mu, off ).
pp_onoff( opinion, on ).
pp_onoff( weight_ij, off ).
pp_onoff( affinity_ij, off ).
pp_onoff( opinion_ij, off ).

