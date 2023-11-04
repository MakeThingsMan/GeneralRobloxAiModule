--[[
Note to others on v4 if you want to make changes: 
NEVER LET THE CURRENT COMBAT STATE BE "" IF YOU ARE IN COMBAT 
IT WILL ALLOW THE COMBAT CONTROLLER TO OCCUR MORE THAN ONCE AND BLOW UP
Patrolling is extremely efficient and requires very little optimization from my tests
The combat controller is extremely efficient now too 
]]
-- possible states: {"Patrolling","Targetting","Fighting","Attacking","Blocking","Dodging","Idle","Stunned","Stationary",""}
------------------------------------- V4 ----------------------------------------- V4 ---------------------------------------
local pfs 							= game:GetService("PathfindingService")
local Players 						= game:GetService("Players")
local NpcHitboxHandler				= game.ServerStorage:WaitForChild("NpcHitboxHandler")
local getPlayersInRegion 			= game.ServerStorage:WaitForChild("GetPlayersInRegion")
local summonVfx 					= game.ServerStorage:WaitForChild("SummonVfx")
local sendStats						= game.ServerStorage:WaitForChild("SendStats")
local summonWeldedVfx				= game.ServerStorage:WaitForChild("SummonWeldedVfx")
local destroyVfx					= game.ServerStorage:WaitForChild("DestroyVfx")
local npcDodge						= game.ServerStorage:WaitForChild("NpcDodge")
local NpcSkillUse					= game.ServerStorage:WaitForChild("NpcSkillUse")
local screenShake					= game.ReplicatedStorage:WaitForChild("ScreenShake")
local StunPlayer					= game.ReplicatedStorage:WaitForChild("StunPlayer")
local config						= require(script.Parent.NpcConfig)
local Switch						= require(game.ServerScriptService.Switch)
local optimizedPlayerTable			= require(game.ServerScriptService.DataController.PlayerTableUpdater)
local npc 							= script.Parent


script.Parent.NpcConfig.Name		= npc.Name.."Config"
script.Parent[npc.Name.."Config"].Parent = game.ServerScriptService.CurrentNpcConfigs

npc.PrimaryPart:SetNetworkOwner(nil)
local humanoid						= script.Parent:WaitForChild("NpcHumanoid")
local animator						= humanoid.Animator
local loadedAnimations				= {}

--------------------------------------------------------------------------------------- Movement Section
local trueTarget					= {
	Name = "",
	Distance = config.searchRadius*2
}
local currentPatrolNode 			= 1 
local patrolWaypoints				= config.assignedPatrolPath:GetChildren()
local lastPosition				 	= npc.HumanoidRootPart.Position

local pathParams 					= {
	["AgentHeight"] = config.characterHeight;
	["AgentRadius"] = 2;
	["AgentCanJump"] = true,
}

local path = pfs:CreatePath(pathParams)

function FindPlayer()
	if trueTarget.Name ~= "" and Players[trueTarget.Name].Character.Humanoid.Health > 0 then -- If you already have a predetermined target 
		local distance =   npc.HumanoidRootPart.Position - Players[trueTarget.Name].Character.HumanoidRootPart.Position -- check if they're in bounds
		if distance.Magnitude <= config.maxRadius then 
			trueTarget.Distance = distance.Magnitude
			return trueTarget -- if they are in bounds then you return the target otherwise continue searching for the rest of the players in the zones you're allowed to search in 
		else 
			trueTarget.Name = ""
			trueTarget.Distance = config.searchRadius*3 -- make it out of range
		end
	end

	trueTarget = closestPlayer()
	return trueTarget
end

