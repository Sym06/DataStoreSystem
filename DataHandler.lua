local DataHandler = {}

local rs = game:GetService("ReplicatedStorage")
local profileService = require(script.Parent.ProfileService)
local globals = require(rs:WaitForChild("Modules").Globals)
local Players = game:GetService("Players")

local template = {
	Keybinds = {
		Shiftlock = "LeftControl",
		Sprint = "LeftShift"
	},
	Currency = 0,
	MaxStamina = 100
}

local profileStore = profileService.GetProfileStore(
	"PREALPHA1",
	template
)

local Profiles = {}

local function PlayerAdded(plr: Player)
	local profile = profileStore:LoadProfileAsync("Player_"..plr.UserId)

	if profile then
		profile:AddUserId(plr.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[plr] = nil
			plr:Kick("Failed to leave. Don't worry your data is safe.")
		end)

		if plr:IsDescendantOf(Players) == true then
			Profiles[plr] = profile
		else
			profile:Release()
		end

	else
		plr:Kick("Failed to load data.")
	end
end

function DataHandler:Init()
	for i,v in Players:GetPlayers() do
		task.spawn(PlayerAdded, v)
	end

	Players.PlayerAdded:Connect(PlayerAdded)

	Players.PlayerRemoving:Connect(function(plr)
		local profile = Profiles[plr]
		if profile then
			repeat wait() until globals.FinishedPlayerSaving[plr.UserId] == true
			profile:Release()
			print('Data saved')
		end
	end)
end

function DataHandler:WaitUntilDataIsLoaded(plr: Player)
	local attempts = 0
	repeat wait() attempts += 1 until Profiles[plr] or attempts == 1000
	if attempts == 1000 and not Profiles[plr] then
		plr:Kick("Failed to load data, please rejoin.")
	end
end

local function getProfile(plr: Player)
	assert(Profiles[plr], string.format("Profile doesn't exit for %s", plr.UserId))
	
	return Profiles[plr]
end

function DataHandler:Get(plr: Player, key, optional)
	local profile = getProfile(plr)
	local returned = nil
	
	assert(profile.Data[key], string.format("Data doesn't exist for %s", plr.UserId))
	
	if type(profile.Data[key]) == "table" then
		returned = profile.Data[key][optional]
	else
		returned = profile.Data[key]
	end
	
	return returned
end

function DataHandler:Set(plr: Player, key: string, value, optional)
	local profile = getProfile(plr)
	assert(profile.Data[key], string.format("Data doesn't exist for %s", plr.UserId))
	
	if type(profile.Data[key]) == "table" then
		profile.Data[key][optional] = value
	else
		profile.Data[key] = value
	end
end

function DataHandler:Update(plr: Player, key: string, callback, optional)
	local profile = getProfile(plr)
	
	local oldData = self:Get(plr, key, optional)
	local newData = callback(oldData)
	
	self:Set(plr, key, newData)
end

function DataHandler:Wipe(plr: Player)
	profileStore:WipeProfileAsync("Player_"..plr.UserId)
	plr:Kick("Data wiped.")
end

return DataHandler