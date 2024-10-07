local players = game:GetService("Players")
local datahandler = require(script.Parent:WaitForChild("DataModules").DataHandler)
local rs = game:GetService("ReplicatedStorage")

local globals = require(rs:WaitForChild("Modules").Globals)

players.CharacterAutoLoads = false

local template = {
	Keybinds = {
		Shiftlock = "LeftControl",
		Sprint = "LeftShift"
	},
	Currency = 0,
	MaxStamina = 100
}

local function dataAssigner(plr: Player)
	local dataFolder = rs:WaitForChild("Data")
	local templateFolder = dataFolder.Template
	
	local playerDataFolder = templateFolder:Clone()
	playerDataFolder.Name = plr.UserId
	playerDataFolder.Parent = dataFolder
	
	local dataLocations = {
		Keybinds = playerDataFolder.Keybinds,
		Currency = playerDataFolder.Currency,
		MaxStamina = playerDataFolder.MaxStamina
	}
	
	xpcall(function()
		local count = 0
		for i,v in pairs(template) do
			if type(v) == "table" then
				for i2,v2 in pairs(v) do
					dataLocations[i][i2].Value = datahandler:Get(plr, i, i2)
				end
			else
				dataLocations[i].Value = datahandler:Get(plr, i)
			end
		end
		
		globals.LoadPlayerCharacter[plr.UserId] = true -- remove to not make char autoload (good for loading later)
		
		repeat 
			wait(.5) count += 1 
			if count == 20 then
				plr:Kick("")
				return
			end
		until globals.LoadPlayerCharacter[plr.UserId] == true
		
		plr:LoadCharacter()
		print('Data loaded')
		
	end, function(output)
		warn("-------------------------\nDATA ERROR: "..output.."\n-------------------------")
		plr:Kick("")
	end)
end

local function dataSaver(plr: Player)
	local dataFolder = rs:WaitForChild("Data")
	local templateFolder = dataFolder.Template
	
	local playerDataFolder = rs.Data[plr.UserId]

	local dataLocations = {
		Keybinds = playerDataFolder.Keybinds,
		Currency = playerDataFolder.Currency,
		MaxStamina = playerDataFolder.MaxStamina
	}
	
	print('Saving data...')
	
	xpcall(function()
		for i,v in pairs(template) do
			if type(v) == "table" then
				for i2,v2 in pairs(v) do
					datahandler:Set(plr, i, dataLocations[i][i2].Value, i2)
				end
			else
				datahandler:Set(plr, i, dataLocations[i].Value)
			end
		end
		
		globals.FinishedPlayerSaving[plr.UserId] = true
	end, function(output)
		warn("-------------------------\nDATA ERROR: "..output.."\n-------------------------")
		plr:Kick("")
	end)
end

game.Players.PlayerAdded:Connect(function(plr)
	datahandler:Init()
	
	globals.LoadPlayerCharacter[plr.UserId] = false
	globals.FinishedPlayerSaving[plr.UserId] = false
	
	datahandler:WaitUntilDataIsLoaded(plr)
	
	dataAssigner(plr)
end)

game.Players.PlayerRemoving:Connect(function(plr)
	dataSaver(plr)
end)