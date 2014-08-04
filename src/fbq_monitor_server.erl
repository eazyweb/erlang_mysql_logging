-module(fbq_monitor_server).

-behaviour(gen_server).

-author("venkatesh@xpertizein.com").

-export([start_link/2, stop/0]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {state, qservername}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link(MonitorName, QueueServerName) ->
 	gen_server:start_link({local, MonitorName}, ?MODULE, [MonitorName, QueueServerName], [] )
 	.

stop() ->
 	gen_server:cast(?MODULE, stop).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================


init([MonitorName, QueueServerName]) ->
	process_flag(trap_exit, true),
	{ok, #state{state = init, qservername = QueueServerName}, 0}
.
handle_call(Message, From, State) ->
	{reply,Message, State}
.

handle_cast(_Request, State) ->
	{noreply, State}.


handle_info(timeout,  #state{state = init, qservername = QueueServerName} = State) ->
	fbq_rabbit:receive_messages(QueueServerName), 
	{noreply, State#state{state = run, qservername = QueueServerName }};
handle_info(_Init, State) ->
	{noreply, State}
.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.


