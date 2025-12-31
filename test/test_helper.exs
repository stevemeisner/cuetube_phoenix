ExUnit.start()
Mox.defmock(Cuetube.YouTubeMock, for: Cuetube.YouTube)
Ecto.Adapters.SQL.Sandbox.mode(Cuetube.Repo, :manual)
