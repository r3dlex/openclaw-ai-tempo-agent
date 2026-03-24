defmodule Tempo.DataStore do
  @moduledoc """
  In-memory data store for AI tool analytics.
  Loads data from JSON files and serves it to the API layer.
  """

  use GenServer

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc "Get all data points for a given source."
  def get_data(source) do
    GenServer.call(__MODULE__, {:get_data, source})
  end

  @doc "Get aggregated user stats for a given source."
  def get_user_stats(source) do
    GenServer.call(__MODULE__, {:get_user_stats, source})
  end

  @doc "Get daily aggregates for a given source."
  def get_daily_aggregates(source) do
    GenServer.call(__MODULE__, {:get_daily_aggregates, source})
  end

  @doc "Reload data from disk."
  def reload do
    GenServer.cast(__MODULE__, :reload)
  end

  # Server Callbacks

  @impl true
  def init(_state) do
    {:ok, load_all_data()}
  end

  @impl true
  def handle_call({:get_data, source}, _from, state) do
    {:reply, Map.get(state, source, []), state}
  end

  @impl true
  def handle_call({:get_user_stats, source}, _from, state) do
    data = Map.get(state, source, [])
    stats = Tempo.Analytics.compute_user_stats(data)
    {:reply, stats, state}
  end

  @impl true
  def handle_call({:get_daily_aggregates, source}, _from, state) do
    data = Map.get(state, source, [])
    aggregates = Tempo.Analytics.compute_daily_aggregates(data)
    {:reply, aggregates, state}
  end

  @impl true
  def handle_cast(:reload, _state) do
    {:noreply, load_all_data()}
  end

  defp load_all_data do
    data_dir = Application.get_env(:tempo, :data_dir, "data")

    %{
      augment: load_augment_data(Path.join(data_dir, "augment_data.json"))
    }
  end

  defp load_augment_data(path) do
    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, %{"dataPoints" => points}} -> points
          {:ok, points} when is_list(points) -> points
          _ -> []
        end

      {:error, _} ->
        []
    end
  end
end
