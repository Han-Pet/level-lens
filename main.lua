-- main.lua is the entrypoint that RuneScape runs when this plugin is enabled.
-- RuneScape plugins use Lua 5.4.
-- Output from print() appears in the RuneScape developer console.
-- Reloading the plugin runs main.lua again.

print("[Level Lens] Plugin loaded successfully!")

local indicatorStyle =
    PersistentDB:GetString("skillsProgressIndicatorStyle")
if indicatorStyle ~= "bottom"
    and indicatorStyle ~= "left"
    and indicatorStyle ~= "background" then
    local savedUseLeftProgressBar =
        PersistentDB:GetBool("skillsProgressUseLeftBar")
    if savedUseLeftProgressBar == true then
        indicatorStyle = "left"
    elseif savedUseLeftProgressBar == false then
        indicatorStyle = "bottom"
    else
        indicatorStyle = "background"
    end
    PersistentDB:SetString(
        "skillsProgressIndicatorStyle",
        indicatorStyle
    )
end
local barThickness =
    PersistentDB:GetInt("skillsProgressBarThickness") or 3
barThickness = math.max(1, math.min(math.floor(barThickness + 0.5), 6))

-- Rarity colours are on unless the player has explicitly saved them as off.
local savedRarity =
    PersistentDB:GetBool("skillsProgressUseRarityColors")
local useRarityColors = savedRarity ~= false
local settingsView
local thicknessMinusButton
local thicknessValueText
local thicknessPlusButton

local skillTypes = {
    SkillType.ATTACK,
    SkillType.DEFENCE,
    SkillType.STRENGTH,
    SkillType.HITPOINTS,
    SkillType.RANGED,
    SkillType.PRAYER,
    SkillType.MAGIC,
    SkillType.COOKING,
    SkillType.WOODCUTTING,
    SkillType.FLETCHING,
    SkillType.FISHING,
    SkillType.FIREMAKING,
    SkillType.CRAFTING,
    SkillType.SMITHING,
    SkillType.MINING,
    SkillType.HERBLORE,
    SkillType.AGILITY,
    SkillType.THIEVING,
    SkillType.SLAYER,
    SkillType.FARMING,
    SkillType.RUNECRAFTING,
    SkillType.HUNTER,
    SkillType.CONSTRUCTION,
    SkillType.SUMMONING,
    SkillType.DUNGEONEERING,
    SkillType.DIVINATION,
    SkillType.INVENTION,
    SkillType.ARCHAEOLOGY,
    SkillType.NECROMANCY
}

-- Different RuneScape skills have real maximum levels of 99, 110, or 120.
-- XP can keep increasing after a real level cap, but there is no next gameplay level.
-- These are real gameplay level caps, not virtual levels.
local maxLevels = {
    [SkillType.ATTACK] = 120,
    [SkillType.DEFENCE] = 99,
    [SkillType.STRENGTH] = 120,
    [SkillType.HITPOINTS] = 99,
    [SkillType.RANGED] = 120,
    [SkillType.PRAYER] = 99,
    [SkillType.MAGIC] = 120,
    [SkillType.COOKING] = 99,
    [SkillType.WOODCUTTING] = 110,
    [SkillType.FLETCHING] = 110,
    [SkillType.FISHING] = 99,
    [SkillType.FIREMAKING] = 110,
    [SkillType.CRAFTING] = 110,
    [SkillType.SMITHING] = 110,
    [SkillType.MINING] = 110,
    [SkillType.HERBLORE] = 120,
    [SkillType.AGILITY] = 99,
    [SkillType.THIEVING] = 120,
    [SkillType.SLAYER] = 120,
    [SkillType.FARMING] = 120,
    [SkillType.RUNECRAFTING] = 110,
    [SkillType.HUNTER] = 110,
    [SkillType.CONSTRUCTION] = 120,
    [SkillType.SUMMONING] = 99,
    [SkillType.DUNGEONEERING] = 120,
    [SkillType.DIVINATION] = 99,
    [SkillType.INVENTION] = 120,
    [SkillType.ARCHAEOLOGY] = 120,
    [SkillType.NECROMANCY] = 120
}

-- This is RuneScape's standard XP curve, which most skills use.
-- Level 1 starts at 0 XP, and level 2 starts at 83 XP.
-- We calculate these XP thresholds locally; this does not call a server or website.
local function getXPForLevel(level)
    local total = 0

    for n = 1, level - 1 do
        total = total + math.floor(n + 300 * 2 ^ (n / 7))
    end

    return math.floor(total / 4)
end

