%% Author: carl
%% Created: 12 Feb 2011
%% Description: TODO: Add description to ascii_marshaller
-module(marshaller_ascii).

%%
%% Include files
%%


%%
%% Exported Functions
%%
-export([marshal/1, marshal/2, unmarshal/1, unmarshal/2]).

%%
%% API Functions
%%
marshal(Msg) ->
	marshal(Msg, iso8583_fields).

marshal(Msg, EncodingRules) ->
	Mti = iso8583_message:get(0, Msg),
	[0|Fields] = iso8583_message:get_fields(Msg),
	Mti ++ bitmap(Fields) ++ encode(Fields, Msg, EncodingRules).
	
unmarshal(Msg) ->
	unmarshal(Msg, iso8583_fields).

unmarshal(Msg, EncodingRules) ->
	IsoMsg1 = iso8583_message:new(),
	{Mti, Rest} = lists:split(4, Msg),
	IsoMsg2 = iso8583_message:set(0, Mti, IsoMsg1),
	{FieldIds, Fields} = extract_fields(Rest),
	decode_fields(FieldIds, Fields, IsoMsg2, EncodingRules).

%%
%% Local Functions
%%
bitmap([]) ->
	[];
bitmap(Fields) ->
	NumBitMaps = (lists:max(Fields) + 63) div 64,
	ExtensionBits = [Bit * 64 - 127 || Bit <- lists:seq(2, NumBitMaps)],
	BitMap = lists:duplicate(NumBitMaps * 8, 0),
	convert:string_to_ascii_hex(bitmap(lists:sort(ExtensionBits ++ Fields), BitMap)).

bitmap([], Result) ->
	Result;
bitmap([Field|Tail], Result) when Field > 0 ->
	ByteNum = (Field - 1) div 8,
	BitNum = 7 - ((Field - 1) rem 8),
	{Left, Right} = lists:split(ByteNum, Result),
	[ToUpdate | RightRest] = Right,
	bitmap(Tail, Left ++ ([ToUpdate + (1 bsl BitNum)]) ++ RightRest).

encode(Fields, Msg, EncodingRules) ->
	lists:reverse(encode(Fields, Msg, [], EncodingRules)).

encode([], _Msg, Result, _EncodingRules) ->
	Result;
encode([Field|Tail], Msg, Result, EncodingRules) ->
	Encoding = EncodingRules:get_encoding(Field),
	Value = iso8583_message:get(Field, Msg),
	EncodedValue = encode_field(Field, Encoding, Value),
	encode(Tail, Msg, lists:reverse(EncodedValue) ++ Result, EncodingRules).

encode_field(_Field, {n, llvar, Length}, Value) when length(Value) =< Length ->
	convert:integer_to_string(length(Value), 2) ++ Value;
encode_field(_Field, {n, lllvar, Length}, Value) when length(Value) =< Length ->
	convert:integer_to_string(length(Value), 3) ++ Value;
encode_field(_Field, {ns, llvar, Length}, Value) when length(Value) =< Length ->
	convert:integer_to_string(length(Value), 2) ++ Value;
encode_field(_Field, {an, llvar, Length}, Value) when length(Value) =< Length ->
	convert:integer_to_string(length(Value), 2) ++ Value;
encode_field(_Field, {an, lllvar, Length}, Value) when length(Value) =< Length ->
	convert:integer_to_string(length(Value), 3) ++ Value;
encode_field(_Field, {ans, llvar, Length}, Value) when length(Value) =< Length ->
	convert:integer_to_string(length(Value), 2) ++ Value;
encode_field(_Field, {ans, lllvar, Length}, Value) when length(Value) =< Length ->
	convert:integer_to_string(length(Value), 3) ++ Value;
encode_field(_Field, {n, fixed, Length}, Value) when length(Value) =< Length ->
	IntValue = list_to_integer(Value),
	convert:integer_to_string(IntValue, Length);
encode_field(_Field, {an, fixed, Length}, Value) when length(Value) =< Length ->
	convert:pad_with_trailing_spaces(Value, Length);
encode_field(_Field, {ans, fixed, Length}, Value) when length(Value) =< Length ->
	convert:pad_with_trailing_spaces(Value, Length);
encode_field(_Field, {x_n, fixed, Length}, [Head | Value]) when Head =:= $C orelse Head =:= $D ->
	IntValue = list_to_integer(Value),
	[Head] ++ convert:integer_to_string(IntValue, Length);
encode_field(_Field, {z, llvar, Length}, Value) when length(Value) =< Length ->
	convert:integer_to_string(length(Value), 2) ++ Value;
