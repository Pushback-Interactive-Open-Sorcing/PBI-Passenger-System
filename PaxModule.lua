--[[
INSTRUCTIONS:

-- Place in replicated storage.

Usage:
- Require the module on the client. (Do not use in production as is prone to attacks.)
- Example: require(game:GetService("ReplicatedStorage"):WaitForChild("PassengerModule")).Spawn()


EXTRAS:
  This open sorced code is protected by the MIT Open Sorced Code licence. 


  Many Thanks:
  PBI Team
]]--





local BagsFolder = game:GetService("ReplicatedStorage").MainItems.PaxBags  -- Folder In ReplicatedStorage that holds the bags

local PAXCOUNT = 100 

local PaxStart = game.Workspace:WaitForChild("PaxStart") -- Reference anypart in the workspace.

local PaxEnd = game.Workspace:WaitForChild("PaxEnd") -- Reference anypart in the workspace.

local PaxFolder = game.Workspace:WaitForChild("PaxFolder") -- Reference the folder in workspace where the pax will be parented to.

local BAGHANDLE = "BagHandle" -- The name of the Part/Meshpart that the passengers will hold the bags with.




------------------------------------------------------------------------------------------
-- DO NOT TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING!!!
------------------------------------------------------------------------------------------




local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local PhysicsService = game:GetService("PhysicsService")

local plane = game.Workspace.Activeplanes:WaitForChild("A320")


local Bags = BagsFolder:GetChildren()

local BAGCHANCE = 85 -- 100 being every time and then smaller chance as the smaller gets bigger

local passenger = {}

warn("startingPax Module")

local userIds = {}

-- =======================================================
--  Friends Pax System
--========================================================
local localplayer = game:GetService("Players").LocalPlayer


local pages = game.Players:GetFriendsAsync(localplayer.UserId)



while true do
	print("[PAX MODULE] Getting Friends 1/7")
	local friends = pages:GetCurrentPage()
	for _, friend in ipairs(friends) do
		table.insert(userIds, friend.Id)
	end

	if pages.IsFinished then
		break
	end
	pages:AdvanceToNextPageAsync()
end