-- Invention is RuneScape's elite skill and uses a different XP curve.
local inventionXPForLevel = {
    0, 830, 1861, 2902, 3980, 5126, 6380, 7787, 9400, 11275,
    13605, 16372, 19656, 23546, 28134, 33520, 39809, 47109, 55535, 65209,
    77190, 90811, 106221, 123573, 143025, 164742, 188893, 215651, 245196, 277713,
    316311, 358547, 404634, 454796, 509259, 568254, 632019, 700797, 774834, 854383,
    946227, 1044569, 1149696, 1261903, 1381488, 1508756, 1644015, 1787581, 1939773, 2100917,
    2283490, 2476369, 2679917, 2894505, 3120508, 3358307, 3608290, 3870846, 4146374, 4435275,
    4758122, 5096111, 5449685, 5819299, 6205407, 6608473, 7028964, 7467354, 7924122, 8399751,
    8925664, 9472665, 10041285, 10632061, 11245538, 11882262, 12542789, 13227679, 13937496, 14672812,
    15478994, 16313404, 17176661, 18069395, 18992239, 19945833, 20930821, 21947856, 22997593, 24080695,
    25259906, 26475754, 27728955, 29020233, 30350318, 31719944, 33129852, 34580790, 36073511, 37608773,
    39270442, 40978509, 42733789, 44537107, 46389292, 48291180, 50243611, 52247435, 54303504, 56412678,
    58575824, 60793812, 63067521, 65397835, 67785643, 70231841, 72737330, 75303019, 77929820, 80618654
}

local function getXPForSkillLevel(skill, level)
    if skill == SkillType.INVENTION then
        return inventionXPForLevel[level]
    end

    return getXPForLevel(level)
end

-- A threshold is the total XP where a level starts, not the player's current XP.
-- GetLevelUncapped uses the XP-based level, so temporary boosts or drains do not affect progress.
local function getSkillProgress(skill)
    local currentXP = Player.GetXPUncapped(skill)
    local currentLevel = Player.GetLevelUncapped(skill)
    local progress = {
        skill = skill,
        name = SkillType.FromID(skill),
        level = currentLevel,
        maxLevel = maxLevels[skill],
        xp = currentXP,
        isMaxed = currentLevel >= maxLevels[skill]
    }

    -- Once the real cap is reached, do not invent a next level or remaining XP target.
    if progress.isMaxed then
        progress.percent = 100
        return progress
    end

    progress.currentLevelXP = getXPForSkillLevel(skill, currentLevel)
    progress.nextLevelXP = getXPForSkillLevel(skill, currentLevel + 1)
    if type(progress.currentLevelXP) ~= "number" or type(progress.nextLevelXP) ~= "number" then
        return progress
    end

    progress.gainedInLevel = currentXP - progress.currentLevelXP
    progress.remaining = progress.nextLevelXP - currentXP
    progress.percent = progress.gainedInLevel / (progress.nextLevelXP - progress.currentLevelXP) * 100

    -- Only a genuinely maxed skill displays 100.00%.
    progress.percent = math.min(progress.percent, 99.99)

    return progress
end

-- ============================================================================
-- UI - Native Skills Window Progress Indicators
-- ============================================================================
-- STATS_CHILD uses parallel runtime layers for tile backgrounds, icons, stats,
-- vanity icons, and buttons. categoryID + dynamicID links the same current tile
-- across those layers, but those runtime IDs are not permanent skill identities.
-- The normal ICON sprite name identifies the skill even when the grid reflows.

local STATS_CHILD_INTERFACE = 1466
local STATS_CHILD_CANVAS_STATIC = 0
local STATS_CHILD_LIST_STATIC = 1
local STATS_CHILD_ICON_STATIC = 3
local STATS_CHILD_BUTTON_STATIC = 7
local SKILL_BORDER_CATEGORY = 0
local SKILL_BORDER_DYNAMIC_BASE = 3000
local SKILL_BORDER_RGBA = 0x55B85AFF
local PROGRESS_BAR_INSET_X = 2
local PROGRESS_BAR_INSET_BOTTOM = 2
local PROGRESS_BAR_INSET_LEFT = 2
local PROGRESS_BAR_INSET_VERTICAL = 2
local PROGRESS_TRACK_RGBA = 0x111820CC
local PROGRESS_FILL_LOW_RGBA = 0xD9E0E8FF
local PROGRESS_FILL_GREEN_RGBA = 0x55B85AFF
local PROGRESS_FILL_BLUE_RGBA = 0x4FA3FFFF
local PROGRESS_FILL_PURPLE_RGBA = 0xA970FFFF
local PROGRESS_FILL_GOLD_RGBA = 0xF2C94CFF
local BACKGROUND_INSET = 1
local BACKGROUND_PROGRESS_ALPHA = 0.35
local RESIZE_DRAW_SUBSCRIPTION = "skillsProgressResizeThrottle"
local RESIZE_REFRESH_INTERVAL = 0.100
local RESIZE_SETTLE_TIME = 0.500
local ATTACH_RETRY_TICKS = 10

