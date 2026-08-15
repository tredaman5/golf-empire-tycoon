local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local services = script.Parent.Services
local PlayerDataService = require(services.PlayerDataService)
local CashService = require(services.CashService)
local PlotService = require(services.PlotService)
local CustomerService = require(services.CustomerService)
local BusinessService = require(services.BusinessService)

local remotes = Instance.new("Folder")
remotes.Name = "GolfEmpireRemotes"
remotes.Parent = ReplicatedStorage
local feedbackEvent = Instance.new("RemoteEvent")
feedbackEvent.Name = "Feedback"
feedbackEvent.Parent = remotes

PlayerDataService:Init()
CashService:Init(PlayerDataService)
PlotService:Init(PlayerDataService)
CustomerService:Init(PlayerDataService, CashService, PlotService, feedbackEvent)
BusinessService:Init(PlayerDataService, CashService, PlotService, CustomerService, feedbackEvent)
PlayerDataService:StartAutosave()

local function onPlayerAdded(player)
	player:SetAttribute("StatusMessage", "Loading golf empire...")
	if not PlayerDataService:Load(player) then
		if player.Parent then
			player:Kick("Your golf empire could not be loaded safely. Please rejoin and try again.")
		end
		return
	end
	if not player.Parent then
		PlayerDataService:Save(player)
		PlayerDataService:Remove(player)
		return
	end
	local plot = PlotService:AssignPlot(player)
	if not plot then
		player:SetAttribute("StatusMessage", "No golf property is currently available.")
		return
	end
	BusinessService:SetupPlot(player)
	player:SetAttribute("StatusMessage", `Assigned to Plot {plot.Id}.`)
end

local removingPlayers = {}
local activeRemovals = 0
local function onPlayerRemoving(player)
	if removingPlayers[player] then
		return
	end
	removingPlayers[player] = true
	activeRemovals += 1
	BusinessService:CleanupPlayer(player)
	CustomerService:CleanupPlayer(player)
	if not PlayerDataService:Save(player) and PlayerDataService:Get(player) then
		warn(`Final save failed for {player.Name}.`)
	end
	PlotService:ReleasePlot(player)
	PlayerDataService:Remove(player)
	removingPlayers[player] = nil
	activeRemovals -= 1
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	local pending = 0
	for _, player in Players:GetPlayers() do
		if not removingPlayers[player] then
			pending += 1
			task.spawn(function()
				onPlayerRemoving(player)
				pending -= 1
			end)
		end
	end
	local deadline = os.clock() + 25
	while (pending > 0 or activeRemovals > 0) and os.clock() < deadline do
		task.wait(0.1)
	end
end)
