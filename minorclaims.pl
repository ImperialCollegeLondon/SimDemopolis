
mcp( I, Ex, New, refuse, resign, (Role,Rule) ) :-
        get_path_val( I, utr, UTR ),
	extract_data( UTR, [], RawData ),
	msort( RawData, SRD ),
	split_list( SRD, _, HiHalf ),
	calculate_upper_quartile( HiHalf, Q3 ),
	member( (Ex,T), UTR ),
	T > Q3, !,
	set_path_val( I, knowcode^^Rule^^roles^^Role, New ),
	write( Ex ), write( ' was sacked as ' ), write( Role ), nl.
mcp( _, Ex, _, refuse, resign, _ ) :-
	write( Ex ), write( ' was let off resigning ' ), nl.

	

mcp( I, New, refuse, serve, (Role,Rule) ) :-
        get_path_val( I, utr, UTR ),
	extract_data( UTR, [], RawData ),
	msort( RawData, SRD ),
	split_list( SRD, LoHalf, _ ),
	calculate_lower_quartile( LoHalf, Q1 ),
	member( (New,T), UTR ),
	T < Q1, !,
	set_path_val( I, knowcode^^Rule^^roles^^Role, New ),
	write( New ), write( ' was coerced to be ' ), write( Role ), nl.
mcp( _, New, refuse, serve, _ ) :-
	write( New ), write( ' was let off serving ' ), nl.