local spriteToSkill = {
    STATICONS_0 = SkillType.ATTACK,
    STATICONS_6 = SkillType.HITPOINTS,
    STATICONS_12 = SkillType.MINING,
    STATICONS_1 = SkillType.STRENGTH,
    STATICONS_7 = SkillType.AGILITY,
    STATICONS_13 = SkillType.SMITHING,
    STATICONS_2 = SkillType.DEFENCE,
    STATICONS_8 = SkillType.HERBLORE,
    STATICONS_14 = SkillType.FISHING,
    STATICONS_3 = SkillType.RANGED,
    STATICONS_9 = SkillType.THIEVING,
    STATICONS_15 = SkillType.COOKING,
    STATICONS_4 = SkillType.PRAYER,
    STATICONS_10 = SkillType.CRAFTING,
    STATICONS_16 = SkillType.FIREMAKING,
    STATICONS_5 = SkillType.MAGIC,
    STATICONS_11 = SkillType.FLETCHING,
    STATICONS_17 = SkillType.WOODCUTTING,
    STATICONS2_0 = SkillType.RUNECRAFTING,
    STATICONS2_1 = SkillType.SLAYER,
    STATICONS2_2 = SkillType.FARMING,
    STATICONS2_6 = SkillType.CONSTRUCTION,
    STATICONS2_5 = SkillType.HUNTER,
    STATICONS2_7 = SkillType.SUMMONING,
    STATICONS2_13 = SkillType.DUNGEONEERING,
    STATICONS2_14 = SkillType.DIVINATION,
    SKILL_ICON_INVENTION_25PX_0 = SkillType.INVENTION,
    SKILL_ICON_INVENTION_25PX_1 = SkillType.INVENTION,
    SKILL_ICON_ARCHAEOLOGY_25PX_0 = SkillType.ARCHAEOLOGY,
    SKILL_ICON_NECROMANCY_25PX_0 = SkillType.NECROMANCY
}

local skillBorders = {}
local currentCanvas
local currentList
local currentIconLayer
local currentButtonLayer
local refreshSkillBorders
local skillsUIAttached = false
local resizeWatchActive = false
local resizePollElapsed = 0
local resizeStableElapsed = 0
local lastListWidth
local lastListHeight
local attachRetryTicks = 0

local function getComponentProperty(component, propertyName)
    local worked, value = pcall(function()
        return component[propertyName]
    end)
    return worked and value or nil
end

local function getStaticComponent(staticID)
    local worked, component = pcall(function()
        return ui.Interfaces:GetComponent(STATS_CHILD_INTERFACE * 65536 + staticID)
    end)
    return worked and component or nil
end

local function getCanvas()
    return getStaticComponent(STATS_CHILD_CANVAS_STATIC)
end

local function getList()
    return getStaticComponent(STATS_CHILD_LIST_STATIC)
end

local function getIconLayer()
    return getStaticComponent(STATS_CHILD_ICON_STATIC)
end

local function getButtonLayer()
    return getStaticComponent(STATS_CHILD_BUTTON_STATIC)
end

local function getButton(categoryID, dynamicID)
    local worked, component = pcall(function()
        return ui.Interfaces:GetComponent(
            STATS_CHILD_INTERFACE,
            STATS_CHILD_BUTTON_STATIC,
            categoryID,
            dynamicID
        )
    end)
    return worked and component or nil
end

local function destroyRectangle(rectangle)
    if rectangle then
        pcall(function()
            rectangle:Destroy()
        end)
    end
end

local function destroyBorder(border)
    destroyRectangle(border.fill)
    destroyRectangle(border.track)
end

local function clearSkillBorders()
    for _, border in pairs(skillBorders) do
        destroyBorder(border)
    end

    skillBorders = {}
    currentCanvas = nil
    currentList = nil
    currentIconLayer = nil
    currentButtonLayer = nil
    resizePollElapsed = 0
    resizeWatchActive = false
    resizeStableElapsed = 0
    lastListWidth = nil
    lastListHeight = nil
    skillsUIAttached = false
end

local function hasAllSkillBorders()
    for _, skill in ipairs(skillTypes) do
        if not skillBorders[skill] then
            return false, skill
        end
    end

    return true, nil
end

