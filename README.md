# HelloFish

A lean one-button fishing helper for WoW Classic Era. It equips your best pole,
applies your strongest available lure, casts Fishing from a global middle-click,
and remembers the weapons it displaced.

> **Heads up** — this is a personal work in progress. I build and evolve it as I
> play using it, so features land when I need them and design choices reflect my
> play style.

## How it works

Right-click enters or leaves fishing mode:

1. Without a pole equipped, it remembers both weapon slots and equips the
   strongest standard Era fishing pole in your bags.
2. With a pole equipped, it restores the remembered main-hand and off-hand.

While fishing, left-click applies the strongest usable lure when needed and
otherwise casts Fishing. Middle-click anywhere also casts Fishing while the
pole is equipped; the global mouse binding is removed again when the pole is
restored.

Applying a lure is always a separate explicit click. When a lure is active, the
button shows its approximate remaining time. Restoration matches full item links
so differently enchanted copies are not confused.

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
