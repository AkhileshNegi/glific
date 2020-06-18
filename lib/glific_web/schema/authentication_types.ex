defmodule GlificWeb.Schema.AuthenticationTypes do
  @moduledoc """
  GraphQL Representation of Glific's Authentication
  """

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Glific.Repo
  alias GlificWeb.Resolvers

  input_object :authentication_input do
    field :name, :string
    field :phone, :string
    field :password, :string
  end

  object :authentication_mutations do
    field :send_otp, :string do
      arg(:input, non_null(:authentication_input))
      resolve(&Resolvers.Authentication.send_otp/3)
    end
  end
end
