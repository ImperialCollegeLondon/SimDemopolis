% TODO: Write a test for this code
init_socnet(Agents, small_world, [P,K] ) :-
    link_neighboursk(Agents, Agents, P, K ).
    % Institution forming code requires link lengh of at least 1.
    %at_least1_link(Agents, Agents).

/*
% Find nodes in graph a distance of one and two from the specified node
% Next1 and Prev1 are the nodes adjacent to the node of interest
% Next2 and Prev2 are the nodes a distance of 2 away from the node of interest
% i.e. Prev2,Prev1,Next1,Next2
link_neighbours2( [], _ ).
link_neighbours2( [H|T], Agents ) :-
    % agent_inspector(H),
    neighbours2( H, Agents, Next1, Next2 ),

    random_reassign_agent(Agents, H, H_new1),
    random_reassign_agent(Agents, H, H_new2),
    random_reassign_agent(Agents, Next1, Next1_new),
    random_reassign_agent(Agents, Next2, Next2_new),
    % Graph is assumed to be undirected (acquaintances know each other)
    link_agents( H_new1, Next1_new ), % initialises social network path  % TODO: assign these to "dummy networks"
    link_agents( H_new2, Next2_new ),
    link_neighbours2( T, Agents ).*/

link_neighboursk( [], _, _, _ ).
link_neighboursk( [H|T], Agents, P, K ) :-
    neighboursk( H, Agents, K, Next ),
    random_reassign_all_agents( Agents, H, P, Next ),
    link_neighboursk( T, Agents, P, K ).

/*
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
*/

% A and the nodes it connect to are within the Agents list
neighboursk( A, As, K, Next ) :-
    length( Next, K ),
    append( [_,[A|Next],_], As ).
% links from A go past the end of the Agents list
neighboursk( A, As, K, Next ) :-
    length( Next, K ),
    append( N1, N2, Next ),
    append( _, [A|N1], As ),
    prefix( N2, As ).

% random_link_prob( 0.25 ).

random_reassign_all_agents(_, _, _, [] ).
random_reassign_all_agents( Agents, A1, P, [A2|T]  ) :-
    random_reassign_agent(Agents, A1, A1_new, A2, A2_new, P ),
    link_agents( A1_new, A2_new ),
    random_reassign_all_agents( Agents, A1, P, T ).

% TODO: Remove duplicate edges and self-edges
% Randomly reassign double ring network to create a small network
% Reassigns A{x} to A{x}_new. Succeeds with probability P
random_reassign_agent(Agents, A1, A1_new, A2, A2_new, P ) :-
    maybe( P ), !,
    random_member( A1_new, Agents ),
    random_member( A2_new, Agents ).
% As stay the same upon above rule failing
random_reassign_agent( _, A1, A1, A2, A2, _ ).

/*
random_reassign_graph(Agents, [], _).
random_reassign_graph(Agents, [[A1_old,A2_old]|Rest_old], [[A1_new,A2_new]|Rest_new]) :-
    random_reassign_agent(Agents, A1_old, A1_new),
    random_reassign_agent(Agents, A2_old, A2_new),
    random_reassign_graph(Agents, Rest_old, Rest_new).
*/
