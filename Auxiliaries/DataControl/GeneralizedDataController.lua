-- in studio place this into a script and parent it to the ServerScriptService



local dataStore					= game:GetService("DataStoreService")
local statsData 				= dataStore:GetDataStore("StatsData")
local players 					= game:GetService("Players")
local sendStats 				= game.ServerStorage:WaitForChild("SendStats")
local sendStatsAlter			= game.ServerStorage:WaitForChild("SendStatsAlternative")
local takeStats 				= game.ServerStorage:WaitForChild("TakeStats")
local DR 						= game.ServerStorage:WaitForChild("DataReady")
local NDR 						= game.ServerStorage:WaitForChild("NewPlayerDataReady")
local ReincarnatePlayer 		= game.ServerStorage:WaitForChild("ReincarnatePlayer")
local CDR 						= game.ReplicatedStorage:WaitForChild("CDR")
local NewPlayerScript 			= require(script:WaitForChild("NewPlayer"))
local DC 						= require(script:WaitForChild("Data Converter"))
local PlayerTableAiUpdater		= require(script:WaitForChild("PlayerTableUpdater")) -- used for an optimization within the ai to make them consume less resources
local SpS						= game.ReplicatedStorage:WaitForChild("SendPlayerStats")
local playerTable 				= {}												--holds stats for all current players so we don't do getAsync every time

--players.CharacterAutoLoads 		= false 		

players.PlayerAdded:Connect(function(player)
	local savedStats = nil  --DC.unconvert(statsData:GetAsync(player.UserId)) 		-- set this to the second thing if you want your players stats to save!
------------------------------------------------------------------------------------------------
	if savedStats then									 							-- initialize the players stats when the first spawn in 
		DR:Fire(player,savedStats) 													-- if they have stats then just send them out
	else 
		savedStats = NewPlayerScript.setNewStats(player) 							-- if not then make them new stats
		NDR:Fire(player)
	end
	takeStats:Fire(savedStats)
	CDR:FireClient(player)
	--player:LoadCharacter()
end)

------------------------------------------------------------------------------------------------
ReincarnatePlayer.Event:Connect(function(player)
	local oldStats = playerTable[player.UserId]
	local savedStats = NewPlayerScript.setNewStats(player) -- make a new player
	takeStats:Fire(savedStats)
	player.Character:MoveTo(Vector3.new(-183.799, 0.5, 786.609)) -- change eventually to make players have random spawns
end)
------------------------------------------------------------------------------------------------
takeStats.Event:Connect(function(pstats,from,reason) 								-- Recieves augmented stats from SERVER CONTROLLERS
	playerTable[pstats.playerID] = pstats
	PlayerTableAiUpdater.Update(playerTable)
end)
------------------------------------------------------------------------------------------------	
SpS.OnServerInvoke = function(player) 												-- sends the player CLIENT stats
	return playerTable[player.UserId]
end
------------------------------------------------------------------------------------------------	
sendStats.OnInvoke = function(player)												-- sends SERVER CONTROLLER'S the player stats
	return  playerTable[player.UserId]
end 
------------------------------------------------------------------------------------------------	
sendStatsAlter.OnInvoke = function(Id)
	return playerTable[Id]
end
------------------------------------------------------------------------------------------------	
players.PlayerRemoving:Connect(function(player) 									-- save the players stats when they leave 
	local savedStats = playerTable[player.UserId]
	if savedStats.States.InCombat.Value == true then 
		playerTable[player.UserId].Lives = playerTable[player.UserId].Lives-1
	end
	table.remove(playerTable,player.UserId) 										-- remove the player from the player table to stop a data leak
	local success, failure = pcall(function()
		statsData:SetAsync(player.UserId,DC.convert(savedStats))
	end)
	if success then
		print(player.Name .. " had their stats saved sucessfully ", savedStats)
	else if failure then
			print(warn(player.Name .. " could not save their data trying again"),failure)
			statsData:SetAsync(player.UserId,DC.convert(savedStats))
		end
	end
end)