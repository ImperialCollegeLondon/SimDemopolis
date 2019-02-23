
outliers( I, LoOut, HiOut ) :-
	get_path_val( I, utr, TinR ),
	extract_data( TinR, [], RawData ),
	compute_quartiles( RawData, IFlo, IFHi, OFLo, OFHi ),
	identify_outliers( TinR, IFlo, IFHi, OFLo, OFHi, [], [], LoOut, HiOut ),
	true.

identify_outliers( [], _, _, _, _, LoOut, HiOut, LoOut, HiOut ).

identify_outliers( [(A,T)|Rest], _, _, OFLo, OFHi, SoFarLo, SoFarHi, LoOut, HiOut ) :-
	T < OFLo, !,
	identify_outliers( Rest, _, _, OFLo, OFHi, [A|SoFarLo], SoFarHi, LoOut, HiOut ).
identify_outliers( [(A,T)|Rest], _, _, OFLo, OFHi, SoFarLo, SoFarHi, LoOut, HiOut ) :-
        T > OFHi, !,
        identify_outliers( Rest, _, _, OFLo, OFHi, SoFarLo, [A|SoFarHi], LoOut, HiOut ).
identify_outliers( [_|Rest], _, _, OFLo, OFHi, SoFarLo, SoFarHi, LoOut, HiOut ) :-
	identify_outliers( Rest, _, _, OFLo, OFHi, SoFarLo, SoFarHi, LoOut, HiOut ).
	

compute_quartiles( RawData, IFLo, IFHi, OFLo, OFHi ) :-
	msort( RawData, SRD ),
	calculate_median( SRD, Median ), whydoweneedthemedian( Median ),
	split_list( SRD, LoHalf, HiHalf ),
	calculate_lower_quartile( LoHalf, Q1 ),
	calculate_upper_quartile( HiHalf, Q3 ),
	calculate_interquartile_range( Q1, Q3, IQR ),
	calculate_inner_fence( Q1, Q3, IQR, IFLo, IFHi ),
	calculate_outer_fence( Q1, Q3, IQR, OFLo, OFHi ),
	true. %identify_outliers( TinR, InnerFence, OuterFence, Minor, Major ).

whydoweneedthemedian( _ ).

extract_data( [], RawData, RawData ).
extract_data( [(_,T)|L], SoFar, RawData ) :-
	extract_data( L, [T|SoFar], RawData ).

calculate_median( SRD, Median ) :-
	length( SRD, L ),
	odd_or_even( SRD, L, Median ).

odd_or_even( SRD, L, Median ) :-
	1 is L mod 2, !,
	M is L div 2,
	nth0( M, SRD, Median ).
odd_or_even( SRD, L, Median ) :-
	M is L div 2,
	M1 is M + 1,
	nth1( M, SRD, E ),
	nth1( M1, SRD, E1 ),
	Median is (E+E1)/2. 

split_list( SRD, LoHalf, HiHalf ) :-
	length( SRD, L ), 
	M is L div 2,
	split_oddeven( SRD, M, LoHalf, HiHalf ).

split_oddeven( SRD, M, LoHalf, HiHalf ) :-	
	1 is M mod 2, !,
	append( LoHalf, [_|HiHalf], SRD ),
	length( LoHalf, M ).
split_oddeven( SRD, M, LoHalf, HiHalf ) :-	
	append( LoHalf, HiHalf, SRD ),
        length( LoHalf, M ).

calculate_lower_quartile( LoHalf, Q1 ) :-
	calculate_median( LoHalf, Q1 ).

calculate_upper_quartile( HiHalf, Q3 ) :-
        calculate_median( HiHalf, Q3 ).

calculate_interquartile_range( Q1, Q3, IQR ) :-
	IQR is Q3 - Q1.

calculate_inner_fence( Q1, Q3, IQR, IFlo, IFhi ) :-
	IFlo is Q1 - (IQR*1.5),
	IFhi is Q3 + (IQR*1.5).

calculate_outer_fence( Q1, Q3, IQR, IFlo, IFhi ) :-
        IFlo is Q1 - (IQR*3),
        IFhi is Q3 + (IQR*3).

%71, 70, 73, 70, 70, 69, 70, 72, 71, 300, 71, 69
