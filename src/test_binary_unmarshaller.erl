%% Author: carl
%% Created: 19 Feb 2011
%% Description: TODO: Add description to test_binary_unmarshaller
-module(test_binary_unmarshaller).

-behaviour(encoding_rules).
-behaviour(custom_marshaller).

%%
%% Include files
%%
-include_lib("eunit/include/eunit.hrl").
-include("field_defines.hrl").

%%
%% Exported Functions
%%
-export([get_encoding/1, marshal/2, unmarshal/2]).

%%
%% API Functions
%%
get_encoding(2) ->
	{n, fixed, 4};
get_encoding(3) ->
	{custom, ?MODULE};
get_encoding(4) ->
	{custom, ?MODULE}.

marshal(_Field, _Value) ->
	erlang:error("Shouldn't have been invoked.").
unmarshal(3, <<3, 0, 4, 0>>) ->
	{"3", <<4, 0>>};
unmarshal(4, <<4, 0>>) ->
	{"4", <<>>}.


%%
%% Local Functions
%%
unmarshall_mti_test() ->
	Msg1 = binary_unmarshaller:unmarshal(<<2, 16>>),
	"0210" = iso8583_message:get(0, Msg1),
	[0] = iso8583_message:get_fields(Msg1),
	Msg2 = binary_unmarshaller:unmarshal(<<2, 0>>),
	"0200" = iso8583_message:get(0, Msg2).
	
field_2_test() ->
	Msg1 = binary_unmarshaller:unmarshal(<<2, 16, 64, 0, 0, 0, 0, 0, 0, 0, 23, 21, 35, 69, 103, 137, 1, 35, 69, 96>>),
	"0210" = iso8583_message:get(0, Msg1),
	[0, 2] = iso8583_message:get_fields(Msg1),
	"15234567890123456" = iso8583_message:get(2, Msg1).

field_2_3_test() ->
	Msg1 = binary_unmarshaller:unmarshal(<<2, 16, 96, 0, 0, 0, 0, 0, 0, 0, 22, 18, 52, 86, 120, 144, 18, 52, 86, 1, 35, 69>>),
	"0210" = iso8583_message:get(0, Msg1),
	[0, 2, 3] = iso8583_message:get_fields(Msg1),
	"1234567890123456" = iso8583_message:get(2, Msg1),
	"012345" = iso8583_message:get(?PROC_CODE, Msg1).

field_4_test() ->
	Msg = binary_unmarshaller:unmarshal(<<18, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 35>>),
	"1200" = iso8583_message:get(0, Msg),
	[0, 4] = iso8583_message:get_fields(Msg),
	"000000000123" = iso8583_message:get(4, Msg).

field_5_test() ->
	Msg = binary_unmarshaller:unmarshal(<<18, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16>>),
	"1200" = iso8583_message:get(0, Msg),
	[0, 5] = iso8583_message:get_fields(Msg),
	"000000000010" = iso8583_message:get(5, Msg).
	
field_6_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 32, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 135, 101>>),
	"0220" = iso8583_message:get(0, Msg),
	[0, 6] = iso8583_message:get_fields(Msg),
	"000000098765" = iso8583_message:get(6, Msg).

field_6_7_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 32, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 152, 118, 84, 2, 34, 25, 6, 18>>),
	"0220" = iso8583_message:get(0, Msg),
	[0, 6, 7] = iso8583_message:get_fields(Msg),
	"000000987654" = iso8583_message:get(6, Msg),
	"0222190612" =  iso8583_message:get(7, Msg).
	
field_18_19_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 32, 0, 0, 96, 0, 0, 0, 0, 0, 18, 52, 5, 103>>),
	"0220" = iso8583_message:get(0, Msg),
	[0, 18, 19] = iso8583_message:get_fields(Msg),
	"1234" = iso8583_message:get(18, Msg),
	"567" =  iso8583_message:get(19, Msg).

field_26_27_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 33, 0, 0, 0, 96, 0, 0, 0, 0, 34, 1>>),
	"0221" = iso8583_message:get(0, Msg),
	[0, 26, 27] = iso8583_message:get_fields(Msg),
	"22" = iso8583_message:get(26, Msg),
	"1" =  iso8583_message:get(27, Msg).

fields_28_29_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 33, 0, 0, 0, 24, 0, 0, 0, 0, 67, 0, 0, 0, 1, 68, 0, 0, 0, 34>>),
	"0221" = iso8583_message:get(0, Msg),
	[0, 28, 29] = iso8583_message:get_fields(Msg),
	"C00000001" = iso8583_message:get(28, Msg),
	"D00000022" =  iso8583_message:get(29, Msg).
	
fields_33_34_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 33, 0, 0, 0, 0, 192, 0, 0, 0, 5, 18, 52, 80, 6, 53, 54, 55, 56, 57, 48>>),
	"0221" = iso8583_message:get(0, Msg),
	[0, 33, 34] = iso8583_message:get_fields(Msg),
	"12345" = iso8583_message:get(33, Msg),
	"567890" =  iso8583_message:get(34, Msg).

