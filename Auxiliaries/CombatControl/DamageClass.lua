local Damage = {}

Damage.__index = Damage

function Damage.New(name,damage,armorPen,hitStun,blockable,dodgable)
	if not damage then 
		warn("You didn't assign",name," any damage!")
	end
	
	if not armorPen then
		armorPen = 0
	end

	if not hitStun then 
		hitStun = .25
	end
	
	if blockable == nil then 
		blockable = true 
	end
	
	if dodgable == nil then 
		dodgable = true
	end
	
	local newDamage = {}
	newDamage.Name					= name
	newDamage.Damage				= damage
	newDamage.ArmorPen 				= armorPen
	newDamage.HitStun	 			= hitStun
	newDamage.Blockable				= blockable
	newDamage.Dodgable				= dodgable
	newDamage.InFrontOfDefender		= false
	setmetatable(newDamage,Damage)
	return newDamage
end

function Damage:SelfApply(pStats)
	return Damage.Apply(self,pStats)
end

function Damage.Apply(Attack, pStats, humanoid)
	local damage 		= Attack.Damage
	damage = damage -(math.clamp(pStats.Defense.Physical-Attack.ArmorPen,0,math.huge) ) -- reduces the damage taken by the defense that you have

	
	damage = math.clamp(damage,1,math.huge)
	
	if pStats.States.SpStates.Dodging == true then 
		if  Attack.Dodgable == true then 
			damage = 0 
		else
			pStats.States.SpStates.Dodging = false
		end 
	end
	
	if pStats.States.SpStates.Blocking == true and Attack.InFrontOfDefender then --  Attacking the block directly
		if Attack.Blockable == false then 
			pStats.States.SpStates.Blocking = false
			pStats.States.SpStates.GuardBroken = true
			pStats.Block.Cooldown = 3 -- set the cooldown to 3 seconds before you can block again might be too short we'll see...
			damage *= 1.05
		else
			pStats.Block.Current -= damage
			if pStats.Block.Current <= 0 then 
				pStats.States.SpStates.Blocking = false
				pStats.States.SpStates.GuardBroken = true
				pStats.Block.Cooldown = 3 -- set the cooldown to 3 seconds before you can block again might be too short we'll see...
				damage = math.abs(pStats.Block.Current) 
			else
				damage = 0 
			end
		end
	elseif Attack.InFrontOfDefender == nil then -- this just catches the case where you want to do trap damage for example.
		damage = damage
	elseif pStats.States.SpStates.Blocking == true and not Attack.InFrontOfDefender then -- Backstab
		pStats.States.SpStates.Blocking = false
		pStats.Block.Cooldown = 3
		damage *= 1.02
	end 
	
	if humanoid then 
		humanoid:TakeDamage(damage)
		pStats.stunTimer = Attack.HitStun
		return
	end
	pStats.Health.Current -= damage
	return pStats
end

return Damage