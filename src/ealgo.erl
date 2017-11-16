-module(ealgo).
-include("ealgo.hrl").
-export([cartesian_product/1]).
-export([combinations/1, combinations/2]).
-export([permutations/1, permutations/2]).
-export([next_permutation/1]).
-export([sign/1, boole/1, ustep/1]).
-export([rabin_karp/2, rabin_karp/3]).


%% https://en.wikipedia.org/wiki/Cartesian_product
%% Gives the cartesian product of a list of list.
-spec cartesian_product(L :: [list()]) ->
    R :: [list()].
cartesian_product([     ]) -> [[]];
cartesian_product([A | T]) ->
    B = cartesian_product(T),
    [[X | Y] || X <- A, Y <- B].


%% Gives all combinations of L. 
-spec combinations(L :: [term()]) ->
    R :: [list()].
combinations([     ]) -> [[]];
combinations([H | T]) ->
    A = B = combinations(T),
    A ++ [[H | Y] || Y <- B].


%% Gives all combinations of L containing exactly N elements.
-spec combinations(L :: [term()], N :: non_neg_integer()) ->
    R :: [list()].
combinations(L, N) when not is_list(L)
                      ; not is_integer(N)
                      ; not (N >= 0) ->
    erlang:error(badarg);
combinations(   _   , 0) -> [[]];
combinations([     ], _) -> [  ];
combinations([H | T], N) ->
    A = combinations(T, N - 1),
    B = combinations(T, N    ),
    [[H | X] || X <- A] ++ B.


%% Gives all permutations of L.
-spec permutations(L :: [term()]) ->
    R :: [list()].
permutations([]) -> [[]];
permutations(L) when is_list(L) ->
    permutations_h1(L, []).
permutations_h1([     ], _) -> [];
permutations_h1([H | T], C) ->
    A = permutations(lists:reverse(C, T)),
    B = permutations_h1(T, [H | C]),
    [[H | X] || X <- A] ++ B.


%% Gives all permutations of L containing exactly N elements.
-spec permutations(L :: [term()], N :: non_neg_integer()) ->
    R :: [list()].
permutations(L, N) when not is_list(L)
                      ; not is_integer(N)
                      ; not (N >= 0) ->
    erlang:error(badarg);
permutations( _ , 0) -> [[]];
permutations([ ], _) -> [  ];
permutations( L , N) ->
    permutations_h2(L, N, []).
permutations_h2([     ], _, _) -> [];
permutations_h2([H | T], N, C) ->
    A = permutations(lists:reverse(C, T), N - 1),
    B = permutations_h2(T, N, [H | C]),
    [[H | X] || X <- A] ++ B.


%% Gives the next permutation of L.
-spec next_permutation(L :: [term()]) ->
    {true, R :: [term()]} | false.
next_permutation(L) when is_list(L) ->
    next_permutation_h1(lists:reverse(L), []).
next_permutation_h1([J, I | A], B) when I < J ->
    S = next_permutation_h2([I | lists:reverse(B, [J])], []),
    {true, lists:reverse(A, S)};
next_permutation_h1([H | A], B) ->
    next_permutation_h1(A, [H | B]);
next_permutation_h1(_, _) -> false.
next_permutation_h2([I, J | A], B) when I < J ->
    [J | lists:reverse(B, [I | A])];
next_permutation_h2([I, H | A], B) ->
    next_permutation_h2([I | A], [H | B]).



%% Gives -1, 0, or 1 depending on whether X is negative, zero, or positive.
-spec sign(X :: number()) ->
    S :: -1 | 0 | 1.
sign(X) when not is_integer(X)
           , not is_float(X) ->
    erlang:error(badarg);
sign(X) when X > 0 ->  1;
sign(X) when X < 0 -> -1;
sign(_)            ->  0.


%% Yields 1 if Expr is true and 0 if it is false.
-spec boole(Expr :: boolean()) ->
    R :: 0 | 1.
boole( true) -> 1;
boole(false) -> 0.


%% Represents the unit step function, equal to 0
%% for X < 0 and 1 for X >= 0.
-spec ustep(X :: number()) ->
    R :: 0 | 1.
ustep(X) when not is_integer(X)
            , not is_float(X) ->
    erlang:error(badarg);
ustep(X) when X >= 0 -> 1;
ustep(_)             -> 0.


%% https://en.wikipedia.org/wiki/Rabin%E2%80%93Karp_algorithm
%% Gives a list of the starting character positions at which
%% Pattern appears as a substring of String.
-spec rabin_karp(String :: string(), Pattern :: string()) ->
    PositionList :: [pos_integer()].
rabin_karp(String, Pattern) when is_list(String), is_list(Pattern) ->
    rabin_karp(String, Pattern, -1).


%% Includes the first N occurrences of Pattern, all if N < 0.
-spec rabin_karp(String :: string(), Pattern :: string(), N :: integer()) ->
    PositionList :: [pos_integer()].
rabin_karp(String, Pattern, N) when  length(String) < length(Pattern), is_integer(N) ->
    [];
rabin_karp(String, Pattern, N) when is_list(String), is_list(Pattern), is_integer(N) ->
    MSB = ealgo_ntl:power_mod(Base = 257, PatSize = length(Pattern), Modu = 1299709),
    Iterate = fun(Hash, Out, In) ->
        ealgo_ntl:remainder((Hash * Base) - (Out * MSB) + In, Modu)
    end,
    PatHash = lists:foldl(fun(X, Acc) -> Iterate(Acc, 0, X) end, 0, Pattern),
    Accept = fun(OutList, WinHash) ->
        (PatHash =:= WinHash) andalso lists:prefix(Pattern, OutList)
    end,
    {Window, InList} = lists:split(PatSize, OutList = String),
    WinHash = lists:foldl(fun(X, Acc) -> Iterate(Acc, 0, X) end, 0, Window),
    rabin_karp_h1(Iterate, Accept, 1, OutList, WinHash, Accept(String, WinHash), InList, N, []).

rabin_karp_h1(_, _,   _, _, _,     _,  _, 0, Acc) -> lists:reverse(Acc, [   ]);
rabin_karp_h1(_, _,   _, _, _, false, [], _, Acc) -> lists:reverse(Acc, [   ]);
rabin_karp_h1(_, _, Pos, _, _,  true, [], _, Acc) -> lists:reverse(Acc, [Pos]);
rabin_karp_h1(Iterate, Accept, Pos, [Out | OutList2], WinHash, IsMatch, [In | InList2], N, Acc) ->
    WinHash2 = Iterate(WinHash, Out, In), IsMatch2 = Accept(OutList2, WinHash2),
    case IsMatch of
        false -> Pos2 = Pos + 1, N2 = N - 0, Acc2 =        Acc;
        true  -> Pos2 = Pos + 1, N2 = N - 1, Acc2 = [Pos | Acc]
    end,
    rabin_karp_h1(Iterate, Accept, Pos2, OutList2, WinHash2, IsMatch2, InList2, N2, Acc2).