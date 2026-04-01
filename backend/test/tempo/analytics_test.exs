defmodule Tempo.AnalyticsTest do
  use ExUnit.Case, async: true

  alias Tempo.Analytics

  @sample_data [
    %{
      "dateRange" => %{"startDate" => "2025-11-24T00:00:00Z", "endDate" => "2025-11-25T00:00:00Z"},
      "creditsConsumed" => "54389",
      "groupKey" => "alice@example.com"
    },
    %{
      "dateRange" => %{"startDate" => "2025-11-24T00:00:00Z", "endDate" => "2025-11-25T00:00:00Z"},
      "creditsConsumed" => "12000",
      "groupKey" => "bob@example.com"
    },
    %{
      "dateRange" => %{"startDate" => "2025-11-25T00:00:00Z", "endDate" => "2025-11-26T00:00:00Z"},
      "creditsConsumed" => "30000",
      "groupKey" => "alice@example.com"
    }
  ]

  describe "compute_user_stats/1" do
    test "aggregates credits per user" do
      stats = Analytics.compute_user_stats(@sample_data)

      alice = Enum.find(stats, &(&1.email == "alice@example.com"))
      assert alice.total_credits == 84389
      assert alice.days_active == 2
    end

    test "computes average_daily correctly" do
      stats = Analytics.compute_user_stats(@sample_data)
      alice = Enum.find(stats, &(&1.email == "alice@example.com"))
      # 84389 / 2 days
      assert alice.average_daily == 84389 / 2
    end

    test "returns last_active date" do
      stats = Analytics.compute_user_stats(@sample_data)
      alice = Enum.find(stats, &(&1.email == "alice@example.com"))
      assert alice.last_active == "2025-11-25"
    end

    test "sorts by total credits descending" do
      [first | _] = Analytics.compute_user_stats(@sample_data)
      assert first.email == "alice@example.com"
    end

    test "returns empty list for empty input" do
      assert Analytics.compute_user_stats([]) == []
    end

    test "handles numeric credits" do
      data = [
        %{"date" => "2025-11-24", "creditsConsumed" => 500, "email" => "charlie@example.com"}
      ]

      stats = Analytics.compute_user_stats(data)
      assert length(stats) == 1
      charlie = hd(stats)
      assert charlie.total_credits == 500
      assert charlie.days_active == 1
      assert charlie.average_daily == 500.0
    end

    test "handles unparseable credits as 0" do
      data = [
        %{"date" => "2025-11-24", "creditsConsumed" => "not_a_number", "email" => "x@example.com"}
      ]

      stats = Analytics.compute_user_stats(data)
      assert hd(stats).total_credits == 0
    end

    test "handles missing credits field as 0" do
      data = [%{"date" => "2025-11-24", "email" => "x@example.com"}]
      stats = Analytics.compute_user_stats(data)
      assert hd(stats).total_credits == 0
    end

    test "falls back to email key when groupKey missing" do
      data = [%{"date" => "2025-11-24", "creditsConsumed" => "100", "email" => "d@example.com"}]
      stats = Analytics.compute_user_stats(data)
      assert hd(stats).email == "d@example.com"
    end

    test "falls back to unknown when no user key present" do
      data = [%{"date" => "2025-11-24", "creditsConsumed" => "100"}]
      stats = Analytics.compute_user_stats(data)
      assert hd(stats).email == "unknown"
    end

    test "handles unknown date" do
      data = [%{"creditsConsumed" => "100", "email" => "e@example.com"}]
      stats = Analytics.compute_user_stats(data)
      assert hd(stats).last_active == "unknown"
    end

    test "single user single day has average_daily equal to total" do
      data = [
        %{
          "dateRange" => %{
            "startDate" => "2025-11-24T00:00:00Z",
            "endDate" => "2025-11-25T00:00:00Z"
          },
          "creditsConsumed" => "200",
          "groupKey" => "only@example.com"
        }
      ]

      stats = Analytics.compute_user_stats(data)
      s = hd(stats)
      assert s.days_active == 1
      assert s.average_daily == 200.0
    end
  end

  describe "compute_daily_aggregates/1" do
    test "groups by date and sums credits" do
      aggregates = Analytics.compute_daily_aggregates(@sample_data)

      day1 = Enum.find(aggregates, &(&1.date == "2025-11-24"))
      assert day1.total_credits == 66389
      assert day1.user_count == 2
    end

    test "sorts chronologically" do
      [first, second] = Analytics.compute_daily_aggregates(@sample_data)
      assert first.date < second.date
    end

    test "returns empty list for empty input" do
      assert Analytics.compute_daily_aggregates([]) == []
    end

    test "counts unique users per day" do
      data = [
        %{
          "dateRange" => %{"startDate" => "2025-11-24T00:00:00Z", "endDate" => ""},
          "creditsConsumed" => "100",
          "groupKey" => "a@example.com"
        },
        %{
          "dateRange" => %{"startDate" => "2025-11-24T00:00:00Z", "endDate" => ""},
          "creditsConsumed" => "200",
          "groupKey" => "a@example.com"
        }
      ]

      [day] = Analytics.compute_daily_aggregates(data)
      # same user counted once
      assert day.user_count == 1
      assert day.total_credits == 300
    end

    test "handles date key format" do
      data = [
        %{"date" => "2025-12-01T00:00:00Z", "creditsConsumed" => 50, "email" => "f@example.com"}
      ]

      [day] = Analytics.compute_daily_aggregates(data)
      assert day.date == "2025-12-01"
    end

    test "handles unknown date" do
      data = [%{"creditsConsumed" => "100", "email" => "g@example.com"}]
      [day] = Analytics.compute_daily_aggregates(data)
      assert day.date == "unknown"
    end
  end
end
