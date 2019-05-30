% TODO: Check this works thoroughly. Write it down to prove it.
init_socnet( Agents, scale_free ) :-
    add_node( Agents ).

%% self-loops are allowed. They are negligible when the graph becomes large.
%% The double path is to account for the fact that the node has connectivity 2
%% TODO: check if this bit is needlessly complicated
add_node( [] ).
/*add_node( [H] , H) :-
    add_path_val( H, socnet, H ),
    add_path_val( H, socnet, H ).*/
add_node( [H|T] ) :-
    add_node( T ),
    length( [H|T], Time),
    Max is 2 * Time - 1,
    random_between(1, Max, Len_Target),
    pref_attach_link( H, [H|T], Len_Target, 1).

%% add links through preferential attachment
pref_attach_link( A, [H|T], Len_Target, Old_Len) :-
    add_node_connectivity( H, Old_Len, New_Len ),
    New_Len >= Len_Target,
    add_path_val( A, socnet, H),
    add_path_val( H, socnet, A).
pref_attach_link( A, [H|T], Len_Target, Old_Len) :-
    add_node_connectivity( H, Old_Len, New_Len ),
    pref_attach_link(A, T, Len_Target, New_Len).
add_node_connectivity( A, Old_Len, New_Len ) :-
    get_path_val( H, socnet, SN ),
    length(SN,Ki),
    New_Len is Old_Len + Ki.

% Find nodes in graph a distance of one and two from the specified node
% Next1 and Prev1 are the nodes adjacent to the node of interest
% Next2 and Prev2 are the nodes a distance of 2 away from the node of interest
% i.e. Prev2,Prev1,Next1,Next2
link_neighbours2( [], _ ).
link_neighbours2( [H|T], Agents ) :-
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
    %gtrace,
    append( _, [A,Next1], Rest ), !.
neighbours2( A, [Next1,Next2|Rest], Next1, Next2 ) :- % A is at the end of the list
    last(Rest, A).



% random_link_prob( 0.25 ).

% TODO: Remove duplicate edges and self-edges
% Randomly reassign double ring network to create a small network
random_reassign_agent(Agents, A, A_new) :- % Reassigns A to A_new. Succeeds with probability P
    random_link_prob( P ),
    maybe( P ), !,
    random_member( A_new, Agents ),
    A_new \= A.
random_reassign_agent(_, A, A). % A stays the same upon above rule failing

/*
random_reassign_graph(Agents, [], _).
random_reassign_graph(Agents, [[A1_old,A2_old]|Rest_old], [[A1_new,A2_new]|Rest_new]) :-
    random_reassign_agent(Agents, A1_old, A1_new),
    random_reassign_agent(Agents, A2_old, A2_new),
    random_reassign_graph(Agents, Rest_old, Rest_new).
*/
