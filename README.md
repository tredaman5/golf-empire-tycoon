# Golf Empire Tycoon

A server-authoritative Roblox tycoon/management game about building, managing, and eventually playing player-designed golf properties.

## Current milestone

Milestone 3 implements versioned DataStore persistence for cash and owned buildings. Players can buy a Driving Range Bay, receive visible customer visits and payments, leave, and return with their cash and bay restored.

Technology: Roblox Studio, Luau, Rojo, and Git.

## Project structure

```text
src/
  shared/                 Shared configuration and types
  server/
    Services/             Data, cash, plot, business, and customer services
    Main.server.luau      Startup and player lifecycle
  client/
    Controllers/          Minimal cash and feedback UI
default.project.json      Rojo mapping
```

## How to run

1. Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/) and its Roblox Studio plugin.
2. Open a terminal in this repository and run `rojo serve`.
3. Open Roblox Studio and create a new Baseplate experience.
4. Open the Rojo plugin, connect to `localhost:34872`, and sync.
5. Press **Play**. No manual objects, remotes, or UI setup is required.

Alternatively, run `rojo build -o GolfEmpireTycoon.rbxlx` and open the resulting place file.

## Persistence setup

Studio persistence is disabled by default, so normal local playtests use temporary session data and cannot overwrite cloud data. Production Roblox servers always use `GolfEmpirePlayerData_v1`.

To test persistence safely in Studio:

1. Publish a separate test version of the experience.
2. In Studio, open **File > Experience Settings > Security**.
3. Enable **Studio Access to API Services** and save the settings.
4. Set `Config.DataStore.EnableInStudio` to `true`.
5. Sync through Rojo and restart the Play session.

Studio uses the separate `GolfEmpirePlayerData_Studio_v1` store. Restore `EnableInStudio` to `false` after testing.

## How to test

### One player

1. Press Play and confirm `Cash: $500`.
2. Find your labeled property and approach its yellow purchase pad.
3. Hold the prompt. Confirm the bay appears and cash becomes $250.
4. Confirm the purchase pad is gone, preventing a duplicate purchase.
5. Confirm a visible customer walks onto the property and uses the bay.
6. Confirm additional customers queue rather than using an occupied bay.
7. After a customer finishes practicing, confirm cash becomes $275 and the customer leaves.
8. Confirm every completed visit adds $25; merely arriving or waiting must not pay revenue.

### Insufficient funds

The normal flow always affords the only purchase. To exercise this branch, temporarily set `Config.StartingCash` below 250, sync, attempt the purchase, verify the feedback, then restore it to 500.

### Multiplayer

1. In Studio's **Test** tab, start a local server with 2-4 players.
2. Confirm every player receives a different labeled plot and independent $500 balance.
3. Walk one player to another player's pad; the purchase must be rejected.
4. Buy on each owner's plot and confirm independent bays and income.
5. Confirm each plot has an independent customer queue and only pays its owner.
6. Disconnect a player and confirm their customers, business, and plot are cleaned up.

### Persistence

1. Complete the Studio persistence setup above.
2. Join, buy the Driving Range Bay, and complete at least one customer visit.
3. Record the current cash balance, stop the session, and start a new session.
4. Confirm the saved cash balance is restored.
5. Confirm the bay is already built, no purchase pad appears, and customers resume visiting.
6. Repeat with 2-4 local players and confirm their records remain independent.
7. Disable Studio API access temporarily and confirm a failed load does not create or save default data.

## Architecture and security

`Main` initializes services and owns player lifecycle. `PlayerDataService` validates versioned records, retries cloud operations, serializes saves, autosaves, and protects failed loads from destructive fallback saves. `CashService` is the sole currency writer. `PlotService` generates and assigns plots. `BusinessService` validates purchases and restores configured buildings. `CustomerService` manages cancellable customer lifecycles, queues, movement, and visit payments.

The server creates each purchase prompt and receives the triggering player's identity from Roblox. It looks up the trusted price, verifies plot and building ownership, and spends authoritative cash. There is no client-to-server economy remote; the only remote carries server-to-client feedback.

## Known limitations

- Four placeholder plots are generated; a fifth simultaneous player gets no plot.
- Geometry and UI are deliberately basic.
- Customers use deterministic movement across the generated flat plots rather than general-purpose pathfinding.
- Roblox Studio execution cannot be automated from this repository, so use the checklist above.
- Playable golf, course design, prestige, monetization, and other future systems are out of scope.

## Recommended Milestone 4

Add the first meaningful facility upgrade and a small management decision so players begin shaping how their golf business operates instead of following a single purchase path.
