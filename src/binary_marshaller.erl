%% Author: carl
%% Created: 19 Feb 2011
%% Description: TODO: Add description to bin_marshaller
-module(binary_marshaller).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([marshall/1, marshall/2]).

%%
%% API Functions
%%
marshall(Msg) ->
	marshall(Msg, iso8583_fields).

marshall(Msg, EncodingRules) ->
	Mti = iso8583_message:get(0, Msg),
	MtiBits = convert:ascii_hex_to_binary(Mti),
	[0|Fields] = iso8583_message:get_fields(Msg),
	BitMap = bitmap(Fields),
	EncodedFields = encode(Fields, Msg, EncodingRules),
	<< MtiBits/binary, BitMap/binary, EncodedFields/binary>>.


%%
%% Local Functions
%%
bitmap([]) ->
	<<>>;
bitmap(Fields) ->
	NumBitMaps = (lists:max(Fields) + 63) div 64,
	ExtensionBits = [Bit * 64 - 127 || Bit <- lists:seq(2, NumBitMaps)],
	BitMap = lists:duplicate(NumBitMaps * 8, 0),
	bitmap(lists:sort(ExtensionBits ++ Fields), BitMap).

bitmap([], Result) ->
	list_to_binary(Result);
bitmap([Field|Tail], Result) when Field > 0 ->
	ByteNum = (Field - 1) div 8,
	BitNum = 7 - ((Field - 1) rem 8),
	{Left, Right} = lists:split(ByteNum, Result),
	[ToUpdate | RightRest] = Right,
	bitmap(Tail, Left ++ ([ToUpdate + (1 bsl BitNum)]) ++ RightRest).

encode(Fields, Msg, EncodingRules) ->
	encode(Fields, Msg, <<>>, EncodingRules).

encode([], _Msg, Result, _EncodingRules) ->
	Result;
encode([Field|Tail], Msg, Result, EncodingRules) ->
	Encoding = EncodingRules:get_encoding(Field),
	Value = iso8583_message:get(Field, Msg),
	EncodedValue = encode_field(Encoding, Value),
	encode(Tail, Msg, convert:concat_binaries(Result, EncodedValue), EncodingRules).

encode_field({n, llvar, Length}, Value) when length(Value) =< Length ->
	LField = convert:integer_to_bcd(length(Value), 2),
	VField = convert:ascii_hex_to_bcd(Value, "0"),
	convert:concat_binaries(LField, VField);
encode_field({n, fixed, Length}, Value) ->
	PaddedValue = convert:integer_to_string(list_to_integer(Value), Length),
	convert:ascii_hex_to_bcd(PaddedValue, "0").