local function createRectangle(parent, dynamicID, skillName, role, counts)
    -- Category 0 has the large dynamic-ID range (0..4096). RuneScape's native
    -- skill components occupy low IDs in this parent, so this plugin deliberately
    -- uses two deterministic IDs per skill, starting at 3000.
    local rectangle
    local worked, errorMessage = pcall(function()
        rectangle = ui.Rectangle.new(parent, SKILL_BORDER_CATEGORY, dynamicID)
        if not rectangle then
            error("Rectangle.new returned nil")
        end

        rectangle.rgba = SKILL_BORDER_RGBA
        rectangle.fill = true
        rectangle.clickthrough = true
        rectangle.hidden = false
    end)

    if not worked then
        destroyRectangle(rectangle)
        counts.failed = counts.failed + 1
        if counts.failed == 1 then
            print(string.format(
                "[Level Lens] Rectangle creation failed | category=%d | dynamic=%d | skill=%s | role=%s | error=%s",
                SKILL_BORDER_CATEGORY,
                dynamicID,
                skillName,
                role,
                tostring(errorMessage)
            ))
        end
        return nil
    end

    counts.created = counts.created + 1
    return rectangle
end

local function createBorder(iconLayer, icon, button, categoryID, dynamicID, borderSlot, skill, counts)
    local baseDynamicID = SKILL_BORDER_DYNAMIC_BASE + borderSlot * 2
    local skillName = tostring(SkillType.FromID(skill))
    local border = {
        icon = icon,
        button = button,
        categoryID = categoryID,
        dynamicID = dynamicID,
        borderSlot = borderSlot,
        skill = skill,
        fill = createRectangle(iconLayer, baseDynamicID, skillName, "fill", counts),
        track = createRectangle(iconLayer, baseDynamicID + 1, skillName, "track", counts)
    }

    if not border.fill or not border.track then
        destroyBorder(border)
        return nil
    end

    return border
end


local function setRectangleGeometry(rectangle, x, y, width, height)
    rectangle:SetPos(x, y)
    rectangle:SetSize(width, height)
    rectangle.hidden = false
end

local function hideBorder(border)
    border.fill.hidden = true
    border.track.hidden = true
end

local function getButtonGeometryInIconSpace(button, iconLayer)
    local worked, buttonGlobalX, buttonGlobalY, iconGlobalX, iconGlobalY, width, height = pcall(function()
        local buttonGlobal = button.xyGlobal
        local iconGlobal = iconLayer.xyGlobal
        if not buttonGlobal or not iconGlobal then
            return nil
        end

        return buttonGlobal.x,
            buttonGlobal.y,
            iconGlobal.x,
            iconGlobal.y,
            button.width,
            button.height
    end)

    if not worked
        or type(buttonGlobalX) ~= "number"
        or type(buttonGlobalY) ~= "number"
        or type(iconGlobalX) ~= "number"
        or type(iconGlobalY) ~= "number"
        or type(width) ~= "number"
        or type(height) ~= "number" then
        return nil
    end

    return buttonGlobalX - iconGlobalX,
        buttonGlobalY - iconGlobalY,
        math.max(0, width),
        math.max(0, height)
end

-- The fill changes color as progress moves through five easy-to-read bands.
-- These work like rarity colors: pale at the start, then green, blue, purple,
-- and finally gold for the highest progress range.
local function getProgressFillColor(percent)
    if percent < 20 then
        return PROGRESS_FILL_LOW_RGBA
    elseif percent < 40 then
        return PROGRESS_FILL_GREEN_RGBA
    elseif percent < 60 then
        return PROGRESS_FILL_BLUE_RGBA
    elseif percent < 80 then
        return PROGRESS_FILL_PURPLE_RGBA
    end

    return PROGRESS_FILL_GOLD_RGBA
end

local function renderProgressBar(border, trackX, trackY, trackWidth, trackHeight,
        fillX, fillY, fillWidth, fillHeight, fillColor)
    border.track.rgba = PROGRESS_TRACK_RGBA
    border.track.alpha = 1.0
    setRectangleGeometry(
        border.track,
        trackX,
        trackY,
        trackWidth,
        trackHeight
    )

    border.fill.rgba = fillColor
    border.fill.alpha = 1.0
    border.fill:SetPos(fillX, fillY)
    border.fill:SetSize(fillWidth, fillHeight)
    border.fill.hidden = fillWidth <= 0 or fillHeight <= 0

    border.fill:MoveToBack()
    border.track:MoveToBack()
end

