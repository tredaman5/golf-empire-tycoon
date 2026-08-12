# Golf Empire Tycoon

A server-authoritative Roblox tycoon/management game about building, managing, and eventually playing player-designed golf properties.

## Current milestone

Milestone 1 implements: join, receive one of four generated plots, start with $500, buy a Driving Range Bay for $250, and earn $25 every 10 seconds. It includes a minimal cash UI and purchase feedback.

Technology: Roblox Studio, Luau, Rojo, and Git.

## Project structure

```text
src/
  shared/                 Shared configuration and types
  server/
    Services/             Data, cash, plot, and business services
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

## How to test

### One player

1. Press Play and confirm `Cash: $500`.
2. Find your labeled property and approach its yellow purchase pad.
3. Hold the prompt. Confirm the bay appears and cash becomes $250.
4. Confirm the purchase pad is gone, preventing a duplicate purchase.
5. Wait 10 seconds; confirm cash becomes $275 and continues rising by $25.

### Insufficient funds

The normal flow always affords the only purchase. To exercise this branch, temporarily set `Config.StartingCash` below 250, sync, attempt the purchase, verify the feedback, then restore it to 500.

### Multiplayer

1. In Studio's **Test** tab, start a local server with 2-4 players.
2. Confirm every player receives a different labeled plot and independent $500 balance.
3. Walk one player to another player's pad; the purchase must be rejected.
4. Buy on each owner's plot and confirm independent bays and income.
5. Disconnect a player and confirm their plot becomes available and their business disappears.

## Architecture and security

`Main` initializes services and owns player lifecycle. `PlayerDataService` stores session-only records. `CashService` is the sole currency writer. `PlotService` generates and assigns plots. `BusinessService` validates purchases, creates configured buildings, and manages cancellable income tasks.

The server creates each purchase prompt and receives the triggering player's identity from Roblox. It looks up the trusted price, verifies plot and building ownership, and spends authoritative cash. There is no client-to-server economy remote; the only remote carries server-to-client feedback.

## Known limitations

- Data is session-only; DataStore persistence is intentionally deferred.
- Four placeholder plots are generated; a fifth simultaneous player gets no plot.
- Geometry and UI are deliberately basic.
- Roblox Studio execution cannot be automated from this repository, so use the checklist above.
- NPCs, golf mechanics, course design, prestige, monetization, and other future systems are out of scope.

## Recommended Milestone 2

Add a small server-simulated customer flow so revenue corresponds to visible customer visits, then add persistence with schema versioning and safe Studio testing behavior.
