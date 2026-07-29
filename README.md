# HelloFish

A lean one-button fishing helper for WoW Classic Era. It equips your best pole,
applies your strongest available lure, casts Fishing, and remembers the weapons
it displaced.

> **Heads up** — this is a personal work in progress. I build and evolve it as I
> play using it, so features land when I need them and design choices reflect my
> play style.

## How it works

The button always shows what the next left-click will do:

1. Equip the strongest standard Era fishing pole in your bags.
2. Apply the strongest usable lure when the pole has no temporary enchant.
3. Cast Fishing.

Applying a lure is always a separate explicit click. When a lure is active, the
button shows its approximate remaining time. Right-click restores the main-hand
and off-hand items that were equipped before the pole, matching their full item
links so differently enchanted copies are not confused.

Shift-drag the button while it is unlocked to move it. Both actions can also be
bound under **Esc > Options > Keybindings > HelloFish**.

## Commands

| Command | Effect |
| --- | --- |
| `/hf` | Show or hide the button |
| `/hf show` · `/hf hide` | Set button visibility |
| `/hf lock` · `/hf unlock` | Lock or unlock Shift-drag movement |
| `/hf config` | Open the addon options |
| `/hf resetpos` | Return the button to its default position |
| `/hf reset` | Clear all HelloFish settings and reload the UI |

## Caveats

- Only supports WoW Classic Era and the standard Era pole/lure catalog.
- Equipment and secure-button changes cannot happen during combat.
- Poles and lures must be in carried bags; the bank is not searched.
- Weapon restoration needs enough bag space to put away the fishing pole.
- Catch tracking, bobber interaction, auto-loot and sound alerts are deliberately
  outside the first release.

## Testing

The item-selection and restoration engine runs outside the game against a
stubbed inventory:

```sh
lua Tests.lua .
luacheck .
```

## License

Released under the [MIT License](LICENSE).
