export type PlayerData = {
	Cash: number,
	OwnedBuildings: { [string]: boolean },
	PlotId: number?,
}

export type SavedPlayerData = {
	SchemaVersion: number,
	Cash: number,
	OwnedBuildings: { [string]: boolean },
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
