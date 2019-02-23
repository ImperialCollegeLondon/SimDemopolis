/*
** Communications Module
*/

/*
** send_msg( FromAg, ToAg, Msg )
**	adds FromAg^^Msg to end of ToAg's msgq 
*/
send_msg( From, To, Msg ) :-
	addq_path_val( To, msgq, From^^Msg ).

/*
** read_msg( Agent, From, Msg )
**	returns first sender^^message in agnt^^msgq
**	removes head of agnt^^msgq and updates to tail
**	returns unbound variable and empty list if no messages to read
** read_msg_fail( Agent, From, Msg )
**	as above but fails if agnt^^msgq is empty
*/
read_msg( Agent, From, Msg ) :-
	get_path_val( Agent, msgq, [From^^Msg|T] ), !,
	set_path_val( Agent, msgq, T ).
read_msg( Agent, _, [] ) :-
	get_path_val( Agent, msgq, [] ).

read_msg_fail( Agent, From, Msg ) :-
        get_path_val( Agent, msgq, [From^^Msg|T] ),
        set_path_val( Agent, msgq, T ).

peek_msgq_empty( Agent ) :-
        get_path_val( Agent, msgq, [] ).

/*
process_msgs( Agent ) :-
	read_msg_loop( Agent ).

read_msg_loop( Agent ) :-
	get_path_val( Agent, msgq, [] ).
read_msg_loop( Agent ) :-
	read_msg( Agent ),
	read_msg_loop( Agent ).
*/

