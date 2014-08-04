-module(fbq_diagnostics).

-author("venkatesh@xpertizein.com").

-include_lib("amqp_client/include/amqp_client.hrl").
-include("include/defines.hrl").

-export([check_rabbit_server/1, check_rabbit_queues/1, messages_in_queue/1,
		 get_rabbit_queue_names/1, check_queue_exist/2, check_standard_queue_exist/1, declare_existing_queue/2]).

% Check for the configurations
% Load the configurations
% Check Connectivity with rabbitmq
% Count the number of channels create tthem if they are not available
% Count the messages on each of the channels

check_rabbit_server(HostName) ->
	%% Try to establish a connection to the RabbitMQ server. 
	%% If the server is available, return a success message and continue further.
	%% If the server is not available, exit gracefully with a message to the 
	%% standard output or log file
	Result = amqp_connection:start(#amqp_params_network{host = HostName}),

	case Result of 
		{ok, Connection} ->
			{ok, Connection};
		{error, econnrefused} ->
			error_in_connection
	end
.

%% Get the number of queues in RabbitMQ with Hostname
check_rabbit_queues(HostName) ->
	%% Make an API call to RabbitMQ admin console to get the number of queues
	Decoded = fbq_webops:rabbit_simple_query({?RABBIT_HOSTNAME, ?RABBIT_PORT, ?RABBIT_USER, ?RABBIT_PASSWORD}, get, "queues"), 
	length(Decoded)
.

%% Get the list of Queue Namesin RabbitMQ with Hostname
get_rabbit_queue_names(HostName) ->
	Decoded = fbq_webops:rabbit_simple_query({?RABBIT_HOSTNAME, ?RABBIT_PORT, ?RABBIT_USER, ?RABBIT_PASSWORD}, get, "queues"), 
	%% Return the list of Queues as string instead of Binary
	[binary_to_list(QueueName) || {<<"name">>, QueueName}  <- [ proplists:lookup(<<"name">>, ObjList)  ||  {struct, ObjList} <- Decoded ]]
.

%% Check if a queue exists in RabbitMQ or not
%% If the queue doesn't exist, create one.
check_queue_exist(QueueName, HostName) ->
	ListOfQueues = fbq_diagnostics:get_rabbit_queue_names(HostName),
	%io:format("queues list : ~p ~n ",[ListOfQueues]),
	Result = lists:member(QueueName, ListOfQueues) ,

	case Result of 
		true ->
			QueueName;
		false ->
			io:format("Create a Queue with given name"),
			{ok, Connection} =  amqp_connection:start(#amqp_params_network{host = HostName}),
			{ok, Channel} = amqp_connection:open_channel(Connection),

			BExchangeName  = list_to_binary(?PANGEA_EXCHANGE),
			amqp_channel:call(Channel, #'exchange.declare'{exchange = BExchangeName}),
			
			BQueueName = list_to_binary(QueueName), 
			amqp_channel:call(Channel, #'queue.declare'{queue =BQueueName,durable=true}),
			
			BRoutingKey = BQueueName,
			amqp_channel:call(Channel, #'queue.bind'{exchange = BExchangeName,
                                              routing_key = BRoutingKey,
                                              queue = BQueueName}),
			
			io:format("Created a queue with name ~p~n ", [QueueName]),
			QueueName
	end
.

%%  Declare the queue that is passed as a param
declare_existing_queue(QueueName, HostName) ->
	{ok, Connection} =  amqp_connection:start(#amqp_params_network{host = HostName}),
	{ok, Channel} = amqp_connection:open_channel(Connection),

	BExchangeName  = list_to_binary(?PANGEA_EXCHANGE),
	BQueueName = list_to_binary(QueueName), 
	
	BRoutingKey = BQueueName,
	amqp_channel:call(Channel, #'queue.bind'{exchange = BExchangeName,
                                      routing_key = BRoutingKey,
                                      queue = BQueueName}),
	
	io:format("binded to the queue ~p~n ", [QueueName]),
	QueueName
.



%% Bind the queues already existed in the Queuing server.
check_standard_queue_exist(HostName) ->
	ListOfQueues = fbq_diagnostics:get_rabbit_queue_names(HostName),
	[ declare_existing_queue(A, HostName) || A <- ListOfQueues ]
.


messages_in_queue(QName) ->
	
	Decoded = fbq_webops:rabbit_simple_query({?RABBIT_HOSTNAME, ?RABBIT_PORT, ?RABBIT_USER, ?RABBIT_PASSWORD}, get, "queues"), 
	
	Extracted = [[proplists:lookup(<<"name">>, ObjList), proplists:lookup(<<"messages">>, ObjList) ]   || {struct, ObjList} <- Decoded],
	%%[[{<<"name">>,<<"hello">>},none],[{<<"name">>,<<"pangeafbq">>},{<<"messages">>,3}]]
	
	ExtractModified = [ [X, if Y == none -> {<<"messages">>, 0}; true -> Y end]    || [X , Y ]  <- Extracted],
	
	Queues = [ {QueueName, Size}  ||  [{<<"name">>, QueueName}, {<<"messages">>, Size}]  <-ExtractModified],
	%% [{<<"hello">>,0},{<<"pangeafbq">>,3}]
	
	BinQ = list_to_binary(QName),
	{value, {BinQ, QueueSize}}= lists:keysearch(BinQ, 1, Queues),
	QueueSize

.