function playersInArea(radius) 
	local inArea = {}
	for i, v in pairs(config.regions) do -- get the availabile players in the regions that you're allowed to check
		local targetablePlayersInRegion = getPlayersInRegion:Invoke(v)
		for i, v in pairs(targetablePlayersInRegion) do 
			local distance = (v.Character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
			if distance <= radius then 
				table.insert(inArea,v) -- add the ones that are in bounds to the list of players 
			end
		end
	end
	return inArea
end

function closestPlayer()
	for i, v in pairs(config.regions) do -- get the availabile players in the regions that you're allowed to check
		local targetablePlayersInRegion = getPlayersInRegion:Invoke(v)
		for i, v in pairs(targetablePlayersInRegion) do 
			local success, distance = CheckInBounds(v) -- check to see which ones are in bounds
			if success and distance < trueTarget.Distance and Players[v.Name].Character.Humanoid.Health > 0  then 
				trueTarget.Name = v.Name 
				trueTarget.Distance = distance
			end
		end
	end
	return trueTarget
end

function closestPlayerByDistance() -- doesn't do the extra calculation to see whether or not the npc is looking at the player
	for i, v in pairs(config.regions) do -- get the availabile players in the regions that you're allowed to check
		local targetablePlayersInRegion = getPlayersInRegion:Invoke(v)
		for i, v in pairs(targetablePlayersInRegion) do 
			local distance = (npc.HumanoidRootPart.Position  - v.Character.HumanoidRootPart.Position).Magnitude  -- check to see which ones are in bounds
			if distance < trueTarget.Distance then 
				trueTarget.Name = v.Name 
				trueTarget.Distance = distance
			end
		end
	end
	return trueTarget
end

function IsLookingAtPlayer(player)
	-- this section looks to see if you are in front of the npc or not 
	local test = player.Character.HumanoidRootPart.CFrame
	local otherTest = npc.HumanoidRootPart.CFrame:ToObjectSpace(test)

	local y = otherTest.Position.Y
	local z = otherTest.Position.Z
	return z*-1>0 and -10<y and y<10 -- *z by -1 to flip the check to be infront of the npc
end

function CheckInBounds(player) -- if the npc is going to be in an area with a bunch of things that could potentially obstruct it's view of the player then you should add the raycast
	local playerPosition						=  player.Character.HumanoidRootPart.Position
	local origin 								=  npc.HumanoidRootPart.Position 
	if not IsLookingAtPlayer(player) then return end
	local distance								= origin-playerPosition
	return distance.Magnitude <= config.searchRadius*.5 and math.abs(distance.Y) <= config.characterHeight, distance.Magnitude
end

function visualize() -- so you can see the various ranges that are there from the config file *IT WILL CAUSE THE AI TO BE INCAPABLE OF TURNING DUE TO THE WELDS*

	local SearchRadius 			= Instance.new("Part")
	local weld 					= Instance.new("Weld")
	SearchRadius.CanCollide 	= false
	SearchRadius.CanQuery		= false
	SearchRadius.CanTouch		= false
	SearchRadius.Anchored		= false
	SearchRadius.Transparency	= .8
	weld.Enabled				= false
	SearchRadius.Color			= Color3.new(0.705882, 0.117647, 1)
	SearchRadius.Position		= npc.HumanoidRootPart.Position
	SearchRadius.Shape 			= Enum.PartType.Cylinder
	SearchRadius.Size			= Vector3.new(config.characterHeight,config.searchRadius,config.searchRadius)
	weld.Part0					= SearchRadius
	weld.Part1					= npc.PrimaryPart
	weld.Parent					= npc.HumanoidRootPart
	SearchRadius.Parent			= workspace
	SearchRadius:SetNetworkOwner(nil)
	weld.Enabled		= true

	local Long 			= Instance.new("Part")
	local weld 			= Instance.new("Weld")
	Long.Transparency	= .8
	Long.CanCollide 	= false
	Long.CanQuery		= false
	Long.CanTouch		= false
	Long.Anchored		= false
	Long.Color			= Color3.new(1, 0.0470588, 0.270588)
	Long.Position		= npc.HumanoidRootPart.Position
	Long.Shape 			= Enum.PartType.Cylinder
	Long.Size			= Vector3.new(config.characterHeight,config.Range.Long,config.Range.Long)
	weld.Part0			= Long
	weld.Part1			= npc.PrimaryPart
	weld.Parent			= npc.HumanoidRootPart
	Long.Parent			= workspace
	Long:SetNetworkOwner(nil)

	local Medium 		= Instance.new("Part")
	local weld 			= Instance.new("Weld")
	Medium.Transparency	= .8
	Medium.CanCollide 	= false
	Medium.CanQuery		= false
	Medium.CanTouch		= false
	Medium.Anchored		= false
	Medium.Color		= Color3.new(1, 0.760784, 0.2)
	Medium.Position		= npc.HumanoidRootPart.Position
	Medium.Shape 		= Enum.PartType.Cylinder
	Medium.Size			= Vector3.new(config.characterHeight,config.Range.Medium,config.Range.Medium)
	weld.Part0			= Medium
	weld.Part1			= npc.PrimaryPart
	weld.Parent			= npc.HumanoidRootPart
	Medium.Parent		= workspace
	Medium:SetNetworkOwner(nil)

	local Short 		= Instance.new("Part")
	local weld 			= Instance.new("Weld")
	Short.Transparency	= .8
	Short.CanCollide 	= false
	Short.CanQuery		= false
	Short.CanTouch		= false
	Short.Anchored		= false
	Short.Color			= Color3.new(0.145098, 1, 0.529412)
	Short.Position		= npc.HumanoidRootPart.Position
	Short.Shape 		= Enum.PartType.Cylinder
	Short.Size			= Vector3.new(config.characterHeight,config.Range.Short,config.Range.Short)
	weld.Part0			= Short
	weld.Part1			= npc.PrimaryPart
	weld.Parent			= npc.HumanoidRootPart
	Short.Parent		= workspace
	Short:SetNetworkOwner(nil)
end

function isVfxPresent(vfxName,data)
	local success, failure = pcall(function()
		local found = workspace.TemporaryVFX[vfxName..npc.Name]
	end)
	return success
end

local waypoints
local nextWaypointIndex
local reachedConnection
local blockedConnection

local function followPath(destination,continuous)
	local start = tick()
	
	while config.currentCombatState == "Attacking" or config.currentCombatState == "Blocking" or config.currentCombatState == "Dodging" do --this is a failsafe in case you're attacking for too long. This shouldn't really ever fire but idk yet.
		task.wait()
		if tick() - start > 3 then 
			print("So could this one honestly")
			config.currentCombatState = "Fighting"
		end
	end

	while config.currentCombatState == "Stunned" do -- you wait to move if you're stunned instead of just returning.
		task.wait()
	end
	
	-- Compute the path
	local success, errorMessage = pcall(function()
		while jumping do task.wait(.1) end
		path:ComputeAsync(npc.HumanoidRootPart.Position, destination)
	end)
	
	if success and path.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		waypoints = path:GetWaypoints()

		-- Detect if path becomes blocked
		blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= nextWaypointIndex then
				-- Stop detecting path blockage until path is re-computed
			
				blockedConnection = nil
				followPath(destination)
				return
			end
		end)

		--Detect when movement to next waypoint is complete
		if not reachedConnection then
			reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
				--print "Triggering the reached connection thing"
				if reached and nextWaypointIndex < #waypoints then
					-- Increase waypoint index and move to next waypoint
					nextWaypointIndex += 1
					moveToPoint(waypoints,nextWaypointIndex)
				else
					if continuous then 
						loadedAnimations.Walk:Stop()
					elseif not continuous and trueTarget ~= "" then
						loadedAnimations.Run:Stop()
					end
					config.currentState = "Idle"
					--disconnect and manually destroy reference to the connections to make sure they aren't causing problems
					reachedConnection:Disconnect()
					blockedConnection:Disconnect()
					reachedConnection = nil
					blockedConnection = nil
				end
			end)
		end

		-- Initially move to second waypoint (first waypoint is path start; skip it)
		nextWaypointIndex = 2
		moveToPoint(waypoints,nextWaypointIndex)
		if not continuous then 
			config.currentState = "Targetting"
		end		
	else
		warn("Path not computed!", errorMessage)
	end
	return 
