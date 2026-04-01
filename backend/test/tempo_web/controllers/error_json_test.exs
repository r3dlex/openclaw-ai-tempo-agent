defmodule TempoWeb.ErrorJSONTest do
  use ExUnit.Case, async: true

  test "render/2 returns error detail for 404" do
    result = TempoWeb.ErrorJSON.render("404.json", %{})
    assert %{errors: %{detail: detail}} = result
    assert is_binary(detail)
  end

  test "render/2 returns error detail for 500" do
    result = TempoWeb.ErrorJSON.render("500.json", %{})
    assert %{errors: %{detail: detail}} = result
    assert is_binary(detail)
  end
end
