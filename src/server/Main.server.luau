local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local services = script.Parent.Services
local PlayerDataService = require(services.PlayerDataService)
local CashService = require(services.CashService)
local PlotService = require(services.PlotService)
local BusinessService = require(services.BusinessService)

local remotes = Instance.new("Folder")
remotes.Name = "GolfEmpireRemotes"
remotes.Parent = ReplicatedStorage
local feedbackEvent = Instance.new("RemoteEvent")
feedbackEvent.Name = "Feedback"
feedbackEvent.Parent = remotes

CashService:Init(PlayerDataService)
PlotService:Init(PlayerDataService)
BusinessService:Init(PlayerDataService, CashService, PlotService, feedbackEvent)

local function onPlayerAdded(player)
	PlayerDataService:Create(player)
	local plot = PlotService:AssignPlot(player)
	if not plot then
		player:SetAttribute("StatusMessage", "No golf property is currently available.")
		return
	end
	BusinessService:SetupPlot(player)
	player:SetAttribute("StatusMessage", `Assigned to Plot {plot.Id}.`)
end

local function onPlayerRemoving(player)
	BusinessService:CleanupPlayer(player)
	PlotService:ReleasePlot(player)
	PlayerDataService:Remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
