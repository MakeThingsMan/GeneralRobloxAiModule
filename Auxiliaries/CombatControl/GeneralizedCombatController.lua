local Players					= game:GetService("Players")
local damageClass  				= require(script.DamageClass)
local NpcHitboxHandler			= game.ServerStorage:WaitForChild("NpcHitboxHandler")
local ss 						= game.ServerStorage:WaitForChild("SendStats")
local ts 						= game.ServerStorage:WaitForChild("TakeStats")
local cEvent 					= game.ServerStorage:WaitForChild("CombatEvent")
local stunPlayer				= game.ReplicatedStorage:WaitForChild("StunPlayer")
local UpdateStunValue			= game.ReplicatedStorage:WaitForChild("UpdateStunValue")

local stunnedPlayers			= {}

function visualizeHitbox(hitbox,Hrp,radial)
	task.spawn(function()
		local visual 	= Instance.new("Part")

		if radial then 
			visual.Size	= Vector3.new(5,hitbox,hitbox)
			visual.Orientation	= Vector3.new(0,0,90) 
			visual.Shape= Enum.PartType.Cylinder
		else
			visual.Size = hitbox.Size
		end
		visual.CFrame 	= Hrp.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0,-.5,-2)))  --hitbox.CFrame:ToWorldSpace(CFrame.new(Hrp.CFrame.Position+Vector3.new(0,0,1),Hrp.CFrame.LookVector))
		visual.Anchored = true
		visual.Color	= Color3.new(1, 0.333333, 0.109804)
		visual.Transparency = .8
		visual.CanCollide = false
		visual.CanQuery = false
		visual.CanTouch = false
		visual.Parent	= workspace
		task.wait(1)
		visual:Destroy()
	end)
end

function IsLookingAtPlayer(target,other)
	local playerPosition						=  target.HumanoidRootPart.Position

	local rayOrigin 							=  other.HumanoidRootPart.Position 
	-- this section looks to see if you are in front of the npc or not 

	local targetCFrame = target.HumanoidRootPart.CFrame
	local TargetCoordinates = other.HumanoidRootPart.CFrame:ToObjectSpace(targetCFrame)

	--local x = otherTest.Position.X
	local y = TargetCoordinates.Position.Y
	local z = TargetCoordinates.Position.Z
	return z*-1>0 and -10<y and y<10 -- the *-1 fixes the values to be infront of the npc.
end



cEvent.Event:Connect(function(defender,Attack,aggressor)
	local pStats = ss:Invoke(defender)
	local savedHealth = pStats.Health.Current
	if aggressor then
		Attack.InFrontOfDefender = IsLookingAtPlayer(defender.Character,aggressor)
	end
	pStats = damageClass.Apply(Attack,pStats)

	pStats.States.InCombat.Value = true
	pStats.States.InCombat.Duration += math.ceil((savedHealth-pStats.Health.Current)/10)
	pStats.States.SpStates.Stunned = true 
	stunPlayer:FireClient(defender,Attack.HitStun)
	UpdateStunValue:FireClient(defender,true)
	stunnedPlayers[defender.Name] = {} -- add the player to the stunned players list
	stunnedPlayers[defender.Name].Timer = Attack.HitStun
	stunnedPlayers[defender.Name].Handled = false
	ts:Fire(pStats,script.Name)
end)

NpcHitboxHandler.Event:Connect(function(npc,Hitbox,Attack)
	local HitboxParams = OverlapParams.new()
	HitboxParams.MaxParts = 10
	HitboxParams.RespectCanCollide = false
	HitboxParams.FilterDescendantsInstances = npc:GetDescendants()

	local peopleHit 	= {}
	local personHumanoid
	local hrp = npc.HumanoidRootPart
	visualizeHitbox(Hitbox,hrp,Attack.Radial)

	local Touching 
	if Attack.Radial then 
		Touching = workspace:GetPartBoundsInRadius(hrp.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0,-.5,-2))).Position,Hitbox,HitboxParams)
	else
		Touching = workspace:GetPartBoundsInBox(hrp.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0,-.5,-2))),Hitbox.Size,HitboxParams)--workspace:GetPartsInPart(Hitbox,params)
	end

	for i, v in pairs(Touching) do 
		local x =v.Parent:FindFirstChildWhichIsA("Humanoid") 
		if x then 
			personHumanoid = x
			if not table.find(peopleHit,personHumanoid) then
				table.insert(peopleHit,personHumanoid)
			end
		end
	end
	for i, v in pairs(peopleHit) do 
		if v.Name == "Humanoid" then 
			print("hit the player: ", v.Parent.Name )
			cEvent:Fire(Players[v.Parent.Name],Attack,npc)
		else
			local npcstats = require(game.ServerScriptService.CurrentNpcConfigs[v.Parent.Name.."Config"])
			print(npcstats,personHumanoid)
			npcstats = npcstats.GiveData()
			Attack.InFrontOfDefender = IsLookingAtPlayer(v.Character,npc)
			damageClass.Apply(Attack,npcstats,personHumanoid)
		end
	end
end)