defmodule Glific.Repo.Migrations.AddTranslationToSessionTemplate do
  @moduledoc """
  Adding translation to session template table
  """
  use Ecto.Migration

  def change do
    translation()
  end

  def translation() do
    alter table(:translations) do
      add :translation, :jsonb, default: "{}"
    end
  end

end
