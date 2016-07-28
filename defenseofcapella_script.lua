-- ****************************************************************************
-- **
-- **  File     : /maps/DefenceOfCapella/DefenceOfCapella_script.lua
-- **  Author(s): Gently
-- **
-- **  Summary  : Mission Script for Defense of Capella
-- ****************************************************************************

local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/utilities.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')

local AssignedObjectives = {}
local ResultCallbacks = {}
 
----------
-- Globals
----------
 
ScenarioInfo.Player = 1
ScenarioInfo.UEFCivilians = 2
ScenarioInfo.UEFAlly = 3
ScenarioInfo.Seraphim = 4
ScenarioInfo.Coop1 = 5
ScenarioInfo.Coop2 = 6
ScenarioInfo.Coop3 = 7
 
--------
-- Locals
--------
 
local Player = ScenarioInfo.Player
local Seraphim = ScenarioInfo.Seraphim
local UEFCivilians = ScenarioInfo.UEFCivilians
local UEFAlly = ScenarioInfo.UEFAlly
local Coop1 = ScenarioInfo.Coop1
local Coop2 = ScenarioInfo.Coop2
local Coop3 = ScenarioInfo.Coop3
 
--------
-- Start-up
--------

function OnStart(Self)
	
		-- Commander Restrictions

	 for _, player in ScenarioInfo.HumanPlayers do
    	ScenarioFramework.RestrictEnhancements({'ResourceAllocation',
												'TacticalNukeMissile',
												'T3Engineering',
												'Teleporter'})
										end
	
	 -- Unit Restrictions
	 
	 for _, player in ScenarioInfo.HumanPlayers do
        ScenarioFramework.AddRestriction(player,
            categories.xal0305 + -- Aeon Sniper Bot
            categories.xaa0202 + -- Aeon Mid Range fighter (Swift Wind)
            categories.xal0203 + -- Aeon Assault Tank (Blaze)
            categories.xab1401 + -- Aeon Quantum Resource Generator
            categories.xas0204 + -- Aeon Submarine Hunter
            categories.xaa0306 + -- Aeon Torpedo Bomber
            categories.xas0306 + -- Aeon Missile Ship
            categories.xab3301 + -- Aeon Quantum Optics Device
            categories.xab2307 + -- Aeon Rapid Fire Artillery
            categories.xaa0305 + -- Aeon AA Gunship
            categories.xrl0302 + -- Cybran Mobile Bomb
            categories.xra0105 + -- Cybran Light Gunship
            categories.xrs0204 + -- Cybran Sub Killer
            categories.xrs0205 + -- Cybran Counter-Intelligence Boat
            categories.xrb2308 + -- Cybran Torpedo Ambushing System
            categories.xrb0104 + -- Cybran Engineering Station 1
            categories.xrb0204 + -- Cybran Engineering Station 2
            categories.xrb0304 + -- Cybran Engineering Station 3
            categories.xrb3301 + -- Cybran Perimeter Monitoring System
            categories.xra0305 + -- Cybran Heavy Gunship
            categories.xrl0305 + -- Cybran Brick
            categories.xrl0403 + -- Cybran Amphibious Mega Bot
            categories.xeb2306 + -- UEF Heavy Point Defense
            categories.xel0305 + -- UEF Percival
            categories.xel0306 + -- UEF Mobile Missile Platform
            categories.xes0102 + -- UEF Torpedo Boat
            categories.xes0205 + -- UEF Shield Boat
            categories.xes0307 + -- UEF Battlecruiser
            categories.xeb0104 + -- UEF Engineering Station 1
            categories.xeb0204 + -- UEF Engineering Station 2
            categories.xea0306 + -- UEF Heavy Air Transport
            categories.xeb2402   -- UEF Sub-Orbital Defense System
			)
		end
	IntroMission1()
end