end

function moveToPoint(waypoints,nextwaypointIndex)
	if waypoints[nextwaypointIndex].Action == Enum.PathWaypointAction.Jump then 
		humanoid.Jump = true
	end
	humanoid:MoveTo(waypoints[nextwaypointIndex].Position)
end

function patrolPath()
	config.currentState = "Patrolling"
	humanoid.WalkSpeed = 8
	loadedAnimations.Walk:Play()
	loadedAnimations.Walk.Looped = true
	followPath(patrolWaypoints[currentPatrolNode].Position + config.assignedPatrolPath.Position,true)
	currentPatrolNode+=1
	if currentPatrolNode > #patrolWaypoints then 
		currentPatrolNode = 1
	end
end

humanoid.StateChanged:Connect(function(old,new)
	if old == Enum.HumanoidStateType.Jumping then 
		jumping = true
	end
	if old == Enum.HumanoidStateType.Landed then 
		jumping = false
	end
end)

--------------------------------------------------------------------------------------- Movement Section End

--------------------------------------------------------------------------------------- Animation Section
function loadAnimations()
	for i, v in pairs(config.animations) do
		local x = Instance.new("Animation")
		x.AnimationId =  v
		x.Name 		  =  i
		loadedAnimations[i] = animator:LoadAnimation(x)
	end 
