/*
** get_path_val( Agent, Path, Value )	returns Value at end of ^^ path
** set_path_val( Agent, Path, Value )	sets Value to end of ^^ path
** add_path_val( Agent, Path, Value )	if Path^^L is a list, adds Value to L
** addq_path_val( Agent, Path, Value )	if Path^^L is a list, appends Value to L
*/

get_path_val( Name, Path, Value ) :-
	b_getval( Name, Agent ),        % Get global variable (inc. backtracking)
	find_path_val( Agent, Path, Value ).

find_path_val( [Field^^Value|_], Field, Value ) :-
	atomic( Field ), !.

find_path_val( [Field^^Fvals|_], Field^^RestPath, Value ) :-
	!,
	find_path_val( Fvals, RestPath, Value ).

find_path_val( [_|Rest], Path, Value ) :-
	find_path_val( Rest, Path, Value ).


set_path_val( Name, Path, Value ) :-
        b_getval( Name, Agent ),
        assign_path_val( Agent, Path, Value, NewAgent ),
	b_setval( Name, NewAgent ).

assign_path_val( [Field^^_|Rest], Field, Value, [Field^^Value|Rest] ) :-
        atomic( Field ), !.
assign_path_val( [Field^^Fvals|Rest], Field^^RestPath, Value, [Field^^NewV|Rest] ) :-
	!,
	assign_path_val( Fvals, RestPath, Value, NewV ).
assign_path_val( [H|Rest1], Path, Value, [H|Rest2] ) :-
	assign_path_val( Rest1, Path, Value, Rest2 ).


add_path_val( Name, Path, Value ) :-
        b_getval( Name, Agent ), % Retrive agent from global database
        addval_path_val( Agent, Path, Value, NewAgent ),
	b_setval( Name, NewAgent ).

addval_path_val( [Field^^L|Rest], Field, Value, [Field^^[Value|L]|Rest] ) :-
	is_list( L ),
	atomic( Field ), !.
addval_path_val( [Field^^Fvals|Rest], Field^^RestPath, Value, [Field^^NewV|Rest] ) :-
	!,
	addval_path_val( Fvals, RestPath, Value, NewV ).
addval_path_val( [H|Rest1], Path, Value, [H|Rest2] ) :-
	addval_path_val( Rest1, Path, Value, Rest2 ).


addq_path_val( Name, Path, Value ) :-
        b_getval( Name, Agent ),
        addqval_path_val( Agent, Path, Value, NewAgent ),
	b_setval( Name, NewAgent ).

addqval_path_val( [Field^^L|Rest], Field, Value, [Field^^Q|Rest] ) :-
	is_list( L ),
	atomic( Field ), !,
	append( L, [Value], Q ).
addqval_path_val( [Field^^Fvals|Rest], Field^^RestPath, Value, [Field^^NewV|Rest] ) :-
	!,
	addqval_path_val( Fvals, RestPath, Value, NewV ).
addqval_path_val( [H|Rest1], Path, Value, [H|Rest2] ) :-
	addqval_path_val( Rest1, Path, Value, Rest2 ).


/*
** short cuts
*/
apv(N,V,P) :- add_path_val(N,V,P).
spv(N,V,P) :- set_path_val(N,V,P).
gpv(N,V,P) :- get_path_val(N,V,P).


/*
** "pretty" print
*/
dmp_agents( [] ).
dmp_agents( [H|T] ) :-
	dmp_agent( H ), 
	nl, nl,
	dmp_agents( T ).

dmp_inst( Name ) :-
	b_getval( Name, Inst ),
	nl,
	pp_agent( Inst, 0 ).

dmp_agent( Name ) :-
	b_getval( Name, Agent ),
	nl,
	pp_agent( Agent, 0 ).

pp_agent( [], _ ).
pp_agent( [Fk^^Fds|Rest], Tab ) :-
	tab( Tab ),
	writeln( Fk ),
	Tab5 is Tab + 5,
	pp_fdvals( Fds, Tab5 ),
	pp_agent( Rest, Tab ).

pp_fdvals( [],_ ).
pp_fdvals( [Fd^^Val|Rest], Tab5 ) :-
	tab( Tab5 ),
	write( Fd ),
	tab( 5 ),
	writeln( Val ),
	pp_fdvals( Rest, Tab5 ).

