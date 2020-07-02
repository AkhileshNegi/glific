defmodule Glific.Flows.Node do
  @moduledoc """
  The Node object which encapsulates one node in a given flow
  """

  use Glific.Schema
  import Ecto.Changeset

  alias Glific.Flows.{
    Action,
    Exit,
    Flow,
    Router,
  }

  @required_fields [:flow_uuid]
  @optional_fields []

  @type t() :: %__MODULE__{
    __meta__: Ecto.Schema.Metadata.t(),
    uuid: Ecto.UUID.t() | nil,
    flow_uuid: Ecto.UUID.t() | nil,
    flow: Flow.t() | Ecto.Association.NotLoaded.t() | nil,
  }

  schema "nodes" do
    belongs_to :flow, Flow

    has_many :actions, Action
    has_many :exits, Exit
    has_one :router, Router
  end


  @doc """
  Standard changeset pattern we use for all data types
  """
  @spec changeset(Node.t(), map()) :: Ecto.Changeset.t()
  def changeset(Node, attrs) do
    tag
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:flow_id)
  end


end
