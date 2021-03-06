-module(linear_intervals).
-export([empty/0, full/0, half/1, single_int/1, single_string/1, range/2, ranges/1]).
-export([from_list/1]).
-export([foldl_int/3]).
-export([is_element/2, is_empty/1]).
-export([invert/1, merge/3, intersection/2, union/2, symmetric_difference/2, subtract/2]).
-export([first_fit/2]).

empty() ->
    {false, []}.

is_empty({false, []}) ->
    true;
is_empty(_) ->
    false.

full() ->
    {true, []}.

half(N) ->
    {false, [N]}.

single_int(N) ->
    {false, [N, N+1]}.

single_string(N) ->
    {false, [N, N ++ [0]]}.

merge_adjacent(Acc, []) ->
    lists:reverse(Acc);
merge_adjacent(Acc, [{L1, M}, {M, H2} | Rest]) ->
    merge_adjacent(Acc, [{L1, H2} | Rest]);
merge_adjacent(Acc, [{L, H} | Rest]) ->
    merge_adjacent([H, L | Acc], Rest).

from_list(Elts) ->
    {false, merge_adjacent([], lists:usort(Elts))}.

foldl_int(_F, Acc, {false, []}) ->
    Acc;
foldl_int(F, Acc, {false, [InStart, InStop | Rest]}) ->
    foldl_int(F, foldl_int_inside(F, Acc, InStart, InStop), {false, Rest}).

foldl_int_inside(_F, Acc, N, N) ->
    Acc;
foldl_int_inside(F, Acc, N, M) ->
    foldl_int_inside(F, F(N, Acc), N + 1, M).

range(inf, inf) ->
    full();
range(inf, N) ->
    {true, [N]};
range(N, inf) ->
    half(N);
range(N, M)
  when N >= M ->
    empty();
range(N, M) ->
    {false, [N, M]}.

ranges([]) ->
    empty();
ranges([{N,M} | Ranges]) ->
    {Initial, Acc0} = range(N,M),
    {Initial, lists:reverse(ranges(lists:reverse(Acc0), Ranges))}.

ranges(Acc, []) ->
    Acc;
ranges(Acc, [{N, M} | Ranges])
  when is_number(N) andalso is_number(M) ->
    if
	N < M ->
	    ranges([M, N | Acc], Ranges);
	true ->
	    ranges(Acc, Ranges)
    end;
ranges(Acc, [{N, inf}]) ->
    [N | Acc].

is_element(E, {Initial, Toggles}) ->
    is_element(E, Initial, Toggles).

is_element(_E, Current, []) ->
    Current;
is_element(E, Current, [T | _])
  when E < T ->
    Current;
is_element(E, Current, [_ | Rest]) ->
    is_element(E, not Current, Rest).

invert({true, Toggles}) ->
    {false, Toggles};
invert({false, Toggles}) ->
    {true, Toggles}.

merge(Op, {S1, T1}, {S2, T2}) ->
    Initial = merge1(Op, S1, S2),
    {Initial, merge(Op, Initial, [], S1, T1, S2, T2)}.

intersection(A, B) -> merge(intersection, A, B).
union(A, B) -> merge(union, A, B).
symmetric_difference(A, B) -> merge(symmetric_difference, A, B).
subtract(A, B) -> merge(difference, A, B).

merge1(intersection, A, B) -> A and B;
merge1(union, A, B) -> A or B; 
merge1(symmetric_difference, A, B) -> A xor B;
merge1(difference, A, B) -> A and not B.

merge(Op, SA, TA, S1, [T1 | R1], S2, [T2 | R2])
  when T1 == T2 ->
    update(Op, SA, TA, T1, not S1, R1, not S2, R2);
merge(Op, SA, TA, S1, [T1 | R1], S2, R2 = [T2 | _])
  when T1 < T2 ->
    update(Op, SA, TA, T1, not S1, R1, S2, R2);
merge(Op, SA, TA, S1, R1, S2, [T2 | R2]) ->
    update(Op, SA, TA, T2, S1, R1, not S2, R2);
merge(Op, _SA, TA, S1, [], _S2, R2) ->
    finalise(TA, mergeempty(Op, left, S1, R2));
merge(Op, _SA, TA, _S1, R1, S2, []) ->
    finalise(TA, mergeempty(Op, right, S2, R1)).

update(Op, SA, TA, T1, S1, R1, S2, R2) ->
    Merged = merge1(Op, S1, S2),
    if
	SA == Merged ->
	    merge(Op, SA, TA, S1, R1, S2, R2);
	true ->
	    merge(Op, Merged, [T1 | TA], S1, R1, S2, R2)
    end.

finalise(TA, Tail) ->
    lists:reverse(TA, Tail).

mergeempty(intersection, _LeftOrRight, true, TailT) ->
    TailT;
mergeempty(intersection, _LeftOrRight, false, _TailT) ->
    [];
mergeempty(union, _LeftOrRight, true, _TailT) ->
    [];
mergeempty(union, _LeftOrRight, false, TailT) ->
    TailT;
mergeempty(symmetric_difference, _LeftOrRight, _EmptyS, TailT) ->
    TailT;
mergeempty(difference, left, true, TailT) ->
    TailT;
mergeempty(difference, right, false, TailT) ->
    TailT;
mergeempty(difference, _LeftOrRight, _EmptyS, _TailT) ->
    [].

first_fit(Request, {false, Toggles}) ->
    first_fit1(Request, Toggles).

first_fit1(_Request, []) ->
    none;
first_fit1(_Request, [N]) ->
    {ok, N};
first_fit1(inf, [_N, _M | Rest]) ->
    first_fit1(inf, Rest);
first_fit1(Request, [N, M | _Rest])
  when M - N >= Request ->
    {ok, N};
first_fit1(Request, [_N, _M | Rest]) ->
    first_fit1(Request, Rest).
