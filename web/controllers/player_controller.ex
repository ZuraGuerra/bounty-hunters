defmodule Elbuencoffi.PlayerController do
  use Elbuencoffi.Web, :controller
  alias Neo4j.Sips, as: Neo4j
  alias Elbuencoffi.M2x

  defp neo4j!(cypher) do
    [%{"ok" => ok}] = Neo4j.query!(Neo4j.conn, cypher)
    ok
  end

  defp neo4j_ok(cypher) do
    Neo4j.query!(Neo4j.conn, cypher)
    |> case do
      [%{"ok" => ok}] -> ok 
      _ -> nil
    end
  end

  def create(conn, %{"phone" => phone, "nickname" => nickname}) do
    player = existing_player(nickname)
    unless player do
      device_id = M2x.create_player_device(phone, nickname)
      avatar_url = "foo.png"
    	player = neo4j! """
    	CREATE (p:Player {
        id: "#{device_id}",
    		phone: "#{phone}", 
    		nickname: "#{nickname}", 
        avatar_url: "#{avatar_url}",
    		money: 100
      })
      RETURN p as ok
    	"""
    end
  	json(conn, player)
  end

  defp existing_player(nickname) do
    neo4j_ok """
    MATCH (p:Player {nickname: "#{nickname}"})
    RETURN p as ok
    """
  end

  def update_location(conn, %{"id" => id, "latitude" => latitude, "longitude" => longitude}) do
    M2x.update_location(id, latitude, longitude)
  	player = neo4j! """
  	MATCH (p:Player {id: "#{id}"})
  	SET p.latitude = #{latitude}, p.longitude = #{longitude}
  	RETURN p as ok
  	"""
    perform_near_matches(id, latitude, longitude)
    show(conn, %{"id" => id})
  end

  def show(conn, %{"id" => id}) do
  	player = neo4j! """
  	MATCH (p:Player {id: "#{id}"})
  	RETURN p as ok
  	"""
    player = Map.put(player, "pending_matches", pending_matches(id))
    player = Map.put(player, "won_matches", won_matches(id))
    player = Map.put(player, "lost_matches", lost_matches(id))
  	json(conn, player)
  end

  defp perform_near_matches(player_id, latitude, longitude) do
    M2x.device_near_location("place,player", latitude, longitude)
    |> Enum.map(&perform_device_match(&1, player_id))
  end

  defp perform_device_match(%{attributes: %{"id" => other_id, "tags" => ["player"]}}, player_id) do
    unless other_id == player_id do
      player_already_challenged(player_id, other_id)
      |> unless do
        player_challenge(player_id, other_id)
      end
    end
  end 

  defp perform_device_match(%{attributes: %{"id" => place_id, "tags" => ["place"]}}, player_id) do
    player_already_loothed_place(player_id, place_id)
    |> unless do
      player_looth_place(player_id, place_id)
    end
  end

  defp player_already_challenged(player_id, other_id) do
    neo4j_ok("""
    MATCH (a:Player {id: "#{player_id}"})-[:Match]-(b:Player {id: "#{other_id}"})
    RETURN b as ok
    """)
  end

  defp player_challenge(player_id, other_id) do
    neo4j!("""
    MATCH (a:Player {id: "#{player_id}"}), (b:Player {id: "#{other_id}"})
    CREATE (a)-[m:Match]->(b)
    SET m.id = str(id(m))
    SET m.latitude_a = a.latitude
    SET m.longitude_a = a.longitude
    SET m.latitude_b = b.latitude
    SET m.longitude_b = b.longitude
    RETURN m as ok
    """)
  end

  defp player_already_loothed_place(player_id, place_id) do
    neo4j_ok("""
    MATCH (a:Player {id: "#{player_id}"})-[:Looths]->(b:Place {id: "#{place_id}"})
    RETURN b as ok
    """)
  end

  defp player_looth_place(player_id, place_id) do
    neo4j!("""
      MATCH (a:Player {id: "#{player_id}"}), (b:Place {id: "#{place_id}"})
      SET a.money = a.money + b.bounty
      CREATE (a)-[:Looths]->(b)
      RETURN a as ok
    """)
  end

  defp pending_matches(player_id) do
    cypher = """
    MATCH (a:Player {id: "#{player_id}"})-[m:Match]->(b:Player)
    RETURN m, b    
    """
    Neo4j.query!(Neo4j.conn, cypher)
    |> Enum.map(fn %{"b" => other, "m" => match} -> 
      %{
        id: match["id"],
        nickname: other["nickname"],
        money: other["money"],
        avatar_url: other["avatar_url"]
      }
    end)
  end

  defp lost_matches(player_id) do
    cypher = """
    MATCH (l:Player {id: "#{player_id}"})<-[m:Beats]-(w:Player)
    RETURN m, w    
    """
    Neo4j.query!(Neo4j.conn, cypher)
    |> Enum.map(fn %{"w" => other, "m" => beat} -> 
      %{
        nickname: other["nickname"],
        avatar_url: other["avatar_url"],
        bounty: beat["bounty"]
      }
    end)
  end

  defp won_matches(player_id) do
    cypher = """
    MATCH (w:Player {id: "#{player_id}"})-[m:Beats]->(l:Player)
    RETURN m, l    
    """
    Neo4j.query!(Neo4j.conn, cypher)
    |> Enum.map(fn %{"l" => other, "m" => beat} -> 
      %{
        nickname: other["nickname"],
        avatar_url: other["avatar_url"],
        bounty: beat["bounty"]
      }
    end)
  end

end
