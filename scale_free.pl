% TODO: Check this works thoroughly. Write it down to prove it.
init_socnet( Agents, scale_free, [] ) :-
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