fields_35_36_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 33, 0, 0, 0, 0, 48, 0, 0, 0, 53, 177, 35, 65, 35, 65, 35, 65, 35, 77, 3, 5, 16, 17, 147, 1, 8, 119, 240, 0, 6, 65, 66, 67, 49, 50, 51>>),
	"0221" = iso8583_message:get(0, Msg),
	[0, 35, 36] = iso8583_message:get_fields(Msg),
	";1234123412341234=0305101193010877?" = iso8583_message:get(35, Msg),
	"ABC123" =  iso8583_message:get(36, Msg).
	
fields_35_36b_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 33, 0, 0, 0, 0, 48, 0, 0, 0, 4, 177, 47, 1, 4, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										   65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										   65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										   65, 65, 65, 65, 65, 65, 65, 65, 65>>),
	[0, 35, 36] = iso8583_message:get_fields(Msg),
	";12?" = iso8583_message:get(35, Msg),
	Expected = lists:duplicate(104, $A),
	Expected =  iso8583_message:get(36, Msg).

field_37_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 33, 0, 0, 0, 0, 8, 0, 0, 0, 65, 49, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32>>),
	[0, 37] = iso8583_message:get_fields(Msg),
	"A1          " = iso8583_message:get(?RETRIEVAL_REF_NUM, Msg).

field_41_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 0, 0, 0, 0, 0, 128, 0, 0, 67, 65, 84, 73, 32, 49, 32, 32>>),
	[0, 41] = iso8583_message:get_fields(Msg),
	"CATI 1  " = iso8583_message:get(?CARD_ACCEPTOR_TERMINAL_ID, Msg).

field_44_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 0, 0, 0, 0, 0, 16, 0, 0, 35, 97, 100, 100, 105, 116, 105, 111, 110, 97, 108, 32, 114, 101, 112, 48, 110, 53, 101, 32, 100, 97, 116, 97>>),
	[0, 44] = iso8583_message:get_fields(Msg),
	"additional rep0n5e data" = iso8583_message:get(44, Msg).
	
field_46_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 64, 0, 0, 0, 0, 4, 0, 0, 25, 18, 52, 86, 120, 144, 18, 52, 86, 120, 144, 0, 33, 97, 100, 100, 105, 116, 105, 111, 110, 97, 108, 32, 100, 97, 116, 97, 32, 45, 32, 105, 115, 111>>),
	[0, 2, 46] = iso8583_message:get_fields(Msg),
	"additional data - iso" = iso8583_message:get(46, Msg).
	
field_52_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 64, 0, 0, 0, 0, 0, 16, 0, 22, 18, 52, 86, 120, 144, 18, 52, 86, 49, 50, 51, 52, 53, 54, 55, 56>>),
	[0, 2, 52] = iso8583_message:get_fields(Msg),
	<<"12345678">> = iso8583_message:get(52, Msg).

field_53_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 64, 0, 0, 0, 0, 0, 8, 0, 22, 18, 52, 86, 120, 144, 18, 52, 86, 0, 0, 0, 0, 0, 0, 0, 1>>),
	[0, 2, 53] = iso8583_message:get_fields(Msg),
	"0000000000000001" = iso8583_message:get(53, Msg).

field_55_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 64, 0, 0, 0, 0, 0, 2, 0, 22, 18, 52, 86, 120, 
										  144, 18, 52, 86, 1, 35, 65, 65, 65, 65, 65, 65, 65, 
										  65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										  65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										  65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										  65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										  65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										  65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										  65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										  65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 
										  65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65>>),
	Expected = lists:duplicate(123, $A),
	Expected = iso8583_message:get(55, Msg).

field_64_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 64, 0, 0, 0, 0, 0, 0, 1, 22, 18, 52, 86, 120, 144, 18, 52, 86, 0, 0, 0, 0, 0, 0, 0, 0>>),
	<<0, 0, 0, 0, 0, 0, 0, 0>> = iso8583_message:get(64, Msg).

field_66_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 192, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 22, 18, 52, 86, 120, 144, 18, 52, 86, 1>>),
	[0, 2, 66] = iso8583_message:get_fields(Msg),
	"1" = iso8583_message:get(66, Msg).

field_91_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 22, 18, 52, 86, 120, 144, 18, 52, 86, 65>>),
	"A" = iso8583_message:get(91, Msg).

field_101_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 22, 18, 52, 86, 120, 144, 18, 52, 86, 8, 70, 105, 108, 101, 78, 97, 109, 101>>),
	"FileName" = iso8583_message:get(101, Msg).

encoding_rules_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 16, 64, 0, 0, 0, 0, 0, 0, 0, 0, 1>>, ?MODULE),
	"0001" = iso8583_message:get(2, Msg).

custom_marshaller_test() ->
	Msg = binary_unmarshaller:unmarshal(<<2, 0, 48, 0, 0, 0, 0, 0, 0, 0, 3, 0, 4, 0>>, ?MODULE),
	"3" = iso8583_message:get(3, Msg),
	"4" = iso8583_message:get(4, Msg).
