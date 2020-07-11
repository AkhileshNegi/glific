defmodule Glific.Flows.Flow do
  @moduledoc """
  The flow object which encapsulates the complete flow as emitted by
  by `https://github.com/nyaruka/floweditor`
  """
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias Glific.{
    Contacts.Contact,
    Flows.FlowContext,
    Flows.FlowRevision,
    Flows.Node,
    Repo,
    Settings.Language
  }

  @required_fields [:name, :language_id, :uuid]
  @optional_fields [:flow_type, :version_number, :shortcode]

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: non_neg_integer | nil,
          name: String.t() | nil,
          shortcode: String.t() | nil,
          uuid: Ecto.UUID.t() | nil,
          flow_type: String.t() | nil,
          nodes: [Node.t()] | Ecto.Association.NotLoaded.t() | nil,
          version_number: String.t() | nil,
          language_id: non_neg_integer | nil,
          language: Language.t() | Ecto.Association.NotLoaded.t() | nil,
          revisions: [FlowRevision.t()] | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: :utc_datetime | nil,
          updated_at: :utc_datetime | nil
        }

  schema "flows" do
    field :name, :string
    field :shortcode, :string

    field :version_number, :string
    field :flow_type, :string
    field :uuid, Ecto.UUID
    belongs_to :language, Language

    has_many :nodes, Node, foreign_key: :flow_uuid

    has_many :revisions, FlowRevision

    timestamps(type: :utc_datetime)
  end

  @doc """
  Return the list of filtered tags
  """
  @spec list_flows(map()) :: [Flow.t()]
  def list_flows(args \\ %{}),
    do: Repo.list_filter(args, Flow, &Repo.opts_with_name/2, &Repo.filter_with/2)

  @doc """
  Get a single flow
  """
  @spec get_flow!(integer) :: Flow.t()
  def get_flow!(id), do: Repo.get!(Flow, id)

  @doc """
  Standard changeset pattern we use for all data types
  """
  @spec changeset(Flow.t(), map()) :: Ecto.Changeset.t()
  def changeset(flow, attrs) do
    flow
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:language_id)
  end

  @doc """
  Process a json structure from floweditor to the Glific data types
  """
  @spec process(map(), map()) :: {Flow.t(), map()}
  def process(json, uuid_map) do
    flow = %Flow{
      uuid: json["uuid"],
      language: json["language"],
      name: json["name"]
    }

    {nodes, uuid_map} =
      Enum.reduce(
        json["nodes"],
        {[], uuid_map},
        fn node_json, acc ->
          {node, uuid_map} = Node.process(node_json, elem(acc, 1), flow)
          {[node | elem(acc, 0)], uuid_map}
        end
      )

    flow = Map.put(flow, :nodes, Enum.reverse(nodes))
    uuid_map = Map.put(uuid_map, flow.uuid, {:flow, flow})

    {flow, uuid_map}
  end

  @doc """
  Build the context so we can execute the flow
  """
  @spec context(Flow.t(), map(), Contact.t()) :: FlowContext.t() | {:error, String.t()}
  def context(%Flow{nodes: nodes}, _uuid_map, _contact) when nodes == [],
    do: {:error, "An empty flow cannot have a context or be executed"}

  def context(flow, uuid_map, contact) do
    # get the first node
    node = hd(flow.nodes)

    %FlowContext{
      contact: contact,
      contact_id: contact.id,
      flow: flow,
      flow_uuid: flow.uuid,
      uuid_map: uuid_map,
      node: node,
      node_uuid: node.uuid
    }
  end
end
