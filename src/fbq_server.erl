-module(fbq_server).

-behaviour(gen_server).

-author("venkatesh@xpertizein.com").

%% API 
-export([start_link/2, stop/0]).

%% Supervisor Callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {state, data}).


%% ===================================================================
%% API functions
%% ===================================================================

start_link(ChildName, Data) ->
 	io:format("inside fbq_server ~n",[]),
	gen_server:start_link({local, ChildName}, ?MODULE, [Data], [] )
 	.
stop() ->
 	gen_server:cast(?MODULE, stop).


%% ===================================================================
%% Supervisor callbacks
%% ===================================================================


init([Data]) ->
	process_flag(trap_exit, true),
	{ok, #state{state = init, data = Data}, 0}
.

handle_call(Message, From, State) ->
	{reply, Message, State}
.

handle_cast(_Request, State) ->
	{noreply, State}
.

handle_info(timeout, #state{state = init, data = Data} = State) ->
	fbq_ibrowse:parse_message(Data),
	{noreply, State#state{state = run}}
;
handle_info(_Init, State) ->
	{noreply, State}
.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.


