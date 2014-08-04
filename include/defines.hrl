-author("venkatesh@xpertizein.com").
-define(RABBIT_HOSTNAME, "localhost").
-define(RABBIT_PORT, "15672").
-define(RABBIT_USER, "guest").
-define(RABBIT_PASSWORD, "guest").

%% Pangea Queues
-define(PANGEAQ, "pangeafbq").
-define(FBACCOUNTS, [?PANGEAQ, ?FACEBOOK1, ?FACEBOOK2, ?FACEBOOK3, ?FACEBOOK4, ?FACEBOOK5]).
-define(PANGEA_EXCHANGE,"pangea").
-define(MONITER_NEW_QUEUES_TIME_INTERVAL, 200).
-define(FACEBOOK_CALLS_LIMIT, 10).
-define(FACEBOOK_CALLS_TIME_LIMIT, 1).
-define(DB_HOST, "localhost").
-define(DB_USER, "root").
-define(DB_PASSWORD, "venky").
-define(DB_DEFAULT, "erlang").

