local Config = {}

Config.StartingCash = 500

Config.Plots = {
	Count = 4,
	Size = Vector3.new(90, 1, 70),
	Spacing = 110,
}

Config.Buildings = {
	DrivingRangeBay = {
		DisplayName = "Driving Range Bay",
		Price = 250,
		CustomerPayment = 25,
	},
}

Config.Customers = {
	SpawnInterval = 8,
	ServiceDuration = 6,
	WalkSpeed = 12,
	MaxQueueSize = 3,
}

return Config
