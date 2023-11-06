-- Place this into a module script and parent it to the Generalized Combat Controller

local module 		= {}
local baseStats 	= require(script.Parent:WaitForChild("BaseStats"))

function module.setNewStats(player)
	local tempStats = baseStats
	tempStats.playerID = player.UserId
	---------------------- Talent Calculation section
	local talent  = 16 --math.floor(16*math.pow(math.cos(.133*y+.2),2))
	---------------------- Constitution Assignment 
	tempStats.PlayerName = player.Name
	return tempStats
end

return module

