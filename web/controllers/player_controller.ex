defmodule Elbuencoffi.PlayerController do
  use Elbuencoffi.Web, :controller
  alias Neo4j.Sips, as: Neo4j

  def create(conn, params) do
  	cypher = """
  	CREATE (p:Player {
  		phone: "#{params[:phone]}", 
  		nickname: "#{params[:nickname]}", 
  		money: 100
  	    })
    RETURN id(p) as id
  	"""
  	[result] = Neo4j.query!(Neo4j.conn, cypher)
  	json(conn, %{id: result["id"]})
  end
end