end

function isAnimationPlaying(AnimationToFind)
	for i, v in pairs(animator:GetPlayingAnimationTracks()) do
		if v.Name == AnimationToFind then 
			return true 
		end
	end
	return false
end

loadAnimations()

--------------------------------------------------------------------------------------- Animation Section End

--------------------------------------------------------------------------------------- Combat Section

function swings() -- this has been generalized to work as long as you make the individual hitboxes, animations, and their respective timings.
	local swingDelay = .2
	for i=1, config.MaxSwings,1 do 
		local distance = (npc.HumanoidRootPart.Position - Players[trueTarget.Name].Character.HumanoidRootPart.Position).Magnitude
		if not config.debounce and distance <= config.Range.Short and config.currentCombatState ~= "Dodging" and config.currentCombatState ~= "Blocking" and not config.States.SpStates.Blocking then
			config.debounce = true 	
			config.currentCombatState = "Attacking"
			loadedAnimations.Idle:Stop()
			loadedAnimations["Swing"..config.swing]:Play()
			local damaging = loadedAnimations["Swing"..config.swing]:GetMarkerReachedSignal("Damage"):Connect(function()
				local hitbox = game.ServerStorage.PremadeHitboxes[config.Hitboxes["Swing"..config.swing]] 
				NpcHitboxHandler:Fire(npc,hitbox,config.Damage["Swing"..config.swing])
			end)
			task.wait(loadedAnimations["Swing"..config.swing].Length)
			if config.swing < config.MaxSwings then
				config.swing+=1
				config.lastSwing = config.swing
			else 
				config.swing=1
				if loadedAnimations.Recovery ~= nil then  -- not everything needs to have a recovery so this will take care of that issue
					loadedAnimations.Recovery:Play()
				end
				task.wait(.1)
			end
			config.debounce = false
			damaging:Disconnect()
		else
			swingDelay = 0
			break
		end
	end
	config.swing = 1
	config.lastSwing = 0
	task.wait(swingDelay) -- give the player some time to counterattack
end

