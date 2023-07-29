defmodule Tnetennba.DynamoDao do
  def get_record(client, word) do
    case AWS.DynamoDB.get_item(client, %{
           TableName: "tnetennba",
           Key: %{Word: %{S: word}}
         }) do
      {:ok, %{"Item" => %{"CurrentRecord" => %{"N" => record}}}, _} ->
        {num, _} = Integer.parse(record)
        num

      val ->
        val
    end
  end

  def update_record(client, word, new_max) do
    new_max_string = Integer.to_string(new_max)
    IO.inspect(new_max_string)
    AWS.DynamoDB.put_item(client, %{
      TableName: "tnetennba",
      Item: %{Word: %{S: word}, CurrentRecord: %{N: new_max_string}},
      ConditionExpression: "CurrentRecord < :new_record OR attribute_not_exists(Word)",
      ExpressionAttributeValues: %{":new_record" => %{N: new_max_string}},
      ReturnValuesOnConditionCheckFailure: "ALL_OLD"
    }) |> IO.inspect()
  end
end