-- =======================================================
--  Bag Function
-- =======================================================
function passenger.Paxbag()
	print("[PAX MODULE] Getting Paxs Bag 2/7") 
	if Bags then

		for i, v in ipairs(Bags) do
			if v:IsA("Model") then
				local randomBag = Bags[math.random(1, #Bags)]
				local PaxBag = math.random(1, 100)



				return randomBag, PaxBag

			end
		end
	else
		return 1, 0
	end
end

-- =======================================================
-- Module Continues
-- =======================================================



local function setPassengerCollisionGroup(rig)
	print("[PAX MODULE] Setting Pax Collition Groups 3/7")
	for _, part in ipairs(rig:GetDescendants()) do
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, "Passenger")
		end
	end
end

function passenger.ApplyRandomAvatar(rig)
	print("[PAX MODULE] Applying Pax Random Avatar 4/7")
	local humanoid = rig:FindFirstChild("Humanoid")
	if not humanoid then return end

	local randomUserId = userIds[math.random(1, #userIds)]
	local desc = Players:GetHumanoidDescriptionFromUserId(randomUserId)
	humanoid:ApplyDescription(desc)
end

function passenger.Move(rig, destinationPart, currentPax)
	print("[PAX MODULE] Starting Movement functions 6/7")
	local humanoid = rig:FindFirstChild("Humanoid")
	local primaryPart = rig.PrimaryPart
	local plane = destinationPart.Parent
	print(plane.Name)
	if not humanoid or not primaryPart or not destinationPart then return end
	--==========================================
	-- Animation
	--==========================================
	local walkaim = Instance.new("Animation")

	walkaim.AnimationId = "rbxassetid://127281884376877"

	local walkTrack = humanoid:LoadAnimation(walkaim)
	-- --==========================================
	-- Animation
	--==========================================

	local path = PathfindingService:CreatePath({AgentRadius = .5 } )
	path:ComputeAsync(primaryPart.Position, PaxStart.Position)

	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		local reachedDestination = false



		local timeout = 60
		local startTime = tick()
		local DebugPoints = {}

		for index, waypoint :PathWaypoint in ipairs(waypoints) do

			humanoid:MoveTo(waypoint.Position)
			walkTrack:Play()

			local reached
			local connection
			local moveToFinishedEvent = humanoid.MoveToFinished
			local eventFired = false

			connection = moveToFinishedEvent:Connect(function(success)
				reached = success
				eventFired = true
			end)

			while not eventFired and (tick() - startTime) < timeout do
				task.wait(0.1)
			end

			connection:Disconnect()

			if not reached then
				break
			end

			if (tick() - startTime) >= timeout then
				break
			end

			if index == #waypoints then
				reachedDestination = true
				for i,v in DebugPoints do
					v:Destroy()
				end
			end
		end

		local PlaneInfoFolder = plane.Information
		local PassengersNeeded = PAXCOUNT
		local PassengerCount = currentPax

		if reachedDestination then
			rig:Destroy()
			PassengerCount += 1
			PassengersNeeded -= 1
		else
			rig:Destroy()
			PassengerCount += 1
			PassengersNeeded -= 1
		end

	else
		warn("Pathfinding failed for passenger")
	end
end

function passenger.Spawn(quantity)
	local currentPax = 0
	print("[PAX MODULE] Spawning Pax 5/7")

	local spawnLocation = PaxStart

	for i = 1, PAXCOUNT do

		local PlaneInfoF = plane.Information
		local PassengersN = PAXCOUNT
		local PassengerC = currentPax
		currentPax = PassengerC + 1
		warn("Pax " .. i .. " out of " .. PAXCOUNT)
		local randomBag, PaxBag = passenger.Paxbag()

		local Passenger = ReplicatedStorage.MainItems.NPCs.Passenger:Clone()
		Passenger.Parent = PaxFolder

		-- :SetPrimaryPartCFrame is deprecated.
		Passenger.PrimaryPart.CFrame = CFrame.new(spawnLocation)

		setPassengerCollisionGroup(Passenger)

		Passenger.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(descendant, "Passenger")
			end
		end)




		passenger.ApplyRandomAvatar(Passenger)

		local humanoid = Passenger:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local scale = 0.25
			if humanoid:FindFirstChild("BodyDepthScale") then
				humanoid.BodyDepthScale.Value = scale
			end
			if humanoid:FindFirstChild("BodyHeightScale") then
				humanoid.BodyHeightScale.Value = scale
			end
			if humanoid:FindFirstChild("BodyWidthScale") then
				humanoid.BodyWidthScale.Value = scale
			end
			if humanoid:FindFirstChild("HeadScale") then
				humanoid.HeadScale.Value = scale
			end
			humanoid.WalkSpeed = 4
			humanoid.JumpPower = 7.5
		end

		if PaxBag <= BAGCHANCE then
			local CurrentBag: Tool = randomBag:Clone()
			CurrentBag.Parent = Passenger

			local arm = Passenger.RightHand
			local _, _, _ = arm.CFrame:ToOrientation()
			CurrentBag.Handle.Handle.CFrame = CFrame.new(arm.Position) * CFrame.Angles(-45, _, _)
			local Handle = CurrentBag:FindFirstDescendant(BAGHANDLE)
			
			local BagWeld = Instance.new("WeldConstraint")
			BagWeld.Part0 = arm
			BagWeld.Part1 = Handle
			BagWeld.Parent = CurrentBag


		end

		task.spawn(function()
			passenger.Move(Passenger, PaxEnd, currentPax)
		end)



	end
end
print("[PAX MODULE] End of Script 7/7")

return passenger
