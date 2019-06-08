%% create new agent object

new_agent( Name ) :-
        Agent = [
		 agt^^Name,
		 msgq^^[],
	         socnet^^[],
		 citizenship^^1,
		 off^^[opn^^0.0, sconf^^0.0, mu^^0.0, oij^^[], wij^^[], aij^^[]]
                ],
        b_setval( Name, Agent ).  % Set global variable Name to Agent list


%% create agents

make_agents( Agents, N ) :-
    %hard_wired_agents( Agents ), !, % Agents set to the list defined in hard_wired_agents
    generate_agents_list( Agents, N ), !,
    make_each_agent( Agents ).  % Each agent in the generate_agents_list list is created individually

make_agents( Agents, _ ) :-
        make_each_agent( Agents ).

make_each_agent( [] ).
make_each_agent( [H|T] ) :-
        new_agent( H ),
        make_each_agent( T ).

% Agents pre-specified for consistency. These will form the society of SimDemopolis
/*
%hard_wired_agents( [ann, bob, chr, dan, eve] ).
%hard_wired_agents( [ann, bob, chr, dan, eve, fre, geo, hal, ian, jez] ).
hard_wired_agents( [ann, bob, chr, dan, edd, fre, geo, hal, ian, jez,
                    k8e, lez, mik, nob, osc, phl, que, rob, sam, tim,
                    urs, vik, wdy, xen, zeb, aar, bbo, cca, dda, eek] ).
%hard_wired_agents( [ann, bob, chr, dan, edd, fre, geo, hal, ian, jez,
                    %k8e, lez, mik, nob, osc, phl, que, rob, sam, tim,
                    %urs, vik, wdy, xen, yak, zeb, aar, bbo, cca, dda,
		    %eek, ffk, ggg, hh8, iic, jjf, kkk, lbw, mmu, nno,
%ooh, ppe, q4a, rrs, sst, tt2, uuc, vvv, wxy, xxx, why, zzt] ).*/

% Generate list of Agents, whose names are integers from 1 to N. This allows
% the network size to be specified easily.
generate_agents_list( [], 0 ).
generate_agents_list( [N_str|T], N ):-
    format(atom(N_str), 'a~:d', N),
    New_N is N-1,
    generate_agents_list( T, New_N ).

/*
gini( [(ann,11),(bob,11),(chr,11),(dan,11),(eve,1),(fre,1),(geo,1),(hal,1),(ian,1),(jez,1)], G ).
gini( [(ann,11),(bob,11),(eve,1),(ian,1)], G ).
gini( [(ann,11),(bob,11),(chr,11),(dan,11),(eve,1),(fre,1),(geo,1),(hal,1),(ian,1),(jez,1)], G ).
gini( [(ann,11),(bob,11),(chr,11),(dan,11),(eve,1),(fre,1),(geo,1),(hal,1),(ian,1),(jez,1)], G ).
gini( [(ann,11),(bob,11),(chr,11),(dan,11),(eve,1),(fre,1),(geo,1),(hal,1),(ian,1),(jez,1)], G ).
*/
