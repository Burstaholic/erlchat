-module(erlchat_chat_controller, [Req, Session]).
-compile(export_all).

login('GET', [Username]) ->
    create_and_push_message("public", string:concat(Username, " joined the room"), "system"),
    {output, "ok"}.

logout('GET', [Username]) ->
    create_and_push_message("public", string:concat(Username, " left the room"), "system"),
	boss_session:remove_session_data(Session, "chatlogin"),
    {output, "ok"}.

live('GET', [Channel]) ->
    Timestamp = boss_mq:now(Channel),
	case boss_session:get_session_data(Session, "chatlogin") of
		{error, Reason} ->
			{ok, [{error, Reason}]};
		undefined ->
			{ok, [{error, "Not logged in."}]};
		Chatuser ->
			{ok, [{timestamp, Timestamp}, {channel, Channel}, {chatuser, Chatuser}]}
	end.

send_message('POST', [Channel]) ->
    create_and_push_message(Channel, list_to_binary(Req:post_param("message")), Req:post_param("nickname")),
    {output, "ok"}.

receive_chat('GET', [Channel, LastTimestamp]) ->
    {ok, Timestamp, Messages} = boss_mq:pull(Channel, list_to_integer(LastTimestamp)),
    %{output, [{messags, Timestamp}]}.
    {json, [{timestamp, Timestamp}, {messages, Messages}]}.

send_test_message('GET', []) ->
    create_and_push_message("public", "This is a test message from the browser", "TestUser"),
    {output, "Message sent"}.

%% Utility methods
create_and_push_message(Channel, Message, Username) ->
    NewMessage = message:new(id, Message, Username, erlang:localtime()),
    boss_mq:push(Channel, NewMessage).


