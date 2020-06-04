defmodule Glific.Tags.MessageTag do
  @moduledoc """
  A pipe for managing the message tags
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Glific.{Tags.Tag, Messages.Message}

  alias __MODULE__

  @required_fields [ :message_id, :tag_id]

  @type t() :: %__MODULE__{
          id: non_neg_integer | nil,
          message: Message.t() | Ecto.Association.NotLoaded.t() | nil,
          tag: Tag.t() | Ecto.Association.NotLoaded.t() | nil,
        }

  schema "messages_tags" do
    belongs_to :message, Message
    belongs_to :tag, Tag
  end

  @spec changeset(MessageTag.t(), map()) :: Ecto.Changeset.t()
  def changeset(message, attrs) do
    message
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
