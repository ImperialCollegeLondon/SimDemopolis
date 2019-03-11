% TODO: Write a test for this code

:- use_module(library(lists)).

:- op( 500, xfy, ^^ ).

load_parent() :-
    working_directory(_, ".."),
    ensure_loaded([access,institution,agents,pprint,network]),
    working_directory(_, "Development"),
    write("Loaded Parent Files"), nl.

% Load small world code from Deelopment directory
test_small_world() :-
    load_parent(),
    ensure_loaded([small_world]),
    write("Small World functions loaded successfully"), nl.

create_small_world() :-
    test_small_world(),
    make_institution( I ),
    write("Institution I: "), write(I), nl,
    make_agents( Agents ),
    write("Agents made: "), write(Agents), nl,
        register( I, Agents ),   % Agents are registered to institution I
    init_socnet2( Agents, small_world ),
    write("Small world network initialized"), nl.