function combatChoice(input) -- make the choices based off the percentages set in the config
	local endResult = {}
	for _, data in pairs(input) do
		for c = 1, data[2], 1 do
			table.insert(endResult, data[1])
		end
	end
	local chosenIndex= math.random(1, #endResult)
	local chosen = endResult[chosenIndex]
	return chosen
end

local combatSwitch = Switch() -- Here you put any and all actions you want the AI to use at the 3 range types.
	
	-- you can add more based off the various skills the ai needs 
	
	:case("Melee",function() -- the basic melee is provided here
		swings()
	end)

	:default(function() --this is required.
		return
	end)

-- This has been generalized such that you can make the ai do whatever you want depending on the config 
-- If you wanted to make a short/medium range npc set the choice for long range as such: choice = "Skip"
function fightActionController(playerDistance,choice) 
	if playerDistance <= config.Range.Short then 
		choice = combatChoice(config.RangeTable.Short)
	elseif playerDistance <= config.Range.Medium and playerDistance > config.Range.Short then
		choice = combatChoice(config.RangeTable.Med)
	elseif playerDistance <= config.Range.Long and playerDistance > config.Range.Medium then
		choice = combatChoice(config.RangeTable.Long) 
	end
	return choice
end

function Block(Data)
	config.blockable = false
	config.currentState = "Stationary"
	config.currentCombatState = "Blocking"
	config.States.SpStates.Blocking = true 
	config.Block.Cooldown = 1 
	summonWeldedVfx:Fire("Block",npc.HumanoidRootPart,Data,false)
	loadedAnimations.Block.Priority = Enum.AnimationPriority.Action2
	loadedAnimations.Block:Play()
	loadedAnimations.Block:GetMarkerReachedSignal("Pause"):Connect(function() -- your block animation must have a marker in it on the frame you want it paused.
		loadedAnimations.Block:AdjustSpeed(0)
		config.Block.Cooldown += 2.1
	end)
end

function Dodge(dodgePriority)
	config.dodgeable = false
	config.currentState = "Stationary"
	config.DodgeCooldown = 1
	local directionTable = {
		DodgeForward = npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,-17)),
		DodgeBack	 = npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,12)),
		DodgeRight	 = npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(12,0,0)),
		DodgeLeft 	 = npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(-12,0,0)),		
	}
	local cardinal = {npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,-17)),npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(12,0,0)),npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0,0,12)),npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(-12,0,0))}
	local dodgeDirection
	local direction = Vector3.new(0,0,0)
	if dodgePriority ~= "" then 
		dodgeDirection = dodgePriority
	else
		local cardinalDirections = {0,0,0,0} -- starting from forward and ending on your left
		local otherCardinalThing = {"DodgeForward","DodgeRight","DodgeBack","DodgeLeft"}
		for i=1,4,1 do 
			local theta = 90*i
			local x = math.cos(theta)*10
			local z = math.sin(theta)*10
			task.spawn(function()
				local rayOrigin 							=  npc.HumanoidRootPart.Position
				local rayDirection 							=  npc.HumanoidRootPart.CFrame:PointToWorldSpace(Vector3.new(x,0,z))
				local raycastParams 						= RaycastParams.new()
				raycastParams.FilterDescendantsInstances 	= {script.Parent}
				raycastParams.FilterType					= Enum.RaycastFilterType.Exclude
				local raycastResult 						= workspace:Raycast(rayOrigin, rayDirection,raycastParams)
				if raycastResult == nil then 
					cardinalDirections[i] 					= true	 
					return
				end
				cardinalDirections[i] 						= false
			end)
		end
		local tally = 0
		for i, v in pairs(cardinalDirections) do
			if v then
				tally+=1
			end
		end	
		if tally == 0 then print("no room to dodge") config.currentState = "" return end 
		local x = math.random(1,tally)
		direction += cardinal[x]
		dodgeDirection = otherCardinalThing[x]
	end
	loadedAnimations[dodgeDirection]:Play()
	direction += directionTable[dodgeDirection]
	local dodgeStart = loadedAnimations[dodgeDirection]:GetMarkerReachedSignal("Dodge"):Connect(function()
		config.currentCombatState = "Dodging"
		local startTime = loadedAnimations[dodgeDirection]:GetTimeOfKeyframe("DodgeStart")
		local endTime	= loadedAnimations[dodgeDirection]:GetTimeOfKeyframe("DodgeEnd")
		local totalTime = endTime-startTime
		npcDodge:Fire(npc,direction,totalTime,dodgeDirection,true)
		config.DodgeCooldown += 2.1
		task.wait(totalTime)
		config.currentCombatState = "Idle" -- this could cause problems i'm pretty sure
	end)
	task.wait(loadedAnimations[dodgeDirection].Length)
	dodgeStart:Disconnect()
	config.currentState = ""
end

