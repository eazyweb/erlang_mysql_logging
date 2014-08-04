
-module(fbq_channel_sup).

-behaviour(supervisor).

-author("venkatesh@xpertizein.com").

%% API
-export([start_link/1]).

%% Supervisor callbacks
-export([init/1]).

-author("venkatesh@xpertizein.com").

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link(QueueServerName) ->
    supervisor:start_link({local, QueueServerName}, ?MODULE, [QueueServerName]).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init(QueueServerName) ->
	MonitorName = string:join([atom_to_list(hd(QueueServerName)), "monitor"], "_"),
	ChildSpecs = [{list_to_atom(MonitorName), {fbq_monitor_server, start_link, [list_to_atom(MonitorName),hd(QueueServerName)]}, permanent, 4000, worker, [fbq_monitor_server]}],
	{ok, {{one_for_one, 10, 60}, ChildSpecs}}
.