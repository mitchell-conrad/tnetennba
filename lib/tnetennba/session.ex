defmodule Tnetennba.Session do
  require Logger
  @derive [Poison.Encoder]
  defstruct [:letters, :word, :guesses, :start_time]

  def get_session(client, session_id) do
    case AWS.DynamoDB.get_item(client, %{
           TableName: "tnetennba-sessions",
           Key: %{SessionId: %{S: session_id}}
         }) do
      {:ok, %{"Item" => %{"State" => %{"S" => state_json}}}, _} ->
        Poison.decode(state_json, as: %Tnetennba.Session{})

      a ->
        IO.inspect a
        Logger.warning("Failed to get state")
        {:ok, %Tnetennba.Session{}}
    end
  end

  def put_session(client, session_id, session_state) do
    encoded_state = Poison.encode!(session_state)
    ttl = DateTime.utc_now() |> DateTime.add(1, :day) |> DateTime.to_unix(:second)
    item = %{SessionId: %{S: session_id}, State: %{S: encoded_state}, Ttl: %{N: Integer.to_string(ttl)}}

    AWS.DynamoDB.put_item(client, %{
      TableName: "tnetennba-sessions",
      Item: item
    })
  end
end
