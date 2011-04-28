%% Author: carl
%% Created: 26 Apr 2011
%% Description: TODO: Add description to iso8583py_test
-module(example_3_ascii_marshaller).
-include("erl8583/include/erl8583_field_ids.hrl").
-include("erl8583/include/erl8583_marshallers.hrl").
-export([test/0, marshal_end/2, unmarshal_init/2]).

marshal_end(_Message, Marshalled) ->
	Length = length(Marshalled),
	erl8583_convert:integer_to_string(Length, 4) ++ Marshalled.

unmarshal_init(Message, Marshalled) ->
	{LenStr, Rest} = lists:split(4, Marshalled),
	Len = list_to_integer(LenStr),
	Len = length(Rest),
	{Message, Rest}.

test() ->
	Msg1 = erl8583_message:new(),
	Msg2 = erl8583_message:set_mti("0800", Msg1),
	Msg3 = erl8583_message:set(3, "300000", Msg2),
	Msg4 = erl8583_message:set(24, "045", Msg3),
	Msg5 = erl8583_message:set(41, "11111111", Msg4),
	Msg6 = erl8583_message:set(42, "222222222222222", Msg5),
	Msg7 = erl8583_message:set(63, "This is a Test Message", Msg6),
	AsciiMessage = erl8583_marshaller:marshal(Msg7, ?MARSHALLER_ASCII ++ [{end_marshaller, ?MODULE}]),
	{ok, Sock} = gen_tcp:connect("localhost", 8000, [list, {packet, 0}, {active, true}]),
	io:format("Sending:~n~s~n", [AsciiMessage]),
	ok = gen_tcp:send(Sock, AsciiMessage),
	receive {tcp, _, AsciiResponse} -> AsciiResponse end,
	io:format("Received:~n~s~n", [AsciiResponse]),
	Response = erl8583_marshaller:unmarshal(AsciiResponse, ?MARSHALLER_ASCII ++ [{init_marshaller, ?MODULE}]),
	erl8583_message:get(0, Response).	