defmodule Tempo.MqClient do
  @moduledoc """
  Client for the OpenClaw Inter-Agent Message Queue (IAMQ).

  Handles:
  - Agent registration on startup
  - Periodic heartbeat to maintain presence
  - Inbox polling for incoming messages
  - Sending messages to other agents
  - Broadcasting to all agents

  Configuration via environment variables:
  - IAMQ_HTTP_URL: Base URL for the MQ HTTP API (default: http://127.0.0.1:18790)
  - IAMQ_AGENT_ID: This agent's ID (default: tempo_agent)
  - IAMQ_HEARTBEAT_MS: Heartbeat interval in ms (default: 300_000)
  - IAMQ_POLL_MS: Inbox poll interval in ms (default: 60_000)
  """
  use GenServer
  require Logger

  @default_url "http://127.0.0.1:18790"
  @default_agent_id "tempo_agent"
  @default_heartbeat_ms 300_000
  @default_poll_ms 60_000

  # --- Public API ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc "Send a message to another agent."
  def send_message(to, subject, body, opts \\ []) do
    GenServer.call(__MODULE__, {:send, to, subject, body, opts})
  end

  @doc "Broadcast a message to all agents."
  def broadcast(subject, body, opts \\ []) do
    send_message("broadcast", subject, body, opts)
  end

  @doc "Fetch unread messages from our inbox."
  def inbox(status \\ "unread") do
    GenServer.call(__MODULE__, {:inbox, status})
  end

  @doc "Mark a message as read/acted/archived."
  def ack(message_id, status \\ "read") do
    GenServer.call(__MODULE__, {:ack, message_id, status})
  end

  @doc "List all registered agents."
  def agents do
    GenServer.call(__MODULE__, :agents)
  end

  @doc "Get MQ service status."
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(state) do
    config = %{
      url: System.get_env("IAMQ_HTTP_URL", @default_url),
      agent_id: System.get_env("IAMQ_AGENT_ID", @default_agent_id),
      heartbeat_ms: parse_int(System.get_env("IAMQ_HEARTBEAT_MS"), @default_heartbeat_ms),
      poll_ms: parse_int(System.get_env("IAMQ_POLL_MS"), @default_poll_ms)
    }

    state = Map.merge(state, %{config: config, registered: false, consecutive_failures: 0})

    # Attempt registration after a short delay (let other services start)
    Process.send_after(self(), :register, 2_000)

    {:ok, state}
  end

  @impl true
  def handle_info(:register, state) do
    case do_register(state.config) do
      :ok ->
        Logger.info("[MQ] Registered as #{state.config.agent_id} at #{state.config.url}")
        schedule_heartbeat(state.config.heartbeat_ms)
        schedule_poll(state.config.poll_ms)
        {:noreply, %{state | registered: true, consecutive_failures: 0}}

      {:error, reason} ->
        Logger.warning("[MQ] Registration failed: #{inspect(reason)}. Retrying in 30s...")
        Process.send_after(self(), :register, 30_000)
        {:noreply, %{state | consecutive_failures: state.consecutive_failures + 1}}
    end
  end

  @impl true
  def handle_info(:heartbeat, state) do
    case do_heartbeat(state.config) do
      :ok ->
        schedule_heartbeat(state.config.heartbeat_ms)
        {:noreply, %{state | consecutive_failures: 0}}

      {:error, reason} ->
        Logger.warning("[MQ] Heartbeat failed: #{inspect(reason)}")
        failures = state.consecutive_failures + 1

        if failures >= 5 do
          Logger.error("[MQ] 5 consecutive failures — re-registering")
          Process.send_after(self(), :register, 5_000)
          {:noreply, %{state | registered: false, consecutive_failures: failures}}
        else
          schedule_heartbeat(state.config.heartbeat_ms)
          {:noreply, %{state | consecutive_failures: failures}}
        end
    end
  end

  @impl true
  def handle_info(:poll_inbox, state) do
    case do_poll_inbox(state.config) do
      {:ok, messages} when messages != [] ->
        Enum.each(messages, &handle_incoming_message/1)
        schedule_poll(state.config.poll_ms)
        {:noreply, state}

      {:ok, _empty} ->
        schedule_poll(state.config.poll_ms)
        {:noreply, state}

      {:error, reason} ->
        Logger.debug("[MQ] Inbox poll failed: #{inspect(reason)}")
        schedule_poll(state.config.poll_ms)
        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:send, to, subject, body, opts}, _from, state) do
    result = do_send(state.config, to, subject, body, opts)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:inbox, status}, _from, state) do
    result = do_poll_inbox(state.config, status)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:ack, message_id, status}, _from, state) do
    result = do_ack(state.config, message_id, status)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:agents, _from, state) do
    result = do_list_agents(state.config)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    result = do_status(state.config)
    {:reply, result, state}
  end

  # --- Internal Functions ---

  defp do_register(%{url: url, agent_id: agent_id}) do
    payload = %{
      agent_id: agent_id,
      name: System.get_env("IAMQ_AGENT_NAME", "Tempo"),
      emoji: System.get_env("IAMQ_AGENT_EMOJI", "\u{23F1}\uFE0F"),
      description:
        System.get_env(
          "IAMQ_AGENT_DESC",
          "AI tool analytics \u2014 aggregates usage data from Augment Code, GitHub Copilot, and Claude into unified dashboards"
        ),
      capabilities:
        parse_caps(
          System.get_env(
            "IAMQ_AGENT_CAPABILITIES",
            "analytics,augment_code,github_copilot,claude_usage,dashboard,data_aggregation,usage_reporting"
          )
        ),
      workspace: File.cwd!()
    }

    case Req.post("#{url}/register", json: payload, receive_timeout: 5_000) do
      {:ok, %{status: status}} when status in [200, 201] -> :ok
      {:ok, %{status: status, body: body}} -> {:error, "HTTP #{status}: #{inspect(body)}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_heartbeat(%{url: url, agent_id: agent_id}) do
    case Req.post("#{url}/heartbeat", json: %{agent_id: agent_id}, receive_timeout: 5_000) do
      {:ok, %{status: status}} when status in [200, 201] -> :ok
      {:ok, %{status: status, body: body}} -> {:error, "HTTP #{status}: #{inspect(body)}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_poll_inbox(config, status \\ "unread") do
    %{url: url, agent_id: agent_id} = config

    case Req.get("#{url}/inbox/#{agent_id}", params: [status: status], receive_timeout: 5_000) do
      {:ok, %{status: 200, body: %{"messages" => messages}}} ->
        {:ok, messages}

      {:ok, %{status: 200, body: body}} when is_list(body) ->
        {:ok, body}

      {:ok, %{status: status_code, body: body}} ->
        {:error, "HTTP #{status_code}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_send(config, to, subject, body, opts) do
    %{url: url, agent_id: agent_id} = config

    payload = %{
      from: agent_id,
      to: to,
      type: Keyword.get(opts, :type, "info"),
      priority: Keyword.get(opts, :priority, "NORMAL"),
      subject: subject,
      body: body,
      replyTo: Keyword.get(opts, :reply_to, nil),
      expiresAt: Keyword.get(opts, :expires_at, nil)
    }

    case Req.post("#{url}/send", json: payload, receive_timeout: 5_000) do
      {:ok, %{status: status, body: resp}} when status in [200, 201] -> {:ok, resp}
      {:ok, %{status: status, body: body}} -> {:error, "HTTP #{status}: #{inspect(body)}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_ack(config, message_id, new_status) do
    %{url: url} = config

    case Req.patch("#{url}/messages/#{message_id}",
           json: %{status: new_status},
           receive_timeout: 5_000
         ) do
      {:ok, %{status: status}} when status in [200, 204] -> :ok
      {:ok, %{status: status, body: body}} -> {:error, "HTTP #{status}: #{inspect(body)}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_list_agents(%{url: url}) do
    case Req.get("#{url}/agents", receive_timeout: 5_000) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, "HTTP #{status}: #{inspect(body)}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_status(%{url: url}) do
    case Req.get("#{url}/status", receive_timeout: 5_000) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, "HTTP #{status}: #{inspect(body)}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_incoming_message(message) do
    from = message["from"] || "unknown"
    subject = message["subject"] || "(no subject)"
    msg_type = message["type"] || "info"
    msg_id = message["id"]

    Logger.info("[MQ] Received #{msg_type} from #{from}: #{subject}")

    case msg_type do
      "request" ->
        route_request(message)
        do_ack(%{url: System.get_env("IAMQ_HTTP_URL", @default_url)}, msg_id, "acted")

      "info" ->
        Logger.info("[MQ] Info from #{from}: #{message["body"]}")
        do_ack(%{url: System.get_env("IAMQ_HTTP_URL", @default_url)}, msg_id, "read")

      "response" ->
        Logger.info("[MQ] Response from #{from}: #{message["body"]}")
        do_ack(%{url: System.get_env("IAMQ_HTTP_URL", @default_url)}, msg_id, "read")

      "error" ->
        Logger.error("[MQ] Error from #{from}: #{message["body"]}")
        do_ack(%{url: System.get_env("IAMQ_HTTP_URL", @default_url)}, msg_id, "read")

      _ ->
        Logger.debug("[MQ] Unknown message type: #{msg_type}")
    end
  end

  defp route_request(message) do
    subject = message["subject"] || ""
    from = message["from"] || "unknown"

    cond do
      String.contains?(subject, "analytics") or String.contains?(subject, "usage") ->
        Logger.info("[MQ] Analytics/usage request from #{from} — queuing for processing")

      String.contains?(subject, "report") ->
        Logger.info("[MQ] Report request from #{from}")

      String.contains?(subject, "status") ->
        Logger.info("[MQ] Status request from #{from}")

      true ->
        Logger.info("[MQ] Unhandled request from #{from}: #{subject}")
    end
  end

  defp schedule_heartbeat(ms), do: Process.send_after(self(), :heartbeat, ms)
  defp schedule_poll(ms), do: Process.send_after(self(), :poll_inbox, ms)

  defp parse_int(nil, default), do: default

  defp parse_int(str, default) do
    case Integer.parse(str) do
      {val, _} -> val
      :error -> default
    end
  end

  defp parse_caps(s) do
    s |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end
end
