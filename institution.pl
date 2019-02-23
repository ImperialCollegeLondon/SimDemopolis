
new_institution( Name ) :-
  Inst = [ 
    inst^^Name, 
    members^^[], 
    players^^[], 
    timeinrole^^[],
    rolehistory^^[],
    rhwindow^^10,
    utr^^[],
    immutable_rules^^[ 
	constitution^^[ 
	    enactment,
 	    amendment,
	    repeal,
	    transmute
	]
    ],
    mutable_rules^^[
        participation,
	legislation^^[ 
	    role_assignment,
            access_control,
            resource_alloc,
            minor_claims
        ]
    ],
    knowcode^^[
	participation^^[
	    call^^particip_check,
   	    roles^^[
		chair^^_,
		franchised^^[]
   	    ],
	    powers^^[
		chair^^[cfv, declare, resign],
		monitors^^[vote]
	    ],
	    dof^^[
		who^^all, 
		extent^^equal
	    ]
	],
	role_assign^^[
	    call^^rap_protocol,
   	    roles^^[
		director^^_,
		racomm^^[]
   	    ],
	    powers^^[
		director^^[cfv, assign, invite, resign],
		racomm^^[vote]
	    ],
	    dof^^[
		ram^^voting, %finger
		wdm^^plurality
	    ]
	],
	access_control^^[
	    call^^ac_control,
   	    roles^^[
		axcontroller^^_,
		axcomm^^[]
   	    ],
	    powers^^[
		axcontroller^^[cfv, admit, eject, resign],
		axcomm^^[vote]
	    ],
	    dof^^[
		wdm^^borda
	    ]
	],
	resource_alloc^^[
	    call^^lpg_game,
   	    roles^^[
		allocator^^_,
		players^^[]
   	    ],
	    powers^^[
		allocator^^[allocate, resign],
		players^^[provide, request]
	    ],
	    dof^^[
		ra_method^^roles_first
	    ]
	],
	minor_claims^^[
	    call^^mcp,
            roles^^[
		judge^^_,
                foreperson^^_,
		proponent^^_,
		opponent^^_,
                jurors^^[]
            ],
            powers^^[
                judge^^[open, close, sentence],
		foreperson^^[find],
		proponent^^[submit],
		opponent^^[submit],
                jurors^^[vote]
            ],
            dof^^[
		adjm^^jury, %mediation, negotiation
                jurysize^^12,
		decision^^unanimous
            ]
        ]
    ],
    sanctions
  ],
  b_setval( Name, Inst ).


%% make institutions

make_institution( Institution ) :-
        hard_wired_institution( Institution ), !,
        new_institution( Institution ).

hard_wired_institution( i ).


%% register agents with institution

register( _, [] ).

register( I, [H|T] ) :-
        add_path_val( I, members, H ),
        register( I, T ).


%% assign one agent (founder) at random to the chair role

founder( I ) :-
	get_path_val( I, members, M ),
	random_member( X, M ),
	set_path_val( I, knowcode^^role_assign^^roles^^director, X ),
	set_path_val( I, knowcode^^role_assign^^roles^^racomm, M ).


%% ab origine all members are franchised

universal_suffrage( I ) :-
	get_path_val( I, members, M ),
	set_path_val( I, franchised, M ).


init_citizenship( I ) :-
	get_path_val( I, members, M ),
	init_cit( M ).

init_cit( [] ).
init_cit( [H|T] ) :-
	set_path_val( H, citizenship, 1 ),
	init_cit( T ).

%% initialise legislation

init_participation_chk( I, participation ) :-
	get_path_val( I, members, M ),
	get_path_val( I, knowcode^^role_assign^^call, G ),
	Goal =.. [G, I, role(chair, participation), M],
	call( Goal ),
	set_path_val( I, knowcode^^participation^^roles^^franchised, M ).

init_access_control( I, access_control ) :-
	get_path_val( I, members, M ),
	get_path_val( I, knowcode^^role_assign^^call, G ),
	Goal =.. [G, I, role(axcontroller, access_control), M],
	call( Goal ),
	set_path_val( I, knowcode^^access_control^^roles^^axcomm, M ).

init_resource_alloc( I, resource_alloc ) :-
	get_path_val( I, members, M ),
	get_path_val( I, knowcode^^role_assign^^call, G ),
	Goal =.. [G, I, role(allocator, resource_alloc), M],
	call( Goal ).

init_minor_claims( I, minor_claims ) :-
	get_path_val( I, members, M ),
	get_path_val( I, knowcode^^role_assign^^call, G ),
	Goal =.. [G, I, role(judge, minor_claims), M],
	call( Goal ).

init_role_assignment( I, role_assign ) :-
	get_path_val( I, members, M ),
	get_path_val( I, knowcode^^role_assign^^call, G ),
	Goal =.. [G, I, role(director, role_assign), M],
	call( Goal ),
	set_path_val( I, knowcode^^role_assign^^roles^^racomm, M ).
	
	








%% assign roles at start by voting or at random

assign_roles( I, voting ) :-
        get_path_val( I, members, A ),
        voting_protocol( I, role^^allocator, A ),
        voting_protocol( I, role^^axcontrol, A ),
        voting_protocol( I, role^^arbiter, A ),
        voting_protocol( I, role^^chair, A ).

assign_roles( I, random ) :-
        get_path_val( I, members, A ),
        random_member( Head, A ),
        random_member( Axco, A ),
        random_member( Chair, A ),
        random_member( Moni, A ),
        assign_role( I, allocator, Head ),
        assign_role( I, axcontrol, Axco ),
        assign_role( I, chair, Chair ),
        assign_role( I, arbiter, Moni ).

assign_role( I, Role, Agent ) :-
        set_path_val( I, roles^^Role, Agent ).

init_timeinrole( I ) :-
	get_path_val( I, members, A ),
	init_to_1( A, [], L ),
	set_path_val( I, timeinrole, L ).

init_utr( I ) :-
	get_path_val( I, members, A ),
	init_to_1( A, [], L ),
	set_path_val( I, utr, L ).

init_to_1( [], L, L ).
init_to_1( [A|T], SoFar, L ) :-
	init_to_1( T, [(A,1)|SoFar], L ).