encode_field(_Field, {b, Length}, Value) when size(Value) =:= Length ->
	convert:binary_to_ascii_hex(Value);
encode_field(Field, {custom, Marshaller}, Value) ->
	Marshaller:marshal(Field, Value).

extract_fields([]) ->
	{[], []};
extract_fields(Message) ->
	BitMapLength = get_bit_map_length(Message),
	{AsciiBitMap, Fields} = lists:split(BitMapLength, Message),
	BitMap = convert:ascii_hex_to_string(AsciiBitMap),
	extract_fields(BitMap, 0, 8, {[], Fields}).

extract_fields([], _Offset, _Index, {FieldIds, Fields}) ->
	Ids = lists:sort(FieldIds),
	{[Id || Id <- Ids, Id rem 64 =/= 1], Fields};
extract_fields([_Head|Tail], Offset, 0, {FieldIds, Fields}) ->
	extract_fields(Tail, Offset+1, 8, {FieldIds, Fields});
extract_fields([Head|Tail], Offset, Index, {FieldIds, Fields}) ->
	case Head band (1 bsl (Index-1)) of
		0 ->
			extract_fields([Head|Tail], Offset, Index-1, {FieldIds, Fields});
		_ ->
			extract_fields([Head|Tail], Offset, Index-1, {[Offset*8+9-Index|FieldIds], Fields})
	end.
			
decode_fields([], _, Result, _EncodingRules) ->
	Result;
decode_fields([Field|Tail], Fields, Result, EncodingRules) ->
	Encoding = EncodingRules:get_encoding(Field),
	{Value, UpdatedFields} = decode_field(Field, Encoding, Fields),
	UpdatedResult = iso8583_message:set(Field, Value, Result),
	decode_fields(Tail, UpdatedFields, UpdatedResult, EncodingRules).
	
decode_field(_FieldId, {n, llvar, _MaxLength}, Fields) ->
	{N, Rest} = lists:split(2, Fields),
	lists:split(list_to_integer(N), Rest);
decode_field(_FieldId, {n, lllvar, _MaxLength}, Fields) ->
	{N, Rest} = lists:split(3, Fields),
	lists:split(list_to_integer(N), Rest);
decode_field(_FieldId, {ns, llvar, _MaxLength}, Fields) ->
	{N, Rest} = lists:split(2, Fields),
	lists:split(list_to_integer(N), Rest);
decode_field(_FieldId, {an, llvar, _MaxLength}, Fields) ->
	{N, Rest} = lists:split(2, Fields),
	lists:split(list_to_integer(N), Rest);
decode_field(_FieldId, {an, lllvar, _MaxLength}, Fields) ->
	{N, Rest} = lists:split(3, Fields),
	lists:split(list_to_integer(N), Rest);
decode_field(_FieldId, {ans, llvar, _MaxLength}, Fields) ->
	{N, Rest} = lists:split(2, Fields),
	lists:split(list_to_integer(N), Rest);
decode_field(_FieldId, {ans, lllvar, _MaxLength}, Fields) ->
	{N, Rest} = lists:split(3, Fields),
	lists:split(list_to_integer(N), Rest);
decode_field(_FieldId, {n, fixed, Length}, Fields) ->
	lists:split(Length, Fields);
decode_field(_FieldId, {an, fixed, Length}, Fields) ->
	lists:split(Length, Fields);
decode_field(_FieldId, {ans, fixed, Length}, Fields) ->
	lists:split(Length, Fields);
decode_field(_FieldId, {x_n, fixed, Length}, [Head|Tail]) when Head =:= $C orelse Head =:= $D ->
	lists:split(Length+1, [Head|Tail]);
decode_field(_FieldId, {z, llvar, _MaxLength}, Fields) ->
	{N, Rest} = lists:split(2, Fields),
	lists:split(list_to_integer(N), Rest);
decode_field(_FieldId, {b, Length}, Fields) ->
	{ValueStr, Rest} = lists:split(2 * Length, Fields),
	Value = convert:ascii_hex_to_binary(ValueStr),
	{Value, Rest};
decode_field(FieldId, {custom, Marshaller}, Fields) ->
	Marshaller:unmarshal(FieldId, Fields).

get_bit_map_length(Msg) ->
	get_bit_map_length(Msg, 16).

get_bit_map_length(Msg, Length) ->
	[HexDig1, HexDig2|_Tail] = Msg,
	<<Byte>> = convert:ascii_hex_to_binary([HexDig1, HexDig2]),
	case (Byte band 128) of
		0 ->
			Length;
		_ ->
			{_Msg1, Msg2} = lists:split(16, Msg),
			get_bit_map_length(Msg2, Length+16)
	end.