function OnPopulate(scenario)
   
    ScenarioUtils.InitializeScenarioArmies()
   
    -- Army Colors
    SetArmyColor('UEFAlly', 81, 82, 241)
    SetArmyColor('UEFCivilians', 133, 148, 255)
    SetArmyColor('Seraphim', 167, 150, 2)
    SetArmyColor('Player', 41, 41, 225)
   
     local colors = {
    ['Coop1'] = {255, 200, 0},
    ['Coop2'] = {189, 116, 16},
    ['Coop3'] = {89, 133, 39}
	}
	local tblArmy = ListArmies()
	for army, color in colors do
		if tblArmy[ScenarioInfo[army]] then
		ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
		end
	end
   
    -- Unit cap
    SetArmyUnitCap(UEFAlly, 1500)
    SetArmyUnitCap(Seraphim, 1500)
    SetArmyUnitCap(UEFCivilians, 1500)
   
    -- Spawn Player initial base
    ScenarioUtils.CreateArmyGroup('Player', 'M1Base')
    ScenarioUtils.CreateArmyUnit('UEFCivilians', 'Gate')
    ScenarioInfo.M1ObjectiveUnits = ScenarioUtils.CreateArmyGroup('UEFCivilians', 'M1Objective')
    ScenarioUtils.CreateArmyGroup('Seraphim', 'M1Wreckage', true)
	ScenarioUtils.CreateArmyGroup('UEFCivilians', 'M1Defense')
	
		
	ScenarioInfo.PlayerCDR = ScenarioFramework.SpawnCommander('Player', 'Commander', 'Warp', true, true, PlayerDeath)
	ScenarioFramework.PauseUnitDeath(ScenarioInfo.PlayerCDR)
    ScenarioFramework.CreateUnitDeathTrigger(PlayerDeath, ScenarioInfo.PlayerCDR)
    ScenarioFramework.CreateUnitDamagedTrigger(PlayerLoseToAI, ScenarioInfo.PlayerCDR, .99)
	
	local cmd = IssueMove({ScenarioInfo.PlayerCDR}, ScenarioUtils.MarkerToPosition('Commander_Walk_1'))
	
	ScenarioFramework.SetPlayableArea('M1_Playable_Area', false)
	
	
	ForkThread(function()
	local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'M1Land', 'GrowthFormation')
			  for k, v in units:GetPlatoonUnits() do
				  ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('InitialPlayerPatrol')))
			  end
		end)
		
	
end

-----------
-- End Game  
-----------

function PlayerWin()
    if(not ScenarioInfo.OpEnded) then
        ScenarioInfo.OpComplete = true
        KillGame()
    end
end

function PlayerLoseToAI()
    if(not ScenarioInfo.OpEnded) and (ScenarioInfo.MissionNumber <= 3) then
        IssueClearCommands({ScenarioInfo.PlayerCDR})
        ScenarioInfo.PlayerCDR:Stop()
        for _, player in ScenarioInfo.HumanPlayers do
                    SetAlliance(player, Seraphim, 'Neutral')
                    SetAlliance(Seraphim, player, 'Neutral')
        end
        local units = ArmyBrains[Player]:GetListOfUnits(categories.ALLUNITS - categories.FACTORY, false)
        IssueClearCommands(units)
        units = ArmyBrains[Seraphim]:GetListOfUnits(categories.ALLUNITS - categories.FACTORY, false)
        IssueClearCommands(units)
        ScenarioFramework.EndOperationSafety()
        ScenarioInfo.OpComplete = false
        for k, v in AssignedObjectives do
            if(v and v.Active) then
                v:ManualResult(false)
            end
        end
    end
end    
	
function PlayerDeath()
    if(not ScenarioInfo.OpEnded) then
        ScenarioFramework.EndOperationSafety()
        ScenarioInfo.OpComplete = false
        for k, v in AssignedObjectives do
            if(v and v.Active) then
                v:ManualResult(false)
            end
        end
        ForkThread(
            function()
                WaitSeconds(3)
                UnlockInput()
                KillGame()
            end
        )
    end
end

function PlayerLose()
    if(not ScenarioInfo.OpEnded) then
        ScenarioFramework.EndOperationSafety()
        ScenarioInfo.OpComplete = false
        for k, v in AssignedObjectives do
            if(v and v.Active) then
                v:ManualResult(false)
            end
        end
        WaitSeconds(3)
        KillGame()
    end
end

function KillGame()
    UnlockInput()
    ScenarioFramework.EndOperation(ScenarioInfo.OpComplete, ScenarioInfo.OpComplete)
end

-----------
-- Mission 1
-----------

function IntroMission1()
    ScenarioInfo.MissionNumber = 1
	
	ForkThread(function()
        WaitSeconds(180)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_Land1', 'GrowthFormation')
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1SeraphimLandAttack01')))
            end
        )
    ForkThread(function()
        WaitSeconds(190)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_Air1', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1SeraphimAirAttack01')))
            end
        end)
    ForkThread(function()
        WaitSeconds(360)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_Land2', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1SeraphimLandAttack01')))
            end
        end)
    ForkThread(function()
        WaitSeconds(370)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_Air2', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1SeraphimAirAttack02')))
            end
        end)
	ForkThread(function()
        WaitSeconds(420)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_Land3', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1SeraphimLandAttack01')))
            end
        end)
	ForkThread(function()
        WaitSeconds(430)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_Air3', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1SeraphimAirAttack02')))
            end
        end)

    StartMission1()
end

