# Golf Empire Tycoon

Golf Empire Tycoon is a Roblox tycoon/management game where players build increasingly prestigious golf properties and will eventually be able to play golf on player-designed courses.

## Product Rule

This is NOT intended to become a generic button tycoon. The long-term differentiator is: **Build it. Manage it. Play it.**

## Architecture

- Luau and a Rojo-compatible structure
- Modular services and configuration-driven systems where appropriate
- Client handles input and presentation
- Server handles economy, ownership, and progression

## Security

- Never trust client currency values or prices.
- Validate purchases and remotes server-side.
- Players cannot modify another player's property.
- Client scripts never modify authoritative player data.

## Development

- Build incrementally and finish one milestone before starting another.
- Prefer focused modules; avoid giant scripts and unnecessary dependencies.
- Do not rewrite unrelated working systems.
- Avoid premature optimization and maintain existing compatibility.

## Future Direction

Future systems may include NPC golfers, facility management, reputation, course building, playable golf, equipment, player-created courses, multiplayer visits, tournaments, country clubs, resorts, and multiple properties. Do not implement them until explicitly requested.
