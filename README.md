# xdayoungx — Tap Simulator REBORN macro

Auto tap, in-game auto clicker, anti-AFK. Tap Reborn only.

## Load (always latest, cache-busted)

```lua
_G.__XDAYOUNGX_TAP_REBORN = nil
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/mickievely/tap-reborn-xdayoungx/main/main.lua?t=" .. tick(),
    true
))()
```

One-liner:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/mickievely/tap-reborn-xdayoungx/main/loader.lua?t="..tick(),true))()
```

UI toggle: **RightControl**