function combatControl()
	local target		= trueTarget.Name
	task.spawn(function() -- this section controlls attacking 
		while trueTarget.Name ~= "" and trueTarget.Distance <= config.searchRadius and Players[target].Character.Humanoid.Health > 0 do --handles the player actually being in range!
			if target ~= trueTarget.Name then return end

			while config.currentCombatState == "Stunned" or config.currentState == "Stationary"  do  -- while you're stunned you do nothing
				task.wait()
			end
			
			while config.currentCombatState == "Blocking" or config.currentCombatState == "Dodging" do 
				task.wait()
				if config.currentCombatState == "Idle" then 
					config.currentCombatState = "Fighting"
					break
				end
			end 

			local choice
			local start = tick()
			while config.currentState == "Targetting" and trueTarget.Distance <= config.Range[config.preferedRange] do 
				task.wait()
				if tick() - start == 3 then 
					config.currentState = ""
					config.currentCombatState = "Fighting"
				end
			end
			
			if config.currentState ~= "Stationary" then 
				if trueTarget.Distance > config.Range[config.preferedRange] and config.currentCombatState == "Fighting" then 
					local x = math.random(1,3)
					if x == 1 then 
						choice = fightActionController(trueTarget.Distance,choice)
						combatSwitch(choice)
						config.currentCombatState = "Fighting"
					else
						config.currentCombatState = "Fighting"
					end
				else
					choice = fightActionController(trueTarget.Distance,choice)
					combatSwitch(choice)
					config.currentCombatState = "Fighting"
				end 
				config.currentState = ""
			end
			config.currentCombatState = config.currentCombatState
			task.wait(config.reactionTime/2)
		end
		config.currentCombatState = ""
		config.currentState = "Idle"
	end)

	task.spawn(function() -- this section controlls defending 
		local Data			= {}

		Data.Player	   		= npc
		Data.Name 			= "Block"..npc.Name
		Data.Destroy 		= -1 -- in this case it just waits for everything to be over
		Data.Lifetime		= .15 -- the amount of time before it gets removed by the debris service
		Data.Npc			= true

		while trueTarget.Name ~= "" do  -- doesn't have to check if the player is in range because the fighting section does that already
			task.wait(config.reactionTime/2)
			if target ~= trueTarget.Name then return end -- break out so you don't have to deal with errors stemming from not having an actual name from the target 

			local pStats = optimizedPlayerTable.Get(Players[trueTarget.Name]) --sendStats:Invoke(Players[trueTarget.Name]) -- that is a 1000x improvement in performance right there my boy!
			
			if pStats.States.SpStates.Attacking == true and config.currentCombatState ~= "Blocking" and config.Block.Cooldown == 0 and config.stunTimer == 0 and config.currentCombatState ~= "Stunned" then 
				for i, v in pairs(animator:GetPlayingAnimationTracks()) do -- no idea if this section actually does anything ngl but hey theoretically it should...
					if v.Name == "Swing"..config.swing then
						if not v:GetMarkerReachedSignal("Damage") then 
							v:Stop()
						else
							while v.isPlaying do task.wait() end
							config.blockable = false
							config.dodgeable = false
							break
						end
					else 
						v:Stop()
					end
				end

				if config.blockable and config.Block.Cooldown == 0  and config.dodgeable and config.DodgeCooldown == 0 then
					local blockChance 	= 50
					local dodgeChance 	= 50
					local bluffChance	= 0
					local dodgePriority = ""
					local skillWeight 	= 30 
					local backstabWeight= 20
					local distance = (npc.HumanoidRootPart.Position - Players[trueTarget.Name].Character.HumanoidRootPart.Position).Magnitude 

					if pStats.States.SpStates.UsingLongSkill or pStats.States.SpStates.UsingMediumSkill or pStats.States.SpStates.UsingShortSkill then --if the player is using a skill then you want to dodge
						blockChance -= skillWeight
						dodgeChance += skillWeight
					elseif distance >= config.Range.Short then -- if the person isn't using skills but is attacking and isn't in melee range then you call the bluff and keep going.
						blockChance = 1
						dodgeChance = 1
						bluffChance = 98
					end

					if not IsLookingAtPlayer(Players[trueTarget.Name]) then --if the player you're targetting gets behind you then you want to dodge forward.
						dodgeChance+= backstabWeight
						blockChance-= backstabWeight
						dodgePriority = "DodgeForward"
					end

					local choices = {{"Block",blockChance},{"Dodge",dodgeChance},{"CallBluff",bluffChance}} 
					local choice = combatChoice(choices)

					if choice == "Block" and config.Block.Cooldown == 0 and config.blockable then 
						task.wait(config.reactionTime) 
						Block(Data)
						task.wait(.1)
					elseif choice == "Dodge" and config.DodgeCooldown == 0 and config.dodgeable then
						Dodge(dodgePriority)
						task.wait(.1) -- just so it doesn't try to block straight after 
					elseif choice == "CallBluff" and config.currentCombatState ~= "Attacking" then
						config.currentState = "Idle"
						config.currentCombatState = "Fighting"
						task.wait(config.reactionTime)
					end
				elseif config.blockable and config.DodgeCooldown <= 1.5 and config.Block.Cooldown == 0 and config.currentState ~= "Stationary" then --if dodgeable is false and you didn't just dodge then you block this next hit
					task.wait(config.reactionTime) 
					Block(Data)
					task.wait(.1)
				elseif config.dodgeable and config.Block.Cooldown == 0 and config.currentState ~= "Stationary"  then -- if all everything else fails then you dodge in a random direction
					Dodge(nil)
				end
			elseif config.currentCombatState == "Blocking" or config.States.SpStates.Blocking == true then
				if pStats.States.SpStates.Attacking == false then 
					config.States.SpStates.Blocking = false
					destroyVfx:Fire("Block",Data,false)
					loadedAnimations.Block:Stop()
					task.wait(.1)
					config.currentCombatState = "Idle"
					config.currentState = ""
					config.blockable = true
				end
			end
			if config.currentState == "Stationary" then -- you don't want to waste your time moving if you're meant to be stationary
				humanoid:MoveTo(npc.HumanoidRootPart.Position)
			end 
		end
		
		if isVfxPresent("Block") then
			destroyVfx:Fire("Block",Data,false)
			loadedAnimations.Block:Stop()
		end
	end)

	task.spawn(function() -- this does the cooldown for skills and blocking
		local tickrate = .1
		while trueTarget.Name ~= "" do
			task.wait(tickrate)
			config.Block.Cooldown 	= math.clamp(config.Block.Cooldown-tickrate,0,3) 
			config.stunTimer 		= math.clamp(config.stunTimer-tickrate,0,3)
			config.DodgeCooldown 	= math.clamp(config.DodgeCooldown-tickrate,0,3)
			for i,v in pairs(config.onCooldown) do
				config.onCooldown[i] = math.clamp(v - tickrate,0,math.huge)
			end
			if config.currentCombatState == "Stunned" and config.stunTimer == 0 then 
				config.currentCombatState = "Idle"
			end
			
			config.dodgeable = config.DodgeCooldown == 0 and config.dodgeable == false
			
			if config.Block.Cooldown == 0 and config.blockable == false then
				config.blockable = true
				config.Block.Current = config.Block.Max
			end
			if config.onCooldown.Enchant < 20 and config.States.SpStates.Enchanted then
				config.States.SpStates.Enchanted = false
				config.Damage.Swing1.Damage -= 5
				config.Damage.Swing2.Damage -= 5
				npc.EliteArmor.Weapon.Edge.Color 	= Color3.new(0.678431, 0.376471, 0.145098)
				npc.EliteArmor.Weapon.Edge.Material = Enum.Material.Metal
			end
		end
		
		if config.States.SpStates.Enchanted then 
			config.States.SpStates.Enchanted = false
			config.Damage.Swing1.Damage -= 5
			config.Damage.Swing2.Damage -= 5
			npc.EliteArmor.Weapon.Edge.Color 	= Color3.new(0.678431, 0.376471, 0.145098)
			npc.EliteArmor.Weapon.Edge.Material = Enum.Material.Metal
		end
	end)

	task.spawn(function() -- turns the npc in the direction of the player constantly
		local target = trueTarget.Name
		local alignOrientation 		= Instance.new("BodyGyro")
		alignOrientation.Parent 	= npc.HumanoidRootPart
		alignOrientation.CFrame		= Players[trueTarget.Name].Character.HumanoidRootPart.CFrame
		alignOrientation.MaxTorque	= Vector3.new(10000,10000,10000)
		alignOrientation.P			= 10000
		while trueTarget.Name ~= "" and trueTarget.Name ~= target do
			local playerPos	   = Players[trueTarget.Name].Character.HumanoidRootPart.CFrame.Position
			alignOrientation.CFrame = CFrame.new(npc.HumanoidRootPart.Position,playerPos)
			task.wait(.05)	
		end
		alignOrientation:Destroy()
	end)
