-module(fbq_server_monitor).

-behaviour(gen_server).

-author("venkatesh@xpertizein.com").

-export([start_link/4, stop/0, loop/0]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {state, qservername, supervisorpid, existedqueues}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link(MonitorName, ServerName, SupervisorPid, ExistedQueues) ->
 	gen_server:start_link({local, MonitorName}, ?MODULE, [MonitorName, ServerName, SupervisorPid, ExistedQueues], [] )
.

stop() ->
 	gen_server:cast(?MODULE, stop).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([MonitorName, ServerName, Supervisorpid, ExistedQueues]) ->
	process_flag(trap_exit, true),
	{ok, #state{state = init, qservername = ServerName, supervisorpid = Supervisorpid,  existedqueues = ExistedQueues}, 0}
.
handle_call(Message, From, State) ->
	{reply,Message, State}
.

handle_cast(_Request, State) ->
	{noreply, State}.


handle_info(timeout,  #state{state = init, qservername = ServerName, supervisorpid = Supervisorpid, existedqueues = ExistedQueues} = State) ->
	%io:format("before ~n",[]),
	spawn(fbq_rabbit,monitor_server_for_queues,[ServerName, self(), ExistedQueues]),
	%io:format("after ~n",[]),
	loop(), 
	{noreply, State#state{state = run, qservername = ServerName }};
handle_info(_Init, State) ->
	{noreply, State}
.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

loop()->
    receive
        {create_new_proc,{NewQueue}} ->
		Pid = fbq_channel_sup:start_link(list_to_atom(NewQueue)),
            loop();
        _ -> loop()
    end.
