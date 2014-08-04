
-module(fbq_sup).

-behaviour(supervisor).

-author("venkatesh@xpertizein.com").
%% API
-export([start_link/0, stop/0]).

%% Supervisor callbacks
-export([init/1]).
-include("include/defines.hrl").


%% ===================================================================
%% API functions
%% ===================================================================
%% @doc start the main supervisor
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

%% @doc Init Callback. Initialize the main supervisor.
%% Check for the number of channels on Rabbit
%% Check if all the standard queues for Pangea exist, if not start them all
%% Spawn a supervisor for each queue.

%% @todo Implement Logging - lager or log4erl
init([]) ->
	NoOfQueues = fbq_diagnostics:check_rabbit_queues(?RABBIT_HOSTNAME),
	QueueNames = fbq_diagnostics:check_standard_queue_exist(?RABBIT_HOSTNAME), 
	RestartStrategy = {one_for_one, 10, 60},
    ChildrenSpecs = [{list_to_atom(Q) , {fbq_channel_sup, start_link, [list_to_atom(Q)]}, permanent, infinity, supervisor, [fbq_channel_sup]} || Q <- QueueNames ],
    MonitorSpec = {server_monitor , {fbq_server_monitor, start_link, [server_monitor, ?RABBIT_HOSTNAME, self(), QueueNames]}, permanent, infinity, supervisor, [fbq_server_monitor]},
    {ok, { RestartStrategy, [MonitorSpec | ChildrenSpecs] } }
.

%% @doc API call to stop the supervisor
stop() ->
    exit(whereis(?MODULE), shutdown)
.
