/*
** initialise social network
**	ring
**	fully connected
**	random -- G(N,P) each pair of N nodes in Graph G is connected with probability P
*/

init_socnet( Agents, ring, _ ) :-
        link_neighbours( Agents, Agents ).
init_socnet( Agents, fully_connected, _ ) :-
	link_all2all( Agents, Agents ).
init_socnet( Agents, random, [P|_] ) :-
	link_all2some( Agents, P ).

init_socnet( Agents, random1, [P|_] ) :-
	link_all2some( Agents, P ),
	at_least1_link( Agents, Agents ).

init_socnet(Agents, small_world, [P,K,_] ) :-
    link_neighboursk(Agents, Agents, P, K ),
    delete_self_loops( Agents ),
    delete_multi_links( Agents ).

init_socnet(Agents, small_world1, [P,K,_] ) :-
    link_neighboursk(Agents, Agents, P, K ),
    delete_self_loops( Agents ),
    delete_multi_links( Agents ),
    % Institution forming code requires link lengh of at least 1.
    at_least1_link( Agents, Agents ).

init_socnet( Agents, scale_free, [_,_,M] ) :-
    add_node( Agents, M ),
    delete_self_loops( Agents ),
    delete_multi_links( Agents ).

init_socnet( Agents, scale_free1, [_,_,M] ) :-
    add_node( Agents, M ),
    delete_self_loops( Agents ),
    delete_multi_links( Agents ),
    at_least1_link( Agents, Agents ).

init_socnet( Agents, scale_free2, [_,_,M] ) :-
    add_node( Agents, M ),
    delete_self_loops( Agents ),
    delete_multi_links( Agents ),
    delete_largest_hub( Agents ),
    at_least1_link( Agents, Agents ).

link_neighbours( [], _ ).
link_neighbours( [H|T], Agents ) :-
        neighbours( H, Agents, Prev, Next ),
        add_path_val( H, socnet, Next ), % initialises social network path
        add_path_val( H, socnet, Prev ),
        link_neighbours( T, Agents ).

% Returns nodes which are adjacent to A
neighbours( A, [A|Rest], Prev, Next ) :-  % A is at the head of the list
        !,
        Rest = [Next|_],
        last( Rest, Prev ). % part of the list library
neighbours( A, As, Prev, Next ) :- % A is within list As
        append( _, [Prev,A,Next|_], As ), !.
neighbours( A, [Next|Rest], Prev, Next ) :- % A is at the end of the list
        append( _, [Prev,A], Rest ).


link_all2all( [], _ ).
link_all2all( [A|Rest], Agents ) :-
	link_one2rest( A, Agents ),
	link_all2all( Rest, Agents ).

link_one2rest( _, [] ).
link_one2rest( A, [A|T] ) :-
	link_one2rest( A, T ), !.
link_one2rest( A, [H|T] ) :-
	add_path_val( A, socnet, H ),
	link_one2rest( A, T ).

link_all2some( [] , _ ).
link_all2some( [A|Rest], P ) :-
	link_one2some( A, Rest, P ),
	link_all2some( Rest, P ).

link_one2some( _, [], _ ).
link_one2some( A, [H|T], P ) :-
	maybe( P ), !,
	link_agents( A, H ),
	link_one2some( A, T, P ).
link_one2some( A, [_|T], P ) :-
	link_one2some( A, T, P ).

link_agents( A1, A2 ) :-
	get_path_val( A2, socnet, SN ),
	member( A1, SN ), !.
link_agents( A1, A2 ) :-
	add_path_val( A1, socnet, A2 ),
	add_path_val( A2, socnet, A1 ).

at_least1_link( [], _ ).
at_least1_link( [A|Rest], Agents ) :-
	get_path_val( A, socnet, [] ), !,
	delete( Agents, A, AgentsNotA ),
	random_member( X, AgentsNotA ),
	link_agents( A, X ),
	at_least1_link( Rest, Agents ).
