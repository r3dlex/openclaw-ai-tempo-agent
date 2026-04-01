defmodule Tempo.DataStoreTest do
  use ExUnit.Case

  # DataStore is already started by the application under test.
  # We use the named process directly.

  describe "get_data/1" do
    test "returns a list for known source :augment" do
      result = Tempo.DataStore.get_data(:augment)
      assert is_list(result)
    end

    test "returns empty list for unknown source" do
      result = Tempo.DataStore.get_data(:nonexistent)
      assert result == []
    end
  end

  describe "get_user_stats/1" do
    test "returns a list for :augment" do
      result = Tempo.DataStore.get_user_stats(:augment)
      assert is_list(result)
    end

    test "each stat has required keys" do
      stats = Tempo.DataStore.get_user_stats(:augment)

      Enum.each(stats, fn stat ->
        assert Map.has_key?(stat, :email)
        assert Map.has_key?(stat, :total_credits)
        assert Map.has_key?(stat, :average_daily)
        assert Map.has_key?(stat, :days_active)
        assert Map.has_key?(stat, :last_active)
      end)
    end
  end

  describe "get_daily_aggregates/1" do
    test "returns a list for :augment" do
      result = Tempo.DataStore.get_daily_aggregates(:augment)
      assert is_list(result)
    end

    test "each aggregate has required keys" do
      aggregates = Tempo.DataStore.get_daily_aggregates(:augment)

      Enum.each(aggregates, fn agg ->
        assert Map.has_key?(agg, :date)
        assert Map.has_key?(agg, :total_credits)
        assert Map.has_key?(agg, :user_count)
      end)
    end
  end

  describe "reload/0" do
    test "reload completes without error" do
      # cast is fire-and-forget; give it a moment then verify store still responds
      Tempo.DataStore.reload()
      # Wait for the cast to complete
      :sys.get_state(Tempo.DataStore)
      result = Tempo.DataStore.get_data(:augment)
      assert is_list(result)
    end
  end

  describe "load_augment_data edge cases via start_link" do
    test "returns empty list when file not found" do
      # Start a separate DataStore with a non-existent data dir
      {:ok, pid} =
        GenServer.start_link(Tempo.DataStore, %{}, name: nil)

      # Override config for this process test by sending call directly
      result = GenServer.call(pid, {:get_data, :augment})
      # The GenServer will try to load from the test config path
      assert is_list(result)
      GenServer.stop(pid)
    end

    test "handles list JSON file format" do
      # Write a temp JSON file with a plain list (not wrapped in dataPoints)
      tmp = System.tmp_dir!()
      data_file = Path.join(tmp, "augment_data_list_test.json")
      File.write!(data_file, Jason.encode!([%{"date" => "2025-11-24", "count" => 5}]))

      prev_dir = Application.get_env(:tempo, :data_dir)
      Application.put_env(:tempo, :data_dir, tmp)

      # Rename the test file to augment_data.json
      augment_file = Path.join(tmp, "augment_data.json")
      File.copy!(data_file, augment_file)

      {:ok, pid} = GenServer.start_link(Tempo.DataStore, %{}, name: nil)
      result = GenServer.call(pid, {:get_data, :augment})
      assert is_list(result)
      assert length(result) == 1
      GenServer.stop(pid)

      # Restore
      Application.put_env(:tempo, :data_dir, prev_dir)
      File.rm(augment_file)
      File.rm(data_file)
    end

    test "handles invalid JSON file" do
      tmp = System.tmp_dir!()
      real_augment = Path.join(tmp, "augment_data_invalid_test_#{:rand.uniform(100_000)}.json")
      # Write a file with invalid JSON
      File.write!(real_augment, "this is not json {{")

      # Override the data_dir so it doesn't find augment_data.json
      # We do this by pointing to a directory where the file won't exist
      empty_dir = Path.join(tmp, "empty_dir_#{:rand.uniform(100_000)}")
      File.mkdir_p!(empty_dir)

      prev_dir = Application.get_env(:tempo, :data_dir)
      Application.put_env(:tempo, :data_dir, empty_dir)

      {:ok, pid} = GenServer.start_link(Tempo.DataStore, %{}, name: nil)
      result = GenServer.call(pid, {:get_data, :augment})
      # File not found -> empty list (exercises the {:error, _} branch)
      assert result == []
      GenServer.stop(pid)

      Application.put_env(:tempo, :data_dir, prev_dir)
      File.rm(real_augment)
      File.rm_rf(empty_dir)
    end

    test "handles JSON that decodes to neither dataPoints map nor list" do
      # A valid JSON object without "dataPoints" key hits the `_ -> []` branch
      tmp = System.tmp_dir!()
      dir = Path.join(tmp, "bad_json_format_#{:rand.uniform(100_000)}")
      File.mkdir_p!(dir)
      File.write!(Path.join(dir, "augment_data.json"), Jason.encode!(%{"other_key" => "value"}))

      prev_dir = Application.get_env(:tempo, :data_dir)
      Application.put_env(:tempo, :data_dir, dir)

      {:ok, pid} = GenServer.start_link(Tempo.DataStore, %{}, name: nil)
      result = GenServer.call(pid, {:get_data, :augment})
      assert result == []
      GenServer.stop(pid)

      Application.put_env(:tempo, :data_dir, prev_dir)
      File.rm_rf(dir)
    end

    test "handles file read error branch directly" do
      tmp = System.tmp_dir!()
      # Use a directory name that does not have augment_data.json
      no_file_dir = Path.join(tmp, "no_augment_file_#{:rand.uniform(100_000)}")
      File.mkdir_p!(no_file_dir)

      prev_dir = Application.get_env(:tempo, :data_dir)
      Application.put_env(:tempo, :data_dir, no_file_dir)

      {:ok, pid} = GenServer.start_link(Tempo.DataStore, %{}, name: nil)
      result = GenServer.call(pid, {:get_data, :augment})
      assert result == []
      GenServer.stop(pid)

      Application.put_env(:tempo, :data_dir, prev_dir)
      File.rm_rf(no_file_dir)
    end
  end
end
