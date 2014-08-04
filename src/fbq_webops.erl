-module(fbq_webops).

-author("venkatesh@xpertizein.com").

-export([rabbit_simple_query/3]).

rabbit_simple_query({HostName, Port, UserName, Password},Method, APICall) ->
	%% HostName, Port, UserName, Password - String
	%% Method - Atom
	%% APICall - String
	%% -- TODO --
	%% Add exception handling for request responses
	Url = string:join(["http://", HostName, ":", Port, "/api/", APICall], ""), 
	{ok, "200", _ , Response} = ibrowse:send_req(Url, [], Method ,[],[{basic_auth,{UserName, Password}}]),
	mochijson2:decode(Response)
.

%ibrowse:send_req("http://192.168.11.10:15672/api/queues", [], get, [], [{basic_auth,{"guest", "guest"}}])