-- Put this into a module script and place it into the Generalized Combat Controller

local playerTable = {}

function playerTable.Update(NewTable)
	playerTable = NewTable
end

function playerTable.Get(player)
	return playerTable[player.UserId]
end 

return playerTable
