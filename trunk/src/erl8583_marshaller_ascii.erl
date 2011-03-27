% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

%% @author CA Meijer
%% @copyright 2011 CA Meijer
%% @doc This module marshals an iso8583message() into 
%%      an ASCII string or unmarshals an ASCII string into an
%%      iso8583message().

-module(erl8583_marshaller_ascii).

%%
%% Include files
%%
%% @headerfile "../include/erl8583_types.hrl"
-include("erl8583_types.hrl").

%%
%% Exported Functions
%%
-export([marshal/1, marshal/2, unmarshal/1, unmarshal/2]).

%%
%% API Functions
%%

%% @doc Marshals an ISO 8583 message into an ASCII string. This function
%%      uses the erl8583_marshaller_ascii_field module to marshal the fields.
%%
%% @spec marshal(iso8583message()) -> string()
-spec(marshal(iso8583message()) -> string()).

marshal(Message) ->
	marshal(Message, erl8583_marshaller_ascii_field).

%% @doc Marshals an ISO 8583 message into an ASCII string. This function
%%      uses the specified field marshalling module.
%%
%% @spec marshal(iso8583message(), module()) -> string()
-spec(marshal(iso8583message(), module()) -> string()).

marshal(Message, FieldMarshaller) ->
	Mti = erl8583_message:get(0, Message),
	[0|Fields] = erl8583_message:get_fields(Message),
	FieldMarshaller:marshal(0, Mti) ++ erl8583_marshaller_ascii_bitmap:marshal(Message) ++ encode(Fields, Message, FieldMarshaller).
	
%% @doc Unmarshals an ASCII string into an ISO 8583 message. This function
%%      uses the erl8583_marshaller_ascii_field module to unmarshal the fields.
%%
%% @spec unmarshal(string()) -> iso8583message()
-spec(unmarshal(string()) -> iso8583message()).

unmarshal(AsciiMessage) ->
	unmarshal(AsciiMessage, erl8583_marshaller_ascii_field).

%% @doc Unmarshals an ASCII string into an ISO 8583 message. This function
%%      uses the specified field marshalling module.
%%
%% @spec unmarshal(string(), module()) -> iso8583message()
-spec(unmarshal(string(), module()) -> iso8583message()).

unmarshal(AsciiMessage, FieldMarshaller) ->
	IsoMsg1 = erl8583_message:new(),
	{Mti, Rest} = lists:split(4, AsciiMessage),
	IsoMsg2 = erl8583_message:set(0, Mti, IsoMsg1),
	{FieldIds, Fields} = erl8583_marshaller_ascii_bitmap:unmarshal(Rest),
	decode_fields(FieldIds, Fields, IsoMsg2, FieldMarshaller).

%%
%% Local Functions
%%
encode(Fields, Msg, FieldMarshaller) ->
	lists:reverse(encode(Fields, Msg, [], FieldMarshaller)).

encode([], _Msg, Result, _FieldMarshaller) ->
	Result;
encode([FieldId|Tail], Msg, Result, FieldMarshaller) ->
	Value = erl8583_message:get(FieldId, Msg),
	EncodedValue = FieldMarshaller:marshal(FieldId, Value),
	encode(Tail, Msg, lists:reverse(EncodedValue) ++ Result, FieldMarshaller).
 
decode_fields([], _, Result, _FieldMarshaller) ->
	Result;
decode_fields([FieldId|Tail], Fields, Result, FieldMarshaller) ->
	{Value, UpdatedFields} = FieldMarshaller:unmarshal(FieldId, Fields),
	UpdatedResult = erl8583_message:set(FieldId, Value, Result),
	decode_fields(Tail, UpdatedFields, UpdatedResult, FieldMarshaller).