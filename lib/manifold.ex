defmodule Manifold do
  use Application

  alias Manifold.{Partitioner, Utils}

  ## OTP

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Spawn partitions based on number of schedlers (CPU cores).
    partitions = System.schedulers_online

    children = [
      Partitioner.child_spec(partitions, [name: Partitioner]),
    ]

    Supervisor.start_link children,
      strategy: :one_for_one,
      max_restarts: 10,
      name: __MODULE__.Supervisor
  end

  ## Client

  @spec send([pid], term) :: :ok
  def send(pids, message) when is_list(pids) do
    pids
      |> Utils.group_by(fn
        nil -> nil
        pid -> node(pid)
      end)
      |> Enum.each(fn
        {nil, _pids} -> :ok
        {node, pids} -> Partitioner.send({Partitioner, node}, pids, message)
      end)
  end

  @spec send(pid, term) :: :ok
  def send(pid, message) do
    __MODULE__.send([pid], message)
  end
end
