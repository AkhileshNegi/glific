defmodule Glific.Conversations do
  @moduledoc """
  The main Glific abstraction that exposes the data in a stuctured manner as a set
  of conversations. For now each contact is associated with one and only one conversation.
  We will keep the API simple for now, but it is likely to become more complex and will require a
  fair number of iterations to get right
  """

  use Ecto.Schema

  import Ecto.Query, warn: false

  alias Glific.{Messages, Repo}

  @doc """
  Returns the last M conversations, each conversation not more than N messages
  """
  @spec list_conversations(map(), boolean) :: list() | integer
  def list_conversations(args, count \\ false) do
    Messages.list_conversations(
      Map.put(args, :ids, get_message_ids(args.contact_opts, args.message_opts, args)),
      count
    )
  end

  @spec get_message_ids(map(), map(), map() | nil) :: list()
  defp get_message_ids(_contact_opts, message_opts, %{filter: %{id: id}}),
    do: get_message_ids([id], message_opts)

  defp get_message_ids(_contact_opts, message_opts, %{filter: %{ids: ids}}),
    do: get_message_ids(ids, message_opts)

  @spec get_message_ids(list(), map()) :: list()
  defp get_message_ids(ids, %{limit: message_limit, offset: message_offset}) do
    query =
      from m in Messages.Message,
        where:
          m.contact_id in ^ids and
            m.message_number >= ^message_offset and
            m.message_number < ^(message_limit + message_offset),
        select: m.id

    Repo.all(query)
  end
end