end

local currentHealth = humanoid.Health

humanoid.HealthChanged:Connect(function(health) -- this deals with the character taking damage
	local change = currentHealth - health
	if change > 1 then 
		config.blockable = false -- let the npc know that it's not allowed to block this attack because it's been hit
		config.dodgeable = false -- likewise with the dodging

		if config.currentCombatState == "" then -- force the npc to go into combat and make sure that it's stunned to begin with
			if trueTarget.Name == "" then 
				trueTarget = closestPlayerByDistance()
			end
			config.currentCombatState = "Stunned" --You need to know if you're stunned before going into the combat controller but cant put this before or after
			combatControl()
		else
			config.currentCombatState = "Stunned"
		end

		for i, v in pairs(animator:GetPlayingAnimationTracks()) do -- this may not be needed we'll see..
			v:Stop()
		end
		
		local x = math.random(1,3)

		local anim = "Hit"..x
		if config.States.SpStates.GuardBroken then 
			anim = "GuardBreak"
		end
		loadedAnimations[anim].Priority = Enum.AnimationPriority.Action4
		loadedAnimations[anim]:Play()
		task.wait(loadedAnimations[anim].Length)
		loadedAnimations[anim]:Stop()

		currentHealth = health
		config.stunTimer = .5 -- replace tomorrow with the stun number from the attack.
	end
end)
--------------------------------------------------------------------------------------- Combat Section End

