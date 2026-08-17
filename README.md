# Golf Empire Tycoon

A server-authoritative Roblox tycoon/management game about building, managing, and eventually playing player-designed golf properties.

## Current milestone

Milestone 5.5 establishes the first visual and property-expansion foundation: landscaped resort plots, a shared multi-bay driving range, animated golfer customers, an arrival and parking district, and a persistent revenue-generating Pro Shop. The Milestone 5 dashboard, metrics, progression, and persistence remain intact.

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

### Driving range management

1. Buy the first bay and confirm the green management kiosk and blue expansion pad appear.
2. Use the kiosk to cycle Value, Standard, and Premium pricing.
3. Confirm payments are $20, $25, and $40 respectively, and customer arrivals visibly slow as prices rise.
4. Earn $750 and purchase the second bay, then purchase Bay 3 for $1,500 and Bay 4 for $2,500.
5. Confirm the shared canopy expands at every step and up to four customers can practice simultaneously without sharing a station.
6. Confirm arrivals accelerate as bays are added; with four bays, Standard pricing should bring a customer roughly every 2.5 seconds and keep several stations active.
7. Leave and rejoin with Studio persistence enabled; confirm all purchased bays and the selected pricing strategy return.
8. Load an existing schema-1 save and confirm it becomes one bay with Standard pricing while retaining cash and ownership.

### Business dashboard and putting green

1. Use the green kiosk to open the dashboard and confirm pricing, customers served, lifetime revenue, queue length, and occupied bays are shown.
2. Change pricing through the dashboard and confirm the server applies the selected strategy.
3. Confirm each arriving customer keeps the payment quoted at arrival even if pricing changes during the visit.
4. Reach 25 customers and $750 lifetime revenue; confirm the purple Putting Green purchase pad appears.
5. Purchase the Putting Green for $1,000 and confirm the green, cup, pole, and flag appear.
6. Confirm periodic customers use the Putting Green, display `Putting...`, and pay $35.
7. Rejoin with persistence enabled and confirm metrics, pricing, bays, and Putting Green return.

### Visual foundation

1. Confirm plots have grass, cobblestone entry paths, trees, shrubs, and warm daylight rather than an exposed Baseplate presentation.
2. Confirm the range has a shared metal canopy, multiple hitting stations, mats, baskets, targets, and surrounding safety netting.
3. Confirm the management kiosk has a roof and illuminated screen.
4. Confirm the Putting Green is circular with a fringe, cup, pole, and flag.
5. Confirm customers appear as varied R15 golfers, walk without sliding, hold a club, and perform a swing or putting motion.
6. Confirm range shots fly outward and putting balls roll across the green before being cleaned up.
7. Confirm customers still queue, pay, route correctly, and clean up when the owner leaves.
8. Confirm customers appear at the central entrance plaza, follow the waiting lane, enter each range station from the rear aisle, and never cut through a queue rail or station divider.
9. With four bays and a busy Putting Green, confirm queued range customers continue filling every available bay instead of being blocked by the putting customer.
10. Confirm range customers stay in the six-position center queue while putting customers use the separate right-side waiting lane.
11. Confirm finished golfers put away their clubs and leave on the side paths without crossing incoming customers.

### Pro Shop

1. Purchase the second driving-range bay and confirm the gold Pro Shop pad appears on the front-left development lawn.
2. Attempt the purchase with less than $1,200 and confirm it is rejected without spending cash.
3. Purchase the Pro Shop for $1,200 and confirm its storefront, sign, counter, and merchandise displays appear.
4. Confirm the shop adds $30 after each 12-second revenue interval and also increases lifetime revenue.
5. Rejoin with Studio persistence enabled and confirm the Pro Shop returns without another purchase pad and resumes generating revenue.
6. Load an existing schema-3 save and confirm it migrates with the Pro Shop unowned while retaining existing progress.

## Architecture and security

`Main` initializes services and owns player lifecycle. `PlayerDataService` validates versioned records, retries cloud operations, serializes saves, autosaves, and protects failed loads from destructive fallback saves. `CashService` is the sole currency writer. `PlotService` generates and assigns plots. `BusinessService` validates purchases and restores configured buildings. `CustomerService` manages cancellable customer lifecycles, queues, movement, and visit payments.

The server creates each purchase prompt and receives the triggering player's identity from Roblox. It looks up the trusted price, verifies plot and building ownership, and spends authoritative cash. There is no client-to-server economy remote; the only remote carries server-to-client feedback.

## Known limitations

- Four placeholder plots are generated; a fifth simultaneous player gets no plot.
- Geometry and UI are deliberately basic.
- Customers use deterministic movement across the generated flat plots rather than general-purpose pathfinding.
- Roblox Studio execution cannot be automated from this repository, so use the checklist above.
- Playable golf, course design, prestige, monetization, and other future systems are out of scope.

## Recommended Milestone 6

Add playable putting so the owner can personally use the facility they built, beginning the `Build it. Manage it. Play it.` gameplay loop.
