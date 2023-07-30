defmodule Tnetennba.DynamoDao do
  def get_record(client, word) do
    case AWS.DynamoDB.get_item(client, %{
           TableName: "tnetennba",
           Key: %{Word: %{S: word}}
         }) do
      {:ok, %{"Item" => %{"CurrentRecord" => %{"N" => record}}}, _} ->
        {num, _} = Integer.parse(record)
        num

      _ ->
        0
    end
  end

  def update_record(client, word, new_max) do
    # TODO: Extract old record from failed conditional update. This is annoying as the old record
    #  is returned as escaped json, not a nice map :(
    new_max_string = Integer.to_string(new_max)

    AWS.DynamoDB.put_item(client, %{
      TableName: "tnetennba",
      Item: %{Word: %{S: word}, CurrentRecord: %{N: new_max_string}},
      ConditionExpression: "CurrentRecord < :new_record OR attribute_not_exists(Word)",
      ExpressionAttributeValues: %{":new_record" => %{N: new_max_string}},
      ReturnValuesOnConditionCheckFailure: "ALL_OLD"
    })
  end


end
