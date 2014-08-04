-module(fbq_logging).
-author("venkateshk@xpertizein.com").
-export([insert_log/3]).

insert_log(Body,QueueName,Connection) ->        
        	%%lager:info("Body is ~p ~n Queue Name is ~p ~n",[Body, QueueName]),
        	Query = "Insert into logs (message) values ('"++binary_to_list(Body)++"')",
        	lager:info("~p ~n",[Query]),
        	mysql:fetch(Connection, list_to_binary(Query))
        	.