function StartMission1()
    ScenarioInfo.M1Objective = Objectives.Protect(
        'primary',
        'incomplete',
        'Defend the Civilians',
        'Defend the Civilians from the incoming Seraphim Attack',
        {
            Units = ScenarioInfo.M1ObjectiveUnits,
            Timer = 480,
            NumRequired = 7,
        }
    )
	
		
	table.insert(AssignedObjectives, ScenarioInfo.M1Objective)
	
	ScenarioInfo.M1Objective:AddResultCallback(
		function(result)
			if(result) then
			 IntroMission2()
			 end
		end
	)
end

-----------
-- Mission 2
-----------

function IntroMission2()
    ScenarioInfo.MissionNumber = 2
	

    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFAlly', 'M2Air1', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_UEFAlly_PatrolAir2')))
	end
		
    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFAlly', 'M2Air2', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_UEFAlly_PatrolAir1')))
    end
		
    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFAlly', 'M2Land1', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_UEFAlly_PatrolLand1')))
    end
		
    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFCivilians', 'M2Land1', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_UEFCivilians_LandPatrol1')))
    end
		
    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFCivilians', 'M2Land2', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_UEFCivilians_LandPatrol2')))
    end
	
	ForkThread(function()
        WaitSeconds(300)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2LandAttack1Player', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraLandAttack_Player')))
            end
        end)
	
	ForkThread(function()
        WaitSeconds(330)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2LandAttack1Ally', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraLandAttack_Ally')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(340)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2AirAttack1Player', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraAirAttack_Player_1')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(370)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2AirAttack1Ally', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraAirAttack_Ally_1')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(600)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2LandAttack2Player', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraLandAttack_Player')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(630)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2AirAttack2Player', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraAirAttack_Player_2')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(690)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2AirAttack1Civilians', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraAirAttack_Civilians_1')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(780)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2AirAttack2Civilians', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraAirAttack_Civilians_2')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(830)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2AirAttack3Civilians', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraAirAttack_Civilians_3')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(850)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2LandAttack3Player', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraLandAttack_Player')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(870)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2AirAttack2Ally', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraAirAttack_Ally_2')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(850)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2LandAttack2Ally', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraLandAttack_Ally')))
            end
        end)
	
	ForkThread(function()
        WaitSeconds(900)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2AirAttack1Player', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraAirAttack_Player_1')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(950)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2LandAttack3Player', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraLandAttack_Player')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(1000)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2AirAttack3Player', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraAirAttack_Player_1')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(1080)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2AirAttack4Civilian', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraAirAttack_Civilians_3')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(1300)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2LandAttack2Civilian', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraLandAttack_Civilian')))
            end
        end)
		
	ForkThread(function()
        WaitSeconds(1450)
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2LandAttack4Player', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SeraLandAttack_Player')))
            end
        end)
		
	
	
	ScenarioUtils.CreateArmyGroup('UEFAlly', 'M2Engineers')
	ScenarioUtils.CreateArmyGroup('UEFAlly', 'M2Base')	
	ScenarioUtils.CreateArmyGroup('UEFCivilians', 'M2Defense')
	ScenarioInfo.M2Objective1 = ScenarioUtils.CreateArmyGroup('UEFCivilians', 'M2Objective1')
	ScenarioInfo.M2Objective2 = ScenarioUtils.CreateArmyGroup('UEFCivilians', 'M2Objective2')
	ScenarioUtils.CreateArmyUnit('UEFAlly', 'Commander')
	ScenarioUtils.CreateArmyGroup('Seraphim', 'M2Wreckage', true)
	ScenarioUtils.CreateArmyGroup('Player', 'M2Base')

    StartMission2()
end

function StartMission2()
    ScenarioInfo.M2Objective1 = Objectives.Protect(
        'primary',
        'incomplete',
        'Defend the Civilians',
        'Defend the Civilians from the incoming Seraphim Attack',
        {
            Units = ScenarioInfo.M2Objective1,
            Timer = 160,
            NumRequired = 7,
        }
    )
	
	ScenarioInfo.M2Objective2 = Objectives.Protect(
        'primary',
        'incomplete',
        'Defend the Civilians',
        'Defend the Civilians from the incoming Seraphim Attack',
        {
            Units = ScenarioInfo.M2Objective2,
            Timer = 1700,
            NumRequired = 7,
        }
    )
	
	table.insert(AssignedObjectives, ScenarioInfo.M2Objective1)
	table.insert(AssignedObjectives, ScenarioInfo.M2Objective2)
	
	ScenarioInfo.M2Objective1:AddResultCallback(
		function(result)
			if(result) then
			 IntroMission3()
			 end
		end
	)
	
	ScenarioInfo.M2Objective2:AddResultCallback(
		function(result)
			if(result) then
			 IntroMission3()
			 end
		end
	)

	ScenarioFramework.SetPlayableArea('M2_Playable_Area', true)

end

-- range on base marker should be 64
