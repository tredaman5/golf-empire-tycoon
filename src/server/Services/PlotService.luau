local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlotService = {}
local plots = {}
local playerDataService

local function makePart(parent, name, size, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Parent = parent
	return part
end

local function addLabel(part, text)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PlotLabel"
	gui.Size = UDim2.fromOffset(260, 50)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(25, 45, 25)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = gui
	return label
end

function PlotService:Init(dataService)
	playerDataService = dataService
	local old = workspace:FindFirstChild("GolfEmpirePlots")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "GolfEmpirePlots"
	folder.Parent = workspace

	for id = 1, Config.Plots.Count do
		local model = Instance.new("Model")
		model.Name = `Plot{id}`
		model.Parent = folder
		local column = (id - 1) % 2
		local row = math.floor((id - 1) / 2)
		local origin = Vector3.new(column * Config.Plots.Spacing - Config.Plots.Spacing / 2, 0, row * 90)
		local ground = makePart(model, "Ground", Config.Plots.Size, origin, Color3.fromRGB(80 + id * 8, 145, 75))
		local sign = makePart(model, "Sign", Vector3.new(12, 5, 1), origin + Vector3.new(0, 3, -30), Color3.fromRGB(88, 55, 35))
		local label = addLabel(sign, `Plot {id} - Available`)
		plots[id] = { Id = id, Model = model, Ground = ground, Origin = origin, Owner = nil, Label = label }
	end
end

function PlotService:AssignPlot(player: Player)
	local data = playerDataService:Get(player)
	if not data then
		return nil
	end
	for _, plot in ipairs(plots) do
		if not plot.Owner then
			plot.Owner = player
			data.PlotId = plot.Id
			plot.Label.Text = `{player.DisplayName}'s Golf Property`
			return plot
		end
	end
	return nil
end

function PlotService:GetPlayerPlot(player: Player)
	local data = playerDataService:Get(player)
	local plot = data and data.PlotId and plots[data.PlotId]
	return if plot and plot.Owner == player then plot else nil
end

function PlotService:OwnsPlot(player: Player, plotId: number): boolean
	local plot = plots[plotId]
	return plot ~= nil and plot.Owner == player
end

function PlotService:ReleasePlot(player: Player)
	local plot = self:GetPlayerPlot(player)
	if not plot then
		return
	end
	plot.Owner = nil
	plot.Label.Text = `Plot {plot.Id} - Available`
	local content = plot.Model:FindFirstChild("PlayerBusiness")
	if content then
		content:Destroy()
	end
	local data = playerDataService:Get(player)
	if data then
		data.PlotId = nil
	end
end

return PlotService
