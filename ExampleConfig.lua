local DamageClass		= require(game.ServerScriptService.GeneralizedCombatController.DamageClass)

local NpcConfig = {
	
	regions = {"Platform of Colossi","TestArea"},
	animations = {
		-- Put in the animation codes for all your states here.
		-- You add new animations for skills here as well!
		Idle 		= "rbxassetid://14342228081",
		Walk 		= "rbxassetid://14342321370",
		Run  		= "rbxassetid://14344281335",
		Swing1		= "rbxassetid://14345135760",
		Swing2		= "rbxassetid://14364132836",
		Block		= "rbxassetid://14425054362",
		Hit1		= "rbxassetid://14430050423", -- "Hit" as in the npc getting hit
		Hit2		= "rbxassetid://14430054014",
		Hit3		= "rbxassetid://14430057390",
		KhanRoar	= "rbxassetid://14364128390", -- this example skill would have an animation attached
		GuardBreak 	= "rbxassetid://14744317013", -- as in the npc getting guard broken
		DodgeBack	= "rbxassetid://14474444970",
		DodgeForward= "rbxassetid://14475061360",
		DodgeRight	= "rbxassetid://14475186279",
		DodgeLeft	= "rbxassetid://14475166469",
	},
	Hitboxes = { 
		-- for this to work you need to have a folder in the ServerStorage that's named "PremadeHitboxes"
		-- from there you need to make a part that is the size you want and from there the Ai will take over
		Swing1 = "KhanWide1",
		Swing2 = "KhanWide1"},
	MaxSwings= 2,
	Damage = {
		KhanRoar	= DamageClass.New("KhanRoar",15,2,.4,false,true), -- The damage is calculated by the server using this damage class.
		Swing1  	= DamageClass.New("Swing1",15,1,.1,true,true),
		Swing2  	= DamageClass.New("Swing2",12,1,.1,true,true)
	},
	Range = {
		Short = 6,
		Medium= 15,
		Long  = 25
	},
	preferedRange = "Short", 				-- This AI likes to be in melee range 
	RangeTable = { 							-- the attacks should be listed in order of least common to most common
		Short = {{"Melee", 80,},{"KhanRoar",20},}, --A range of 1 - 12 studs for this example
		Med = 	{{"KhanRoar",100},}, -- A range of 12 - 30 for this example
		Long = 	{{"Skip",100}}, 	-- A range of 30 - 50 for this example
	},
	onCooldown = {
		KhanRoar  = 0, -- The skills that can go on cooldown go here *KEEP THE NAMES CONSISTENT* 
	},
	faction = "", 							-- not needed
	stunTimer = 0,							-- The amount of time the AI is currently stunned for
	DodgeCooldown = 0,						-- The amount of time befor the AI can dodge again
	jumping						= false,	-- Used by the pathfinding to resolve an issue where the npc gets stuck on top of parts that it attempts to jump over
 	InitiateCombatRange 		= 25, 		-- the range that the npc needs to be at to be able to target the players around it
	reactionTime				= .08, 		-- The amount of delay between the npc seeing that it's going to be attacked and it responding with something.
	swing 						= 1,		-- An internal counter for the AI for it to keep track of the amount of times it has attacked using melee swings
	lastSwing 					= 0,		-- Keeps track of the last swing the AI did to make sure it plays the correct animations
	debounce 					= false,	-- A debounce variable
	currentCombatState			= "",		-- The state the AI is in currently. It could be Attacking, Defending, Dodging, etc. all of that is tracked here.
	blockable 					= true,		-- Tells the AI if it can block currently or not!
	dodgeable					= true,		-- Tells the Ai if it can dodge currently or not!
	searchRadius				= 75, 		-- The radius the AI is allowed to check for players 
	maxRadius 					= 75*.5 + 5,-- The distance the player has to get to before the AI loses interest
	characterHeight				= 6, 		-- Used for the pathfinding, a taller npc means less areas the pathfinding will allow it to go through.
	currentState				= nil,		-- The state variable. It can be set to Patrolling, Targetting, Idle, Stationary, or ""
	assignedPatrolPath			= game.Workspace.PatrolPath1, -- the patrolpath that the npc will follow
	
	---- example stats 
		Race 		= "Human",
		Artifact 	= "N/A",
		Health = { 							-- For health it does need to be structured like this.
			Current = 200, 					-- These values can be changed to your hearts content though!
			Regen 	= 1.3,
			Max 	= 200,
		},
	Block = {								-- Block must be structured like this if you use the included combat controller
		Max = 130 ,
		Current = 130 ,
		Cooldown = 0 
	},
		States = {
			Buffs = {

			},
			SpStates = {
				Blocking			= false, -- Leave this here
				GuardBroken			= false	 -- Leave this here
		}, 
		},
		Defense = {							 -- This must also stay if you use the included combat module.
			Qi 			= 15,
			Physical	= 20,
		},
		Constitution = -1,
		Temperature = 0,
		MovementSpeed = 1,
	
}
return NpcConfig