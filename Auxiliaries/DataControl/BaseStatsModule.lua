-- Put this into a module script and parent it to the Generalized Data Controller

local playerStats = {	
	["Health"] = {
		["Current"] = 100,
		["Regen"] 	= 1, 
		["Max"] 	= 100,
	},
	["Qi"] = {
		["Current"] = 0,
		["Element1"] = {
			["Element"] = "Neutral",
			["Tier"]	= 1
		},
		["Element2"] = {
			["Element"] = "Neutral",
			["Tier"]	= 1
		},
		["Regen"] 		= 1,
		["Max"] 		= 100,
		["Unlocked"] 	= false
	},
	["States"] = {
		["Buffs"] = {
			
			},
		["InCombat"] = {
			["Value"]	= false,
			["Duration"] = 0,
		},

		["SpStates"] = {
			["RegenOff"] 			= false,
			["Dead"] 				= false, 
			["GuardBroken"]			= false,
			["Blocking"]			= false,
			["Stunned"]				= false,
			["Dodging"]				= false, -- you can guess what this means bruh you're not stupid
			["Attacking"]			= false, -- as in melee attacks
			["UsingShortSkill"]		= false, --->
			["UsingLongSkill"]		= false, --|these tell the ai out there what the player is doing so they can predict that they have to dodge or not.
			["UsingMediumSkill"]	= false}, --->
			}, 
	["Defense"] = {
		["Qi"] 			= 1,
		["Physical"] 	= 1,
	},
	["AugmentingStats"] 	= {
		["Strength"] 		= 1, 		
		["Intelligence"] 	= 1, 	
		["Dexterity"] 		= 1, 		
		["Vitality"]		= 1, 	
	},
	["Achievements"] = {
		["Points"] = 0,
		["Feats"] = {},
	},
	["Bloodlines"] = {
		["Active"] = -1,
		["Obtained"] = {
		["Count"] =0,	
		},
	},
	["Block"] = {
		["Max"] = 100, -- note to self make this actually max out your current because somoene somewhere could make current block a million for all i know 
		["Current"] = 100,
		["Cooldown"] = 0
	}, -- The amount of damage your block can take.
	["Lives"] = 1,
	["playerID"] = "N/a",
}
return playerStats
