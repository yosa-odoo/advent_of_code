This day 05 is a mess.

The first star is easy and the `common.sql` and `query_1.sql` is enough to understand.

The second star is more ... complicated.

- `query_2_old.sql` is theoretically correct but it brut forces all the seeds and reuses the function of the first star;
which takes forever.

- `query_2.sql` is incomplete and waiting for the `poc.sql` to be finished
- `poc.sql` is the lab of trials and errors to find a way to use intervals and pure sql
(which failed as you can see with the plpgsql function)


Seeds interval:

seed_range
'[10,20)'

source_ranges:
'[20,30)'
'[15,30)'
'[12,17)'
'[0,15)'
'[0,9)'

 left_range | intersect_range | right_range
------------+-----------------+-------------
 [10,20)    |                 |
 [10,15)    | [15,20)         |
 [10,12)    | [12,17)         | [17,20)
            | [10,15)         | [15,20)
            |                 | [10,20)



Allen's interval:

[BEFORE] = [BE] = No delta to apply
[INTER] = [IN] = Delta to be applied
[AFTER] = [AF] = No delta to apply

				|------|    	A is fixed
				.      .
				.      .
 				. |--| .		-> Is contained by A
 				[B[IN]A]
 				.      .
 				.      .
				|--|   .		-> Starts A
				[BE][IN]
				.      .
				.      .
				.   |--|		-> Finishes A
				[BE][IN]
				.      .
				.      .
	  		|------|   .		-> Overlaps A
				[IN][AF]
				.      .
				.      .
				|------|		-> Equals A
				[INTER ]
				.      .
				.      .
	|------| 	.	   .		-> Before A
				[AFTER ]
				.      .
				.      .
	 	 |------| 	   .		-> Meets A
	 	 		[AFTER ]
				.      .
				.      .
			|----------|		-> Is finished by A
				[INTER ]
				.      .
				.      .
			|-------------|		-> Contains A
				[INTER ]


