
/*
** resource allocation framework and loop
*/

resource_allocation_loop( I ) :-
	play_ten_rounds( I ),
	update_time_in_roles( I ).


play_ten_rounds( _ ).

update_time_in_roles( I ) :-
	get_path_val( I, knowcode^^participation^^roles^^chair, Fndr ),
	get_path_val( I, knowcode^^role_assign^^roles^^director, Allo ),
        get_path_val( I, knowcode^^access_control^^roles^^axcontroller, Fran ),
        get_path_val( I, knowcode^^resource_alloc^^roles^^allocator, Chai ),
        get_path_val( I, knowcode^^minor_claims^^roles^^judge, Alan ),
	update_time_in_role( I, Fndr, 1 ),
	update_time_in_role( I, Allo, 1 ),
	update_time_in_role( I, Fran, 1 ),
	update_time_in_role( I, Chai, 1 ),
	update_time_in_role( I, Alan, 1 ),
	update_utr( I, Fndr, 1 ),
	update_utr( I, Allo, 1 ),
	update_utr( I, Fran, 1 ),
	update_utr( I, Chai, 1 ),
	update_utr( I, Alan, 1 ),
	update_rolehistory( I, (Fndr,Allo,Fran,Chai,Alan) ).

update_rolehistory( I, Roles ) :-
	get_path_val( I, rolehistory, RH ),
	get_path_val( I, rhwindow, Window ),
	length( RH, L ),
	L < Window, !,
	set_path_val( I, rolehistory, [Roles|RH] ).
update_rolehistory( I, Roles ) :-
	get_path_val( I, rolehistory, RH ),
	remove_last( RH, First, (X,A,F,C,M) ),
	set_path_val( I, rolehistory, [Roles|First] ),
	update_time_in_role( I, X, -1 ),
	update_time_in_role( I, A, -1 ),
	update_time_in_role( I, F, -1 ),
	update_time_in_role( I, C, -1 ),
	update_time_in_role( I, M, -1 ).
	

update_time_in_role( I, A, X ) :-
	get_path_val( I, timeinrole, TinR ),
	find_and_replace( A, TinR, NewTinR, X ),
	set_path_val( I, timeinrole, NewTinR ).

update_utr( I, A, X ) :-
	get_path_val( I, utr, TinR ),
	find_and_replace( A, TinR, NewTinR, X ),
	set_path_val( I, utr, NewTinR ).

find_and_replace( A, [(A,T)|L], [(A,T1)|L], X ) :-
	T1 is T + X,
	!.
find_and_replace( A, [(B,T)|L1], [(B,T)|L2], X ) :-
	find_and_replace( A, L1, L2, X ).

remove_last( [Last], [], Last ) :- !.
remove_last( [H|T1], [H|T2], Last ) :-
	remove_last( T1, T2, Last ).