local function renderLeftProgress(border, x, y, width, height, fraction, fillColor)
    local insetLeft = math.min(PROGRESS_BAR_INSET_LEFT, math.max(width - 1, 0))
    local insetVertical = math.min(
        PROGRESS_BAR_INSET_VERTICAL,
        math.max(math.floor((height - 1) / 2), 0)
    )
    local trackX = x + insetLeft
    local trackY = y + insetVertical
    local trackWidth = math.max(math.min(barThickness, width - insetLeft), 1)
    local trackHeight = math.max(height - insetVertical * 2, 1)
    local fillHeight = math.floor(trackHeight * fraction + 0.5)
    fillHeight = math.max(0, math.min(fillHeight, trackHeight))

    renderProgressBar(
        border,
        trackX,
        trackY,
        trackWidth,
        trackHeight,
        trackX,
        trackY + trackHeight - fillHeight,
        trackWidth,
        fillHeight,
        fillColor
    )
end

local function renderBottomProgress(border, x, y, width, height, fraction, fillColor)
    local insetX = math.min(
        PROGRESS_BAR_INSET_X,
        math.max(math.floor((width - 1) / 2), 0)
    )
    local trackHeight = math.max(math.min(barThickness, height), 1)
    local insetBottom = math.min(
        PROGRESS_BAR_INSET_BOTTOM,
        math.max(height - trackHeight, 0)
    )
    local trackX = x + insetX
    local trackY = y + height - insetBottom - trackHeight
    local trackWidth = math.max(width - insetX * 2, 1)
    local fillWidth = math.floor(trackWidth * fraction + 0.5)
    fillWidth = math.max(0, math.min(fillWidth, trackWidth))

    renderProgressBar(
        border,
        trackX,
        trackY,
        trackWidth,
        trackHeight,
        trackX,
        trackY,
        fillWidth,
        trackHeight,
        fillColor
    )
end

local function renderBackgroundProgress(border, x, y, width, height, fraction, fillColor)
    local backgroundX = x + BACKGROUND_INSET
    local backgroundY = y + BACKGROUND_INSET
    local backgroundWidth = math.max(width - BACKGROUND_INSET * 2, 1)
    local backgroundHeight = math.max(height - BACKGROUND_INSET * 2, 1)
    local fillWidth = math.floor(backgroundWidth * fraction + 0.5)
    fillWidth = math.max(0, math.min(fillWidth, backgroundWidth))

    border.fill.rgba = fillColor
    border.fill.alpha = BACKGROUND_PROGRESS_ALPHA
    border.fill:SetPos(backgroundX, backgroundY)
    border.fill:SetSize(fillWidth, backgroundHeight)
    border.fill.hidden = fillWidth <= 0
    border.track.hidden = true

    border.fill:MoveToBack()
end

-- Each skill owns a fill and track rectangle. Bottom and Left show
-- both; Background uses only the translucent fill.
local function renderBorder(border, progress)
    if not progress then
        hideBorder(border)
        return true
    end

    local x, y, width, height = getButtonGeometryInIconSpace(border.button, currentIconLayer)
    if x == nil then
        return nil
    end
    if width <= 0 or height <= 0 then
        hideBorder(border)
        return true
    end

    local percent = progress.isMaxed and 100
        or math.max(0, math.min(progress.percent or 0, 100))
    local fraction = math.max(0, math.min(percent / 100, 1))
    local fillColor = useRarityColors
        and getProgressFillColor(percent)
        or PROGRESS_FILL_GREEN_RGBA

    if indicatorStyle == "background" then
        renderBackgroundProgress(border, x, y, width, height, fraction, fillColor)
    elseif indicatorStyle == "left" then
        renderLeftProgress(border, x, y, width, height, fraction, fillColor)
    else
        renderBottomProgress(border, x, y, width, height, fraction, fillColor)
    end

    -- Resize detection caches the whole tile bounds, not the smaller bar bounds.
    border.lastX = x
    border.lastY = y
    border.lastWidth = width
    border.lastHeight = height

    return true
end

-- Style changes redraw cached progress only; they do not read XP again.
local function refreshAllProgressIndicatorStyles()
    for _, border in pairs(skillBorders) do
        pcall(function()
            renderBorder(border, border.progress)
        end)
    end
end

local function updateThicknessControls()
    if not thicknessMinusButton or not thicknessPlusButton then
        return
    end

    local backgroundSelected = indicatorStyle == "background"
    thicknessMinusButton:SetDisabled(
        backgroundSelected or barThickness <= 1
    )
    thicknessPlusButton:SetDisabled(
        backgroundSelected or barThickness >= 6
    )
end

local function resolveSkill(icon)
    if icon.type ~= ui.ComponentType.SPRITE or type(icon.spriteID) ~= "number" then
        return nil
    end

    local worked, spriteName = pcall(function()
        return id.Sprite.FromID(icon.spriteID)
    end)
    if not worked or not spriteName then
        return nil
    end

    -- Tile positions and runtime IDs can change. The built-in normal icon sprite
    -- identifies the current tile without relying on its row, column, or position.
    -- VANITYICON is deliberately not used because it may show a replacement icon.
    return spriteToSkill[tostring(spriteName)]
