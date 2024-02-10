-- Basic setup
local addonName, RoachIQ = ...
RoachIQ = RoachIQ or {}
RoachIQ.GroupMembers = {}

-- Frame creation and layout setup
local function CreateMainFrame()
    local frame = CreateFrame("Frame", "RoachIQ_MainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 400) -- Width, Height
    frame:SetPoint("CENTER") -- Position on the screen
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOPLEFT", frame.TitleBg, "TOPLEFT", 5, -5)
    frame.title:SetText("RoachIQ")

    -- TODO: Avoid affecting event listeners for other keys besides Escape (add else clause to pass thru everything else?)
    -- -- Add OnKeyDown script handler to quit when Escape key is pressed
    -- frame:SetScript("OnKeyDown", function(self, key)
    --     if key == "ESCAPE" then
    --         self:Hide() -- Hide the main frame
    --     end
    -- end)

    return frame
end

local mainFrame = CreateMainFrame() -- Create main frame early to allow reference

local dungeonsToTrack = {
    ["Goldshire"] = {"Cow"},
    ["Ragefire Chasm"] = {"Oggleflint", "Taragaman the Hungerer", "Jergosh the Invoker", "Bazzalan"},
    ["The Deadmines"] = {"Rhahk'Zor", "Sneed", "Gilnid", "Mr. Smite", "Captain Greenskin", "Edwin VanCleef"},
    ["Wailing Caverns"] = {"Disciple of Naralex", "Lady Anacondra", "Kresh", "Lord Pythas", "Skum", "Verdan the Everliving", "Mutanus the Devourer", "Deviate Faerie Dragon"},
}

local killedBosses = {}  -- Initialize a table to keep track of slain bosses

-- Add a flag to track whether the player is in combat
local inCombat = false

-- Function to check if the player is in combat
local function IsPlayerInCombat()
    return inCombat
end


local function ShowEvents(eventsFrame)
    -- Hide any previous message or frames
    if eventsFrame.message then eventsFrame.message:Hide() end

    -- Release previous event frames
    for _, child in ipairs({eventsFrame:GetChildren()}) do
        if child:IsObjectType('Frame') and child:GetName() and string.find(child:GetName(), "RoachIQEventFrame") then
            child:Hide()
            child:ClearAllPoints()
            child:SetParent(nil)
        end
    end

    -- Display key events from the combat log
    local eventList = {} -- Initialize an empty event list

    -- Iterate through the dungeons and their respective bosses
    for dungeonName, bossList in pairs(dungeonsToTrack) do
        local dungeonCleared = true -- Assume the dungeon is cleared initially

        -- Check if all bosses in the boss list for the current dungeon have been killed
        for _, boss in ipairs(bossList) do
            if not killedBosses[boss] then
                dungeonCleared = false -- Set the flag to false if any boss is not killed
                break
            end
        end

        -- If the dungeon is cleared, add it to the event list
        if dungeonCleared then
            table.insert(eventList, dungeonName .. " cleared")
        end
    end

    -- Display the events in the eventsFrame
    local startY = -30
    for i, eventText in ipairs(eventList) do
        local eventFrame = CreateFrame("Frame", "RoachIQEventFrame"..i, eventsFrame)
        eventFrame:SetSize(580, 20) -- Adjusted to fit within the main frame width
        eventFrame:SetPoint("TOPLEFT", 10, startY)

        local eventTextFrame = eventFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        eventTextFrame:SetJustifyH("LEFT")
        eventTextFrame:SetPoint("LEFT", 5, 0)
        eventTextFrame:SetText(eventText)

        startY = startY - 25 -- Adjust spacing between rows
    end
end


local function CombatLogEventHandler(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
    end
    
    if not inCombat then
        local _, subevent, _, sourceGUID, _, _, _, _, destName = CombatLogGetCurrentEventInfo()
        
        -- Check if the event is a boss kill
        if subevent == "UNIT_DIED" and destName then
            print(destName)  -- Print the name of the unit that was killed
            -- Iterate through dungeons
            for dungeonName, bossList in pairs(dungeonsToTrack) do
                -- Check if the boss killed is in the boss list of the current dungeon
                for _, boss in ipairs(bossList) do
                    if string.find(destName, boss) then
                        -- Mark the boss as killed
                        killedBosses[boss] = true
                        -- Update the Events tab content if it's currently shown
                        if PanelTemplates_GetSelectedTab(RoachIQ_MainFrame) == 3 then
                            ShowEvents(RoachIQEventsFrame)
                        end
                        return  -- Exit the function once a boss is found and marked
                    end
                end
            end
        end
    end
end


-- Function to handle event tab updates
local function UpdateEventTab()
    if PanelTemplates_GetSelectedTab(RoachIQ_MainFrame) == 3 then
        ShowEvents(RoachIQEventsFrame)
    end
end

-- Add a handler for combat state changes
local function CombatStateChangeEventHandler(self, event, ...)
    -- Update event tab when combat ends
    if event == "PLAYER_REGEN_ENABLED" then
        UpdateEventTab()
    end
end

-- Create quizzes tab content
local quizzesFrame = CreateFrame("Frame", "RoachIQQuizzesFrame", mainFrame)
quizzesFrame:SetAllPoints(mainFrame)

-- Create group tab content
local groupFrame = CreateFrame("Frame", "RoachIQGroupFrame", mainFrame)
groupFrame:SetAllPoints(mainFrame)

-- Create events tab content
local eventsFrame = CreateFrame("Frame", "RoachIQEventsFrame", mainFrame)
eventsFrame:SetAllPoints(mainFrame)

-- Custom function to clear children from a frame
local function ReleaseChildren(frame)
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
        child:ClearAllPoints()
    end
end

local function BuildQuizzesTab(quizzesFrame)
    ReleaseChildren(quizzesFrame)
    local placeholderText = quizzesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    placeholderText:SetPoint("TOP", quizzesFrame, "TOP", 0, -30)
    placeholderText:SetText("Quizzes Content Goes Here")
    print("BuildQuizzesTab executed") -- Debugging print
end

local function UpdateGroupMembers()
    wipe(RoachIQ.GroupMembers) -- Clear existing members list
    local groupType = IsInRaid() and "raid" or IsInGroup() and "party"
    if not groupType then return end -- Exit if not in a group

    local numGroupMembers = GetNumGroupMembers()
    if groupType == "party" then numGroupMembers = numGroupMembers + 1 end -- Include player in party size

    for i = 1, numGroupMembers do
        local unit = (groupType == "party" and i == numGroupMembers) and "player" or groupType..i
        local name, realm = UnitName(unit)
        local _, class = UnitClass(unit)
        if name then
            name = realm and realm ~= "" and name.."-"..realm or name
            table.insert(RoachIQ.GroupMembers, {
                name = name,
                class = class or "Unknown"
            })
        end
    end
end

local function ShowGroupMembers(groupFrame)
    -- Hide any previous message or frames
    if groupFrame.message then groupFrame.message:Hide() end

    -- Release previous member frames
    for _, child in ipairs({groupFrame:GetChildren()}) do
        if child:IsObjectType('Frame') and child:GetName() and string.find(child:GetName(), "RoachIQGroupMemberFrame") then
            child:Hide()
            child:ClearAllPoints()
            child:SetParent(nil)
        end
    end

    -- Display message if not in a group, but only for the Group tab
    if PanelTemplates_GetSelectedTab(RoachIQ_MainFrame) == 2 and not IsInGroup() and not IsInRaid() then
        groupFrame.message = groupFrame.message or groupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        groupFrame.message:SetPoint("CENTER")
        groupFrame.message:SetText("You must be in a group to enable this page.")
        groupFrame.message:Show()
        return
    end

    -- Display group members
    local startY = -30
    for i, memberInfo in ipairs(RoachIQ.GroupMembers) do
        local memberFrame = CreateFrame("Frame", "RoachIQGroupMemberFrame"..i, groupFrame)
        memberFrame:SetSize(580, 20) -- Adjusted to fit within the main frame width
        memberFrame:SetPoint("TOPLEFT", 10, startY)

        local nameText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetJustifyH("LEFT")
        nameText:SetPoint("LEFT", 5, 0)
        nameText:SetText(memberInfo.name)

        local classText = memberFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        classText:SetJustifyH("RIGHT")
        classText:SetPoint("RIGHT", -5, 0)
        classText:SetText(memberInfo.class)

        startY = startY - 25 -- Adjust spacing between rows
    end
end

local function ShowContentForTab(tabId)
    quizzesFrame:Hide()
    groupFrame:Hide()
    eventsFrame:Hide() -- Hide the Events tab content
    
    if tabId == 1 then
        BuildQuizzesTab(quizzesFrame)
        quizzesFrame:Show()
        print("Quizzes tab shown") -- Debugging print
    elseif tabId == 2 then
        UpdateGroupMembers()
        ShowGroupMembers(groupFrame)
        groupFrame:Show()
        print("Group tab shown") -- Debugging print
    elseif tabId == 3 then
        ShowEvents(eventsFrame)
        eventsFrame:Show()
        print("Events tab shown") -- Debugging print
        -- Recheck combat log events when Events tab is shown
        CombatLogEventHandler()
    end
end

-- Modify CreateTab to handle content switching
local function CreateTab(parent, id, title)
    local tab = CreateFrame("Button", "$parentTab"..id, parent, "CharacterFrameTabButtonTemplate")
    tab:SetID(id)
    tab:SetText(title)
    tab:SetScript("OnClick", function()
        PanelTemplates_SetTab(parent, id)
        ShowContentForTab(id)
    end)
    PanelTemplates_TabResize(tab, 0)
    return tab
end


-- Tab setup
local quizzesTab = CreateTab(mainFrame, 1, "Quizzes")
quizzesTab:SetPoint("TOPLEFT", mainFrame, "BOTTOMLEFT", 5, 7)
local groupTab = CreateTab(mainFrame, 2, "Group")
groupTab:SetPoint("TOPLEFT", quizzesTab, "TOPRIGHT", -14, 0)
local eventsTab = CreateTab(mainFrame, 3, "Events")
eventsTab:SetPoint("TOPLEFT", groupTab, "TOPRIGHT", -14, 0)

PanelTemplates_SetNumTabs(mainFrame, 3) -- Adjust the number according to your actual tabs
PanelTemplates_SetTab(mainFrame, 1) -- Optionally set the initial tab
ShowContentForTab(PanelTemplates_GetSelectedTab(mainFrame)) -- Initialize content

-- Simplify slash command to toggle display
SLASH_ROACHIQ1 = "/roachiq"
SlashCmdList["ROACHIQ"] = function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        ShowContentForTab(PanelTemplates_GetSelectedTab(mainFrame))
    end
end

mainFrame:Hide() -- Hide the main frame initially

-- Register for events to track combat state changes
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", CombatStateChangeEventHandler)

-- Register event handling for group updates and combat log events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event)
    if mainFrame:IsShown() then
        ShowContentForTab(PanelTemplates_GetSelectedTab(mainFrame))
    end
end)

-- Register for combat log events
mainFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
mainFrame:SetScript("OnEvent", function(self, event, ...)
    CombatLogEventHandler(self, event, ...)
end)

-- Register for the PLAYER_LOGIN event to enable combat logging
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    -- Enable combat logging
    LoggingCombat(true)
end)
