defmodule Elbuencoffi.RandomAvatar do
	import Elbuencoffi.Alphabet

	@avatar_base_url "https://raw.githubusercontent.com/ZuraGuerra/bounty-hunters-assets/master/Avatars/"

	def generate(nickname) do
      avatar_code = encrypt(nickname)
      avatar = golemize(avatar_code)
      System.cmd("convert", [
      	"#{Enum.at(avatar, 0)}",
      	"#{Enum.at(avatar, 1)}",
      	"#{Enum.at(avatar, 2)}",
      	"#{Enum.at(avatar, 3)}",
      	"#{Enum.at(avatar, 4)}",
      	"-flatten", "priv/static/images/#{nickname}.png"
      ])
      avatar_url = "/images/#{nickname}.png"
	end

	defp golemize(avatar_code) do
	  back = @avatar_base_url <> "Face#{Enum.at(avatar_code, 0)}/Back.png"
      body = @avatar_base_url <> "Face#{Enum.at(avatar_code, 1)}/Body.png"
      eyes = @avatar_base_url <> "Face#{Enum.at(avatar_code, 2)}/Eyes.png"
      mouth = @avatar_base_url <> "Face#{Enum.at(avatar_code, 3)}/Mouth.png"
      nose = @avatar_base_url <> "Face#{Enum.at(avatar_code, 4)}/Nose.png"
      [back, body, eyes, mouth, nose]
	end

	defp encrypt(nickname) do	
  	  nickname
	  |> String.downcase
	  |> String.to_char_list
      |> Enum.slice(0, 5)
      |> Enum.map(fn x -> 
      	  letter = x - ?a
      	  cond do
      	  	letter > 10 ->
      	  		letter = letter - 10
      	  		if letter > 10 do
      	  			letter = letter - 10
      	  		end
      	  	letter == 0 ->
      	  		letter = 1
      	  	:else ->
                letter
      	  end
      	  letter
      	end)
	end

end