end

local function collectSkillTiles(iconLayer)
    local tiles = {}
    local inspected = 0
    local recognised = 0
    local supported = 0

    local worked, errorMessage = pcall(function()
        iconLayer:IterateDynamicComponents(function(icon, _visible)
            inspected = inspected + 1
            local skill = resolveSkill(icon)
            if skill then
                local borderSlot = recognised
                recognised = recognised + 1
                supported = supported + 1

                local categoryID = icon.categoryID
                local dynamicID = icon.dynamicID
                local button = getButton(categoryID, dynamicID)
                if button then
                    tiles[#tiles + 1] = {
                        skill = skill,
                        icon = icon,
                        button = button,
                        categoryID = categoryID,
                        dynamicID = dynamicID,
                        borderSlot = borderSlot
                    }
                end
            end
            return false
        end)
    end)

    return tiles, inspected, recognised, supported, worked and nil or errorMessage
end

refreshSkillBorders = function(logAttachmentSummary)
    if not currentIconLayer then
        return false
    end

    local counts = { created = 0, failed = 0 }
    local tiles, _, _, _, collectionError = collectSkillTiles(currentIconLayer)
    if collectionError then
        counts.failed = counts.failed + 1
        print("[Level Lens] Border attachment failed: " .. tostring(collectionError))
    end
    local usedSlots = {}
    for _, border in pairs(skillBorders) do
        usedSlots[border.borderSlot] = true
    end

    local seen = {}
    for _, tile in ipairs(tiles) do
        local border = skillBorders[tile.skill]

        if not border then
            local borderSlot = tile.borderSlot
            if usedSlots[borderSlot] then
                borderSlot = 0
                while usedSlots[borderSlot] and borderSlot < 29 do
                    borderSlot = borderSlot + 1
                end
            end
            usedSlots[borderSlot] = true

            border = createBorder(
                currentIconLayer,
                tile.icon,
                tile.button,
                tile.categoryID,
                tile.dynamicID,
                borderSlot,
                tile.skill,
                counts
            )
            skillBorders[tile.skill] = border

            if border and Player.IsAvailable() then
                border.progress = getSkillProgress(tile.skill)
            end
        elseif border then
            border.icon = tile.icon
            border.button = tile.button
            border.categoryID = tile.categoryID
            border.dynamicID = tile.dynamicID
        end

        if border then
            seen[tile.skill] = true
            local callSucceeded, renderCompleted = pcall(function()
                return renderBorder(border, border.progress)
            end)
            if not callSucceeded or not renderCompleted then
                counts.failed = counts.failed + 1
                if counts.failed == 1 then
                    if not callSucceeded then
                        print("[Level Lens] Border attachment failed: " .. tostring(renderCompleted))
                    else
                        print(string.format(
                            "[Level Lens] Border attachment failed: geometry unavailable for %s",
                            tostring(SkillType.FromID(tile.skill))
                        ))
                    end
                end
            end
        end
    end

    for skill, border in pairs(skillBorders) do
        if not seen[skill] then
            destroyBorder(border)
            skillBorders[skill] = nil
        end
    end

    if logAttachmentSummary then
        if counts.failed > 0 then
            clearSkillBorders()
            return false
        end

        local allSkillsAttached, missingSkill = hasAllSkillBorders()
        if not allSkillsAttached then
            print(string.format(
                "[Level Lens] Border attachment failed: missing skill %s",
                tostring(SkillType.FromID(missingSkill))
            ))
            clearSkillBorders()
            return false
        end
    end

    return true
end

local function refreshCurrentSkillBorderGeometry()
    if not currentIconLayer then
        return nil
    end

    local tiles, _, _, _, collectionError = collectSkillTiles(currentIconLayer)
    if collectionError then
        return nil
    end

    local currentSkillTiles = {}
    for _, tile in ipairs(tiles) do
        currentSkillTiles[tile.skill] = tile
    end

    for _, skill in ipairs(skillTypes) do
        if not currentSkillTiles[skill] then
            return nil
        end
    end

    local inspectedTiles = 0
    local changedBorders = 0
    for _, skill in ipairs(skillTypes) do
        local tile = currentSkillTiles[skill]
        local border = skillBorders[tile.skill]
        if not border then
            return nil
        end

        inspectedTiles = inspectedTiles + 1
        local x, y, width, height = getButtonGeometryInIconSpace(tile.button, currentIconLayer)
        if x == nil then
            return nil
        end

        -- Always retain the current native children, even when their geometry
        -- matches the previous scan, so later XP updates do not use stale wrappers.
        border.icon = tile.icon
        border.button = tile.button
        border.categoryID = tile.categoryID
        border.dynamicID = tile.dynamicID

        local geometryChanged = x ~= border.lastX
            or y ~= border.lastY
            or width ~= border.lastWidth
            or height ~= border.lastHeight

        if geometryChanged then
            local rendered, renderCompleted = pcall(function()
                return renderBorder(border, border.progress)
            end)
            if not rendered or not renderCompleted then
                return nil
            end
            changedBorders = changedBorders + 1
        end
    end

    return inspectedTiles, changedBorders
