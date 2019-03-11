% TODO: Write a test for this code
:- write("In the file").
init_socnet2(Agents, small_world) :-
    write("In small world code"),
    link_neighbours2(Agents, Agents).

% Find nodes in graph a distance of one and two from the specified node
% Next1 and Prev1 are the nodes adjacent to the node of interest
% Next2 and Prev2 are the nodes a distance of 2 away from the node of interest
% i.e. Prev2,Prev1,Next1,Next2
link_neighbours2( [], _ ).
link_neighbours2( [H|T], Agents ) :-
    write("Linking Neighbours"),
    neighbours2( H, Agents, Next1, Next2 ),  % TODO: Remove Prev1 and Prev2 from this. They are redundant

    random_reassign_agent(Agents, H, H_new1),
    random_reassign_agent(Agents, H, H_new2),
    random_reassign_agent(Agents, Next1, Next1_new),
    random_reassign_agent(Agents, Next2, Next2_new),
    add_path_val( H_new1, socnet, Next1_new ), % initialises social network path  % TODO: assign these to "dummy networks"
    add_path_val( H_new2, socnet, Next2_new ),
    link_neighbours2( T, Agents ).

% Returns nodes a distance of 2 away from A. There is probably a more elegant way
% of implementing this, but I don't know what it is.
% This requires a network size > 5.
neighbours2( A, [A|Rest], Next1, Next2 ) :-  % A is at the head of the list
    !,
    Rest = [Next1, Next2|_].
neighbours2( A, [_,A|Rest],  Next1, Next2 ) :- % A is 2nd element of list
    !,
    Rest = [Next1, Next2|_].
neighbours2( A, As, Next1, Next2 ) :- % A is within list As
    append( _, [A,Next1,Next2|_], As ), !.
neighbours2( A, [Next2|Rest], Next1, Next2 ) :- % A is 2nd to last in the list
    gtrace,
    append( _, [A,Next1], Rest ), !.
neighbours2( A, [Next1,Next2|Rest], Next1, Next2 ) :- % A is at the end of the list
    last(Rest, A).

/*
% Returns nodes which are adjacent to A
neighbours1( A, [A|Rest], Prev1, Next1 ) :-  % A is at the head of the list
    !,
    Rest = [Next1|_],
    last( Rest, Prev1 ). % part of the list library
neighbours1( A, As, Prev1, Next1 ) :- % A is within list As
    append( _, [Prev1,A,Next1|_], As ), !.
neighbours1( A, [Next1|Rest], Prev1, Next1 ) :- % A is at the end of the list
    append( _, [Prev1,A], Rest ).
*/


/*
link_all2some( [] ).
link_all2some( [A|Rest] ) :-
	link_one2some( A, Rest ),
	link_all2some( Rest ).

link_one2some( _, [] ).
link_one2some( A, [H|T] ) :-
	random_link_prob( P ),
	maybe( P ), !,
	link_agents( A, H ),
	link_one2some( A, T ).
link_one2some( A, [_|T] ) :-
	link_one2some( A, T ).

link_agents( A1, A2 ) :-
	get_path_val( A2, socnet, SN ),
	member( A1, SN ), !.
link_agents( A1, A2 ) :-
	add_path_val( A1, socnet, A2 ),
	add_path_val( A2, socnet, A1 ).
*/

% random_link_prob( 0.25 ).

% Randomly reassign double ring network to create a small network
random_reassign_agent(Agents, _, A_new) :- % Reassigns A. Succeeds with probability P
    random_link_prob( P ),
    maybe( P ), !,
    random_member( A_new, Agents ).
random_reassign_agent(_, A, A). % A stays the same upon above rule failing

/*
random_reassign_graph(Agents, [], _).
random_reassign_graph(Agents, [[A1_old,A2_old]|Rest_old], [[A1_new,A2_new]|Rest_new]) :-
    random_reassign_agent(Agents, A1_old, A1_new),
    random_reassign_agent(Agents, A2_old, A2_new),
    random_reassign_graph(Agents, Rest_old, Rest_new).
*/
