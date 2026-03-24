defmodule Tempo.Analytics do
  @moduledoc """
  Analytics computation module.
  Transforms raw data points into user stats and daily aggregates.
  """

  @doc """
  Compute per-user statistics from raw data points.

  Returns a list of maps with:
  - email: user identifier
  - total_credits: sum of all credits consumed
  - average_daily: average credits per active day
  - days_active: number of unique days with activity
  - last_active: most recent activity date
  """
  def compute_user_stats(data_points) do
    data_points
    |> Enum.group_by(&extract_user/1)
    |> Enum.map(fn {email, records} ->
      credits = Enum.map(records, &parse_credits/1) |> Enum.sum()
      dates = Enum.map(records, &extract_date/1) |> Enum.uniq()
      days_active = length(dates)

      last_active =
        dates
        |> Enum.sort(:desc)
        |> List.first()

      %{
        email: email,
        total_credits: credits,
        average_daily: if(days_active > 0, do: credits / days_active, else: 0),
        days_active: days_active,
        last_active: last_active
      }
    end)
    |> Enum.sort_by(& &1.total_credits, :desc)
  end

  @doc """
  Compute daily aggregate statistics from raw data points.

  Returns a list of maps with:
  - date: the day (string)
  - total_credits: sum of credits for that day
  - user_count: number of unique users active that day
  """
  def compute_daily_aggregates(data_points) do
    data_points
    |> Enum.group_by(&extract_date/1)
    |> Enum.map(fn {date, records} ->
      credits = Enum.map(records, &parse_credits/1) |> Enum.sum()
      users = Enum.map(records, &extract_user/1) |> Enum.uniq() |> length()

      %{
        date: date,
        total_credits: credits,
        user_count: users
      }
    end)
    |> Enum.sort_by(& &1.date)
  end

  defp extract_user(%{"groupKey" => key}), do: key
  defp extract_user(%{"email" => email}), do: email
  defp extract_user(_), do: "unknown"

  defp extract_date(%{"dateRange" => %{"startDate" => start_date}}) do
    start_date |> String.slice(0, 10)
  end

  defp extract_date(%{"date" => date}), do: String.slice(date, 0, 10)
  defp extract_date(_), do: "unknown"

  defp parse_credits(%{"creditsConsumed" => credits}) when is_binary(credits) do
    case Integer.parse(credits) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp parse_credits(%{"creditsConsumed" => credits}) when is_number(credits), do: credits
  defp parse_credits(_), do: 0
end