end

local function attachToSkillsInterface(canvas, listComponent, iconLayer, buttonLayer)
    currentCanvas = canvas
    currentList = listComponent
    currentIconLayer = iconLayer
    currentButtonLayer = buttonLayer

    local refreshed, attached = pcall(function()
        return refreshSkillBorders(true)
    end)
    if not refreshed or not attached then
        if not refreshed then
            print("[Level Lens] Border attachment failed: " .. tostring(attached))
            clearSkillBorders()
        end
        return false
    end

    lastListWidth = getComponentProperty(currentList, "width")
    lastListHeight = getComponentProperty(currentList, "height")
    resizePollElapsed = 0
    resizeWatchActive = false
    resizeStableElapsed = 0
    return true
end

local function checkSkillsInterface()
    local canvas = getCanvas()
    local listComponent = getList()
    local iconLayer = getIconLayer()
    local buttonLayer = getButtonLayer()
    local interfaceAvailable = canvas and listComponent and iconLayer and buttonLayer

    if not interfaceAvailable then
        if skillsUIAttached then
            clearSkillBorders()
        end
        attachRetryTicks = 0
        return
    end

    if skillsUIAttached then
        local sentinelValid = false
        if currentList then
            local worked, width = pcall(function()
                return currentList.width
            end)
            sentinelValid = worked and width ~= nil
        end

        if sentinelValid then
            return
        end

        clearSkillBorders()
    end

    if attachRetryTicks > 0 then
        attachRetryTicks = attachRetryTicks - 1
        return
    end

    if attachToSkillsInterface(canvas, listComponent, iconLayer, buttonLayer) then
        skillsUIAttached = true
        attachRetryTicks = 0
    else
        attachRetryTicks = ATTACH_RETRY_TICKS
    end
end

local function updateSkillBorder(skill, progress)
    local border = skillBorders[skill]
    if not border then
        return
    end

    border.progress = progress
    pcall(function()
        renderBorder(border, progress)
    end)
end

-- SettingsLayerReady supplies this plugin's native Plugin Hub settings area.
Event.SettingsLayerReady.Subscribe(
    "skillsProgressSettings",
    function(event)
        local worked, errorMessage = pcall(function()
            if settingsView then
                settingsView:Destroy()
                settingsView = nil
            end
            thicknessMinusButton = nil
            thicknessValueText = nil
            thicknessPlusButton = nil

            local parent = event.component
            -- PrettyUI builds only the controls inside the native settings area.
            settingsView = prettyui.SimpleView.new(parent, {
                width = parent.width,
                height = parent.height,
            })

            settingsView:AddTitle("Level Lens")
            settingsView:AddText("Progress indicator style")
            settingsView:AddRadioButton({
                { text = "Background bar", value = "background" },
                { text = "Bottom bar", value = "bottom" },
                { text = "Left bar", value = "left" },
            }, {
                selectedValue = indicatorStyle,
                onChange = function(_, value)
                    indicatorStyle = value
                    PersistentDB:SetString(
                        "skillsProgressIndicatorStyle",
                        indicatorStyle
                    )
                    updateThicknessControls()
                    refreshAllProgressIndicatorStyles()
                end,
            })

            settingsView:AddText("Progress bar thickness")
            thicknessMinusButton = settingsView:AddSimpleButton(
                "-",
                function()
                    if barThickness > 1 then
                        barThickness = math.max(1, math.min(barThickness - 1, 6))
                        PersistentDB:SetInt(
                            "skillsProgressBarThickness",
                            barThickness
                        )
                        thicknessValueText.content =
                            tostring(barThickness) .. " PX"
                        updateThicknessControls()
                        refreshAllProgressIndicatorStyles()
                    end
                end,
                {
                    width = 32,
                    height = 24,
                    columnGap = 12,
                }
            )
            thicknessValueText = settingsView:AddText({
                text = tostring(barThickness) .. " PX",
                inline = true,
                width = 48,
                height = 24,
                columnGap = 12,
            })
            thicknessPlusButton = settingsView:AddSimpleButton(
                "+",
                function()
                    if barThickness < 6 then
                        barThickness = math.max(1, math.min(barThickness + 1, 6))
                        PersistentDB:SetInt(
                            "skillsProgressBarThickness",
                            barThickness
                        )
                        thicknessValueText.content =
                            tostring(barThickness) .. " PX"
                        updateThicknessControls()
                        refreshAllProgressIndicatorStyles()
                    end
                end,
                {
                    inline = true,
                    width = 32,
                    height = 24,
                }
            )
            updateThicknessControls()

            settingsView:AddText("Progress bar colours")
            settingsView:AddRadioButton({
                { text = "Rarity colours", value = "rarity" },
                { text = "Solid green", value = "green" },
            }, {
                selectedValue = useRarityColors and "rarity" or "green",
                onChange = function(_, value)
                    useRarityColors = value == "rarity"
                    PersistentDB:SetBool(
                        "skillsProgressUseRarityColors",
                        useRarityColors
                    )
                    refreshAllProgressIndicatorStyles()
                end,
            })
        end)

        if not worked then
            print(
                "[Level Lens] UI error: "
                    .. tostring(errorMessage)
            )
        end
    end
)

