export type PlayerData = {
	Cash: number,
	OwnedBuildings: { [string]: boolean },
	BayCount: number,
	PricingStrategy: string,
	CustomersServed: number,
	LifetimeRevenue: number,
	PuttingGreenOwned: boolean,
	PlotId: number?,
}

export type SavedPlayerData = {
	SchemaVersion: number,
	Cash: number,
	OwnedBuildings: { [string]: boolean },
	BayCount: number,
	PricingStrategy: string,
	CustomersServed: number,
	LifetimeRevenue: number,
	PuttingGreenOwned: boolean,
}

export type BuildingConfig = {
	DisplayName: string,
	Price: number,
	CustomerPayment: number,
}

export type CustomerConfig = {
	SpawnInterval: number,
	ServiceDuration: number,
	WalkSpeed: number,
	MaxQueueSize: number,
}

return {}
