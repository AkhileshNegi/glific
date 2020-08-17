defmodule Glific.Flows.FlowCount do
  @moduledoc """
  The flow count object
  """
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query, warn: false

  alias __MODULE__

  alias Glific.{
    Flows.Flow,
    Repo
  }

  @required_fields [:uuid, :flow_id, :type, :count]
  @optional_fields []

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: non_neg_integer | nil,
          uuid: Ecto.UUID.t() | nil,
          flow_id: non_neg_integer | nil,
          flow: Flow.t() | Ecto.Association.NotLoaded.t() | nil,
          type: String.t() | nil,
          count: integer() | nil,
          inserted_at: :utc_datetime | nil,
          updated_at: :utc_datetime | nil
        }

  schema "flow_counts" do
    field :uuid, Ecto.UUID
    belongs_to :flow, Flow
    field :type, :string
    field :count, :integer

    timestamps(type: :utc_datetime)
  end

  @doc """
  Standard changeset pattern we use for all data types
  """
  @spec changeset(FlowCount.t(), map()) :: Ecto.Changeset.t()
  def changeset(flow_revision, attrs) do
    flow_revision
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  @doc false
  @spec create_flow_count(map()) :: {:ok, FlowCount.t()} | {:error, Ecto.Changeset.t()}
  def create_flow_count(attrs \\ %{}) do
    {:ok, flow} = Glific.Repo.fetch_by(Flow, %{uuid: attrs.flow_uuid})

    attrs = Map.merge(attrs, %{flow_id: flow.id})

    %FlowCount{}
    |> FlowCount.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update count
  """
  @spec update_flow_count(map()) :: {:ok, FlowCount.t()}
  def update_flow_count(attrs) do
    {:ok, flow} = Repo.fetch_by(Flow, %{uuid: attrs.flow_uuid})

    query =
      from fc in FlowCount,
        update: [inc: [count: 1]],
        where: fc.flow_id == ^flow.id and fc.uuid == ^attrs.uuid and fc.type == ^attrs.type

    Repo.update_all(query, [])
  end
end