-- XP remains event-driven. This server-tick check only watches whether the
-- separately loaded Skills interface appeared, disappeared, or was rebuilt.
Event.ServerLogic.Subscribe("skillsProgressInterfaceLifecycle", function()
    checkSkillsInterface()
end)

-- LIST size is sampled every 100ms. A size change starts a short-lived watcher
-- that checks tile geometry until the layout has remained stable for 500ms.
-- Idle samples read only LIST width and height; they do not enumerate skill tiles.
Event.Draw.Subscribe(RESIZE_DRAW_SUBSCRIPTION, function(drawEvent)
    local timeDeltaSecs = tonumber(drawEvent.timeDeltaSecs) or 0
    resizePollElapsed = math.min(
        RESIZE_REFRESH_INTERVAL,
        resizePollElapsed + timeDeltaSecs
    )
    if resizePollElapsed < RESIZE_REFRESH_INTERVAL then
        return
    end

    resizePollElapsed = 0
    if not skillsUIAttached or not currentList then
        return
    end

    local sizeRead, listWidth, listHeight = pcall(function()
        return currentList.width, currentList.height
    end)
    if not sizeRead or listWidth == nil or listHeight == nil then
        return
    end

    if lastListWidth == nil or lastListHeight == nil then
        lastListWidth = listWidth
        lastListHeight = listHeight
        return
    end

    local sizeChanged = listWidth ~= lastListWidth or listHeight ~= lastListHeight
    lastListWidth = listWidth
    lastListHeight = listHeight

    if sizeChanged then
        resizeWatchActive = true
        resizeStableElapsed = 0
    end

    if not resizeWatchActive then
        return
    end

    local worked, inspectedTiles, changedBorders = pcall(refreshCurrentSkillBorderGeometry)
    if not worked or not inspectedTiles then
        return
    end

    if sizeChanged or changedBorders > 0 then
        resizeStableElapsed = 0
    else
        resizeStableElapsed = resizeStableElapsed + RESIZE_REFRESH_INTERVAL
    end

    if resizeStableElapsed >= RESIZE_SETTLE_TIME then
        resizeWatchActive = false
        resizeStableElapsed = 0
    end
end)

-- Attach immediately when the Skills interface is already open. If it is not,
-- the lightweight lifecycle listener above will attach when it appears.
checkSkillsInterface()

-- Event.SkillTransmit only fires when a player skill value changes.
-- We calculate progress on load or skill changes instead of checking every skill every tick.
Event.SkillTransmit.Subscribe("skillsProgressSkillTransmit", function(skillTransmitEvent)
    local skill = skillTransmitEvent.skill

    if maxLevels[skill] then
        local progress = getSkillProgress(skill)
        -- Event.SkillTransmit drives XP changes and updates only this skill's border.
        updateSkillBorder(skill, progress)
    end
end)

-- Plugin-created native UI must be destroyed on disable/reload. We destroy only
-- our rectangles and remove only subscriptions owned by this plugin.
function PluginShutdown()
    Event.Draw.Unsubscribe(RESIZE_DRAW_SUBSCRIPTION)
    Event.SkillTransmit.Unsubscribe("skillsProgressSkillTransmit")
    Event.ServerLogic.Unsubscribe("skillsProgressInterfaceLifecycle")
    Event.SettingsLayerReady.Unsubscribe("skillsProgressSettings")
    if settingsView then
        settingsView:Destroy()
        settingsView = nil
    end
    thicknessMinusButton = nil
    thicknessValueText = nil
    thicknessPlusButton = nil
    clearSkillBorders()
end