at_least1_link( [_|Rest], Agents ) :-
	at_least1_link( Rest, Agents ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Small-World network generation
% Added for the network topology project by James Arnold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

link_neighboursk( [], _, _, _ ).
link_neighboursk( [H|T], Agents, P, K ) :-
    neighboursk( H, Agents, K, Next ),
    random_reassign_all_agents( Agents, H, P, Next ),
    link_neighboursk( T, Agents, P, K ).


% A and the nodes it connect to are within the Agents list
neighboursk( A, Agents, K, Next ) :-
    length( Next, K ),
    append( [_,[A|Next],_], Agents ).
% links from A go past the end of the Agents list
neighboursk( A, Agents, K, Next ) :-
    length( Next, K ),
    append( N1, N2, Next ),
    append( _, [A|N1], Agents ),
    prefix( N2, Agents ).

% random_link_prob( 0.25 ).

random_reassign_all_agents(_, _, _, [] ).
random_reassign_all_agents( Agents, A1, P, [A2|T]  ) :-
    random_reassign_agent(Agents, A1, A1_new, A2, A2_new, P ),
    link_agents( A1_new, A2_new ),
    random_reassign_all_agents( Agents, A1, P, T ).

% Randomly reassigns a k-link ring network to create a small network
% Reassigns A{x} to A{x}_new. Succeeds with probability P
random_reassign_agent(Agents, A1, A1_new, A2, A2_new, P ) :-
    maybe( P ), !,
    random_member( A1_new, Agents ),
    random_member( A2_new, Agents ).
% A1 and A2 stay the same upon above rule failing
random_reassign_agent( _, A1, A1, A2, A2, _ ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scale Free Network Generation
% Added for the network topology project by James Arnold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% self-loops are allowed. They are negligible when the graph becomes large.
%% The double path is to account for the fact that the node has connectivity 2
%% TODO: check if this bit is needlessly complicated
add_node( [], _ ).
add_node( [H|T], M ) :-
    add_node( T, M ), !,
    add_link( [H|T], M, 0 ).

add_link( _, M, M ).
add_link( [H|T], M, L  ):-
    length( [H|T], Time ),
    Max is 2*M*(Time-1) + (2*L) + 1,
    random_between( 1, Max, Len_Target ),
    pref_attach_link( H, [H|T], Len_Target, 1 ),
    New_L is L + 1,
    add_link( [H|T], M, New_L ).

%% add links through preferential attachment
/*pref_attach_link( A, [A|T], Len_Target, Old_Len ) :-
    add_node_connectivity( A, Old_Len, New_Len ),
    New_Len >= Len_Target.*/
pref_attach_link( A, [H|T], Len_Target, Old_Len ) :-
    add_node_connectivity( H, Old_Len, New_Len ),
    New_Len >= Len_Target,
    add_path_val( A, socnet, H ),
    add_path_val( H, socnet, A ).
pref_attach_link( A, [H|T], Len_Target, Old_Len ) :-
    add_node_connectivity( H, Old_Len, New_Len ),
    pref_attach_link( A, T, Len_Target, New_Len ).

add_node_connectivity( A, Old_Len, New_Len ) :-
    get_path_val( A, socnet, SN ),
    length( SN,Ki ),
    New_Len is Old_Len + Ki.


delete_self_loops( [] ).
delete_self_loops( [A|Rest] ) :-
    get_path_val( A, socnet, SN ),
    remove_selfs_from_sn( A, SN, New_SN ),
    set_path_val( A, socnet, New_SN ),
    delete_self_loops( Rest ).

% remove all instances of A from list SN
% If no self-loops found, do nothing
remove_selfs_from_sn( A, SN, SN ):-
    \+ member( A, SN ).
remove_selfs_from_sn( A, SN, SN3 ) :-
    select( A, SN, SN2 ),
    remove_selfs_from_sn( A, SN2, SN3 ).

delete_multi_links( [] ).
delete_multi_links( [A|Rest] ) :-
    get_path_val( A, socnet, SN ),
    % remove duplicates
    list_to_set( SN, New_SN ),
    set_path_val( A, socnet, New_SN ),
    delete_multi_links( Rest ).

% Remove links to the largest hub in the social network. Leave it with a single
% link so SimDemopolis still works
delete_largest_hub( Agents ) :-
    highest_degree( Agents, _, _, A ),
    delete_links2A( A, Agents ),
    set_path_val( A, socnet, [] ).

delete_links2A( _, [] ).
delete_links2A( A, [H|T] ) :-
    get_path_val( H, socnet, SN ),
    \+ member( A, SN ),
    delete_links2A( A, T ).
delete_links2A( A, [H|T] ) :-
    get_path_val( H, socnet, SN ),
    select( A, SN, SN2 ),
    set_path_val( H, socnet, SN2 ),
    delete_links2A( A, T ).

highest_degree( [], 0, _, _ ).
highest_degree( [H|T], Old_Highest, Old_Highest, H ) :-
    highest_degree( T, Old_Highest, _, _  ),
    get_path_val( H, socnet, SN ),
    length( SN, K ),
    K =< Old_Highest.

highest_degree( [H|T], K, Old_Highest, _ ) :-
    highest_degree( T, Old_Highest, _, _  ),
    get_path_val( H, socnet, SN ),
    length( SN, K ),
    K > Old_Highest.
