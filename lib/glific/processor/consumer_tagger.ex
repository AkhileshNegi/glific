defmodule Glific.Processor.ConsumerTagger do
  @moduledoc """
  Process all messages of type consumer and run them thru the various in-built taggers.
  At a later stage, we will also do translation and dialogflow queries as an offshoot
  from this GenStage
  """

  use GenStage

  alias Glific.{
    Communications,
    Messages.Message,
    Repo,
    Taggers,
    Taggers.Keyword,
    Taggers.Numeric,
    Taggers.Status,
    Tags,
    Tags.Tag
  }

  @min_demand 0
  @max_demand 1

  @doc false
  @spec start_link(any) :: GenServer.on_start()
  def start_link(_), do: GenStage.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc false
  def init(:ok) do
    state = %{
      producer: Glific.Processor.Producer,
      keyword_map: Keyword.get_keyword_map(),
      status_map: Status.get_status_map(),
      numeric_map: Numeric.get_numeric_map(),
      numeric_tag_id: 0
    }

    state =
      case Repo.fetch_by(Tag, %{label: "Numeric"}) do
        {:ok, tag} -> Map.put(state, :numeric_tag_id, tag.id)
        _ -> state
      end

    {:producer_consumer, state,
     subscribe_to: [
       {state.producer,
        selector: fn %{type: type} -> type == :text end,
        min_demand: @min_demand,
        max_demand: @max_demand}
     ]}
  end

  @doc """
  public endpoint for adding a number and a value
  """
  @spec add_numeric(String.t(), integer) :: :ok
  def add_numeric(key, value), do: GenServer.call(__MODULE__, {:add_numeric, {key, value}})

  @doc false
  def handle_call({:add_numeric, {key, value}}, _from, state) do
    new_numeric_map = Map.put(state.numeric_map, key, value)

    {:reply, "Numeric Map Updated", [], Map.put(state, :numeric_map, new_numeric_map)}
  end

  @doc false
  def handle_info(_, state), do: {:noreply, [], state}

  @doc false
  def handle_events(messages, _from, state) do
    messages_with_tags = Enum.map(messages, &process_message(&1, state))

    {:noreply, messages_with_tags, state}
  end

  @spec process_message(atom() | Message.t(), map()) :: Message.t()
  defp process_message(message, state) do
    body = Taggers.string_clean(message.body)

    message
    |> add_status_tag("Unread", state)
    |> new_contact_tagger(state)
    |> numeric_tagger(body, state)
    |> keyword_tagger(body, state)
    |> Repo.preload(:tags)
    |> Communications.publish_data(:created_message_tag)
  end

  @spec numeric_tagger(atom() | Message.t(), String.t(), map()) :: Message.t()
  defp numeric_tagger(message, body, state) do
    case Numeric.tag_body(body, state.numeric_map) do
      {:ok, value} -> add_tag(message, state.numeric_tag_id, value)
      _ -> message
    end
  end

  @spec keyword_tagger(atom() | Message.t(), String.t(), map()) :: Message.t()
  defp keyword_tagger(message, body, state) do
    case Keyword.tag_body(body, state.keyword_map) do
      {:ok, value} -> add_tag(message, value, body)
      _ -> message
    end
  end

  @spec new_contact_tagger(Message.t(), map()) :: Message.t()
  defp new_contact_tagger(message, state) do
    if Status.is_new_contact(message.sender_id) do
      message
      |> add_status_tag("New User", state)
      |> add_status_tag("Language", state)
    end

    message
  end

  @spec add_status_tag(Message.t(), String.t(), map()) :: Message.t()
  defp add_status_tag(message, status, state),
    do: add_tag(message, state.status_map[status])

  @spec add_tag(Message.t(), integer, String.t() | nil) :: Message.t()
  defp add_tag(message, tag_id, value \\ nil) do
    Tags.create_message_tag(%{
      message_id: message.id,
      tag_id: tag_id,
      value: value
    })

    message
  end
end
