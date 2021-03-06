defmodule GlificWeb.Schema.Query.ConversationTest do
  use GlificWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Glific.Contacts

  setup do
    Glific.Seeds.seed_contacts()
    Glific.Seeds.seed_messages()
    :ok
  end

  load_gql(:list, GlificWeb.Schema, "assets/gql/conversations/list.gql")

  test "conversations always returns a few threads" do
    {:ok, result} = query_gql_by(:list, variables: %{"nc" => 1, "sc" => 3})
    assert get_in(result, [:data, "conversations"]) |> length >= 1

    contact_id = get_in(result, [:data, "conversations", Access.at(0), "contact", "id"])

    {:ok, result} =
      query_gql_by(:list, variables: %{"nc" => 1, "sc" => 1, "filter" => %{"id" => contact_id}})

    assert get_in(result, [:data, "conversations"]) |> length == 1
  end

  test "conversations filtered by a contact id" do
    # if we send in an invalid id, we should not see any conversations
    {:ok, result} =
      query_gql_by(:list,
        variables: %{"nc" => 3, "sc" => 3, "filter" => %{"Gid" => "234567893453"}}
      )

    assert get_in(result, [:data, "conversations"]) == nil

    # lets create a new contact with no message
    {:ok, contact} =
      Contacts.create_contact(%{name: "My conversation contact", phone: "+123456789"})

    cid = Integer.to_string(contact.id)

    {:ok, result} =
      query_gql_by(:list, variables: %{"nc" => 1, "sc" => 1, "filter" => %{"id" => cid}})

    assert get_in(result, [:data, "conversations"]) |> length == 1
    assert get_in(result, [:data, "conversations", Access.at(0), "contact", "id"]) == cid
    assert get_in(result, [:data, "conversations", Access.at(0), "messages"]) == []
  end
end