--------------------------------------------------------------------------------------- Main Section

while humanoid.Health > 0 do -- this one simply moves towards the player that is the closest
	FindPlayer()
	if config.currentCombatState == "" and trueTarget.Distance <= config.InitiateCombatRange and IsLookingAtPlayer(Players[trueTarget.Name]) then 
		config.currentCombatState = "Fighting"
		config.currentState = ""
		loadedAnimations.Run:Stop()
		loadedAnimations.Walk:Stop()
		combatControl()
	elseif trueTarget.Name ~= "" and (config.currentCombatState == "" or config.currentCombatState == "Fighting")   and config.currentState ~= "Stationary" then -- if you have targets and you aren't blocking
		if isAnimationPlaying("Run") == false and  config.currentState ~= "Targetting" then -- plays your running animation again assuming it loops
			humanoid.WalkSpeed = 16
			loadedAnimations.Run:Play()
			loadedAnimations.Run.Looped = true
		end
		local complete = followPath(Players[trueTarget.Name].Character.PrimaryPart.Position)
		task.wait(.3) --this limits the amount of times the controller actually recalculates the path .3 worked best for me.
	elseif config.currentState ~= "Patrolling" and config.currentState ~= "Targetting" and config.currentCombatState == "" and config.currentState ~= "Stationary" then 
		loadedAnimations.Run:Stop()
		if config.currentState == "Idle" then
			loadedAnimations.Idle:Play()
			loadedAnimations.Idle.Looped = true
			task.wait(math.random(5,30)/10)
			loadedAnimations.Idle:Stop()
		end
		patrolPath()	
	end 
	lastPosition = npc.HumanoidRootPart.Position
	config.currentMovementState = config.currentState
	task.wait(.05)
end

script.Enabled=false
--------------------------------------------------------------------------------------- Main Section End