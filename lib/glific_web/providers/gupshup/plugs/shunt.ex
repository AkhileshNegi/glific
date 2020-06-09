defmodule GlificWeb.Providers.Gupshup.Plugs.Shunt do
  alias Plug.Conn
  alias GlificWeb.Providers.Gupshup.Router

  def init(opts), do: opts

  def call(%Conn{params: %{"type" => type, "payload" => %{"type" => payload_type}}} = conn, opts) do
    conn
    |> change_path_info(["gupshup", type, payload_type])
    |> Router.call(opts)
  end

  def call(%Conn{params: %{"type" => type}} = conn, opts) do
    conn
    |> change_path_info(["gupshup", type, "unknown"])
    |> Router.call(opts)
  end

  def call(conn, opts) do
    conn
    |> change_path_info(["gupshup", "unknown", "unknown"])
    |> Router.call(opts)
  end

  def change_path_info(conn, new_path),
    do: put_in(conn.path_info, new_path)
end
