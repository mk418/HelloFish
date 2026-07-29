# HelloFish — Design Document

A one-button fishing helper for World of Warcraft Classic Era.

## Design goals

1. **One fishing-mode toggle.** Right-click equips the best pole or restores the
   weapons it displaced; the primary icon shows pole, lure or cast state.
2. **Every consumable needs a click.** The addon never spends a lure because an
   event fired or a timer expired.
3. **Put combat gear back safely.** Equipping a two-handed pole displaces both
   weapon slots, so the pre-fishing loadout is a first-class piece of state.
4. **No libraries.** The addon uses the Era client API directly and keeps its
   secure surface to one button.

## State machine

At login and after bag, equipment, skill, spellbook or enchant changes,
`Fishing:State()` resolves the current state:

```text
Fishing unknown ───────────────> disabled
No pole equipped + pole owned ─> right-click equips pole
Pole equipped + no lure + lure > left-click applies lure
Pole equipped ─────────────────> left/middle-click casts
```

The button is a `SecureActionButtonTemplate`. Pole equip is a native secure item
action; lure is an item-ID macro; cast uses the localized name returned for
Fishing spell 7620. The known-rank check covers Apprentice through Artisan
because the Apprentice spell is no longer necessarily known at higher ranks.
Every macro carries a `[nocombat]` condition. Lua updates secure attributes only
out of combat and repeats any deferred refresh on `PLAYER_REGEN_ENABLED`.

While a pole is equipped, a dedicated invisible secure button is temporarily
bound to physical `BUTTON3` with `SetOverrideBindingClick`. This provides the
global middle-click cast without a full-screen mouse frame. Removing the pole
clears only the binding owned by HelloFish.

## Item selection

Poles and lures are fixed, descending-priority standard Era catalogs. Item IDs
make bag scans locale-independent; `IsUsableItem` removes anything the current
character cannot use. The bank is intentionally excluded.

Pole priority is Arcanite, Nat Pagle's Extreme Angler, Big Iron, Darkwood,
Strong, Blump Family, then the basic Fishing Pole. Lures sort by fishing bonus,
with Aquadynamic Fish Attractor first and Shiny Bauble last. Equal-bonus Flesh
Eating Worms precede Bright Baubles.

`GetWeaponEnchantInfo` is the source of truth for whether the main hand already
has a lure and for its remaining time. No lure is selected while any temporary
main-hand enchant is active.

## Weapon restoration

Immediately before the secure equip action, the addon snapshots slots 16 and 17
into per-character saved variables. A snapshot stores each item ID and full
hyperlink, or `false` for an empty slot. It is never overwritten while active,
so repeated clicks and reloads cannot replace the combat loadout with the pole.

Right-click starts a bounded restoration job. It finds a full hyperlink match
before falling back to the same item ID, moves one item per pass, and recomputes
after inventory locks settle. Empty saved slots are restored by moving their
current item to a free bag slot. A completed restore clears the snapshot;
missing items, a busy cursor or full bags preserve it for another attempt.

## Saved variables and UI

`HelloFishDB` owns account-wide visibility, lock, scale and screen position.
`HelloFishCharDB` owns only the active weapon snapshot. The button defaults just
left of HelloWarrior's default cluster and supports Shift-drag while unlocked.
The options canvas exposes visibility, locking, scale and position reset.

## File structure

```text
Core.lua      event dispatch, chat output and slash commands
Config.lua    saved-variable defaults and options canvas
Fishing.lua   catalogs, state selection and weapon restoration
Button.lua    secure action button, presentation and movement
Tests.lua     offline engine harness; not loaded by the client
```

## Out of scope

Catch/session tracking, bobber clicking, auto-loot, sound alerts, minimap
launchers, bank scanning, expansion equipment and seasonal-only items.
