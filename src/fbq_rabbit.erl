-module(fbq_rabbit).

-author("venkatesh@xpertizein.com").

-export([receive_a_message/0, receive_messages/1, monitor_server_for_queues/3, call_supervisor_to_bindqueues/3]).

-include_lib("amqp_client/include/amqp_client.hrl").
-include("include/defines.hrl").


%%
%% Generate a random string of digits that can be used as an atom for a registered process name

random_digits() ->
    lists:concat( tuple_to_list( erlang:now() ) ).


gen_child_name(QueueName) ->
        list_to_atom(string:join([atom_to_list(QueueName), random_digits()], "_")).


%%-- TODO --
%% Refactor this function to take hostname, queue name as arguments

receive_a_message() ->
    {ok, Connection} = amqp_connection:start(#amqp_params_network{host = ?RABBIT_HOSTNAME}),
    {ok, Channel} = amqp_connection:open_channel(Connection),

    amqp_channel:call(Channel, #'queue.declare'{queue = <<"pangeafbq">>}),
    io:format(" [*] Waiting for messages. To exit press CTRL+C~n"),

    amqp_channel:subscribe(Channel, #'basic.consume'{queue = <<"pangeafbq">>,
                                                     no_ack = true}, self()),
    receive
        #'basic.consume_ok'{} -> ok
    end,
    loop(Channel).


loop(Channel) ->
    receive
        {#'basic.deliver'{}, #amqp_msg{payload = Body}} ->
            io:format(" [x] Received ~p~n", [Body]),
            Children = supervisor:which_children(fbq_sup),
            {_, Pid, _, _ } = lists:nth(random:uniform(length(Children)), Children), 
            fbq_server:receive_a_message(Pid, Body), 
            loop(Channel)
    end.


receive_messages(QueueName) ->
    io:format("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx~n"),
    io:format("Ready to receive message on Queue ~p, ~n", [QueueName]),
    {ok, Connection} = amqp_connection:start(#amqp_params_network{host = ?RABBIT_HOSTNAME}),
    {ok, Channel} = amqp_connection:open_channel(Connection),	
    BQueueName = list_to_binary(atom_to_list(QueueName)), 
    amqp_channel:subscribe(Channel, #'basic.consume'{queue = BQueueName,
                                                      no_ack = true}, self()),
    	receive
        #'basic.consume_ok'{} -> ok
    end,
    mysql:start_link(connection, ?DB_HOST , ?DB_USER, ?DB_PASSWORD, ?DB_DEFAULT),
    TimeStamp = get_current_time_stamp(),
    looping(QueueName, connection)
 .


looping(QueueName, Connection) ->
    receive
        {#'basic.deliver'{}, #amqp_msg{payload = Body}} ->
        spawn(fbq_logging,insert_log,[Body,atom_to_list(QueueName),Connection]),
        looping(QueueName, Connection)
    after
       1000 ->
        looping(QueueName, Connection)
    end.   
        

monitor_server_for_queues(Hostname, SupervisorPid, ExistedQueues) ->
    timer:sleep(?MONITER_NEW_QUEUES_TIME_INTERVAL),
    ServerQueues = fbq_diagnostics:get_rabbit_queue_names(Hostname),
    NewQueuesList = [X || X <- ServerQueues, lists:member(X,ExistedQueues)=:=false],
    call_supervisor_to_bindqueues(Hostname, SupervisorPid, NewQueuesList),
    monitor_server_for_queues(Hostname, SupervisorPid, lists:append([NewQueuesList,ExistedQueues]))
.

call_supervisor_to_bindqueues(Hostname, SupervisorPid, []) ->
    ok;
call_supervisor_to_bindqueues(Hostname, SupervisorPid, NewQueuesList) ->
    lists:foreach(fun(NewQueueName)-> fbq_diagnostics:declare_existing_queue(NewQueueName, Hostname), SupervisorPid ! {create_new_proc,{NewQueueName}} end, NewQueuesList)
. 
get_current_time_stamp() ->
    {Mega, Secs, _} = now(),
    Timestamp = Mega*1000000 + Secs,
    Timestamp.
