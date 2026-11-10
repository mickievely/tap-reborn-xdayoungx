_G.__XDAYOUNGX_TAP_REBORN = nil

local url = "https://raw.githubusercontent.com/mickievely/tap-reborn-xdayoungx/main/main.lua?t=" .. tostring(tick())

local fn, err = loadstring(game:HttpGet(url, true), "xdayoungx/main.lua")
if not fn then
    error(err or "load failed")
end
fn()
