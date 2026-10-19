local function expect(actual, expected, message)
    assert(actual == expected, message .. ": expected " .. tostring(expected)
        .. ", got " .. tostring(actual))
end

GameKey = { CONTROL = 82, SHIFT = 81 }
local stored = {}
PersistentDB = {}
for _, kind in ipairs({ "Bool", "Int", "String", "StructuredData" }) do
    PersistentDB["Get" .. kind] = function(_, key) return stored[key] end
    PersistentDB["Set" .. kind] = function(_, key, value) stored[key] = value; return true end
end
local event = { Subscribe = function() end, Unsubscribe = function() end }
Event = { SettingsLayerReady = event, ContentLayerReady = event, Draw = event }
id = { Font = { MUSEO_SANS_19PT_REGULAR = 19 } }
ui = { AlignMode = { CENTRE = 1 }, TextDataConfig = { new = function() return {} end } }
local controls = {}
local prettyui = { SimpleView = { new = function()
    local view = { Destroy = function() end }
    function view:AddCheckboxButton(entries, options)
        controls.checkbox = { entries = entries, options = options }
    end
    for _, kind in ipairs({ "Text", "ColourPicker", "Slider", "ComboBox", "KeybindField" }) do
        view["Add" .. kind] = function(_, options) return { options = options } end
    end
    return view
end } }
local submitted, syncs, ready = {}, 0, true
local renderer = { Sync = function(settings)
    submitted = settings
    syncs = syncs + 1
    return ready
end }
local UI = require("src/ui")
UI:init({}, prettyui, renderer)
UI:mountSettings({})
expect(UI.gridEnabled, false, "grid defaults off")
expect(UI.gridColour, 0xFFFFFF59, "grid defaults to translucent white")
expect(UI.gridThickness, 1, "grid defaults to thin outlines")
expect(UI.gridColourPicker.options.alphaSlider, true, "grid picker offers opacity")
expect(UI.gridThicknessSlider.options.min, 0.5, "grid thickness minimum")
expect(UI.gridThicknessSlider.options.max, 10, "grid thickness maximum")
expect(UI.gridThicknessSlider.options.step, 0.5, "grid thickness increment")
local markerColour, markerThickness = UI.currentStyle.outlineColour, UI.outlineThickness
controls.checkbox.options.onChange(nil, nil, "show_grid", true)
UI.gridColourPicker.options.onChange(nil, 0x12345678)
UI.gridThicknessSlider.options.onChange(nil, 2.5)
expect(UI.currentStyle.outlineColour, markerColour, "grid picker preserves marker colour")
expect(UI.outlineThickness, markerThickness, "grid slider preserves marker thickness")
UI:init({}, prettyui, renderer)
UI:mountSettings({})
expect(UI.gridEnabled, true, "grid enabled state survives reload")
expect(UI.gridColour, 0x12345678, "grid colour and alpha survive reload")
expect(UI.gridThickness, 2.5, "grid thickness survives reload")
expect(UI.gridColourPicker.options.value, 0x12345678, "picker restores saved colour")
expect(UI.gridThicknessSlider.options.value, 2.5, "slider restores saved thickness")

local function coord(x)
    return { x = x, z = 20, level = 0, ToCoordFine = function()
        return { level = 0, position = { x = x * 512, y = 0, z = 20 * 512 } }
    end }
end
local markerCoord, emptyCoord = coord(10), coord(11)
local markers = { [markerCoord] = { text = "Keep label", outlineColour = 0xABCDEF80 } }
local grid = { coord(10), emptyCoord }
UI.globalStyle = { fill = true, outlineCornersOnly = true }
UI.ignoreDepth = true
local function sync(hover, coords)
    return UI:syncMarkers(markers, hover, 30 * 512, coords or grid)
end
local function at(x)
    for _, entry in ipairs(submitted) do
        if entry.coordGrid.x == x then return entry end
    end
end
assert(sync())
expect(#submitted, 2, "marked grid coordinate has only one submission")
expect(at(10).isGrid, false, "saved marker overrides grid")
expect(at(10).outlineColour, 0xABCDEF80, "saved marker retains colour")
expect(at(10).outlineThickness, markerThickness, "saved marker retains thickness")
expect(at(10).fill, true, "saved marker follows marker fill setting")
expect(at(10).outlineCornersOnly, true, "saved marker follows marker corners setting")
expect(at(11).isGrid, true, "unmarked coordinate is a display grid tile")
expect(at(11).outlineColour, 0x12345678, "grid has independent colour and opacity")
expect(at(11).outlineThickness, 2.5, "grid has independent thickness")
expect(at(11).fill, false, "grid never inherits marker fill")
expect(at(11).outlineCornersOnly, false, "grid always has full outlines")
expect(at(11).ignoreDepth, true, "grid follows scenery setting")
expect(at(11).drawDistance, 30 * 512, "grid uses existing draw distance")
expect(#UI.markerLabels, 1, "grid creates no labels")
expect(UI.markerLabels[1].text, "Keep label", "marker label stays intact")
local before = syncs
sync()
expect(syncs, before, "unchanged grid avoids reconciliation")
UI.gridColourPicker.options.onChange(nil, 0x00000059)
sync()
expect(at(11).outlineColour, 0x00000059, "colour change invalidates render cache")
UI.gridThicknessSlider.options.onChange(nil, 4)
sync()
expect(at(11).outlineThickness, 4, "thickness change invalidates render cache")
UI.ignoreDepth = false
sync()
expect(at(11).ignoreDepth, false, "scenery change reaches grid")
sync(emptyCoord)
expect(at(11).isGrid, false, "hover replaces unmarked grid style")
expect(at(11).outlineColour, 0xFFFFFF90, "grid hover uses empty-tile preview")
expect(at(11).fill, true, "empty-tile preview keeps its fill")
expect(at(11).outlineThickness, markerThickness, "hover uses marker thickness")
sync(markerCoord)
assert(at(10).outlineColour ~= 0xABCDEF80, "marked hover still lightens the marker")
expect(at(10).fill, true, "marked hover preserves marker fill")
expect(markers[emptyCoord], nil, "composition never writes grid coordinates into markers")

ready = false
assert(not sync(nil, { coord(10), coord(12) }), "renderer failure is reported")
before = syncs
ready = true
assert(UI:syncMarkers(markers, nil, 30 * 512, UI.renderGrid), "unchanged grid retries failure")
expect(syncs, before + 1, "failure retries reconciliation")
controls.checkbox.options.onChange(nil, nil, "show_grid", false)
sync()
expect(#submitted, 1, "disable immediately removes grid submissions")
expect(at(10).outlineColour, 0xABCDEF80, "disable preserves saved marker")
UI:init({}, prettyui, renderer)
expect(UI.gridEnabled, false, "disabled state persists")
expect(UI.gridColour, 0x00000059, "disabled state preserves chosen grid colour")
expect(UI.gridThickness, 4, "disabled state preserves chosen thickness")
UI:destroySettings()
expect(UI.gridColourPicker, nil, "settings cleanup releases grid picker")
expect(UI.gridThicknessSlider, nil, "settings cleanup releases grid slider")
print("test_grid_ui: ok")
