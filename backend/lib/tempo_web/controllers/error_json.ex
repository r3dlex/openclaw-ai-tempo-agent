defmodule TempoWeb.ErrorJSON do
  @moduledoc """
  Renders JSON error responses for Phoenix controller errors.

  Returns a JSON body of the form `%{errors: %{detail: "..."}}` where the
  detail message is derived from the HTTP status template (e.g. `"404.json"`).
  """

  @doc false
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
