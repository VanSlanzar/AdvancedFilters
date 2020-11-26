AdvancedFilters = AdvancedFilters or {}
local AF = AdvancedFilters
local firstOpened
local firstOpenedIsBank = false
local changeFilterCallsAfterFirstOpenWasBank = 0
local vanillaUIChangesToSearchBarsWereDone = false
AF.vanillaUIChangesToSearchBarsWereDone = vanillaUIChangesToSearchBarsWereDone

---==========================================================================================================================================================================
--______________________________________________________________________________________________________________________
--                                                  TODO - BEGIN
--______________________________________________________________________________________________________________________
--TODO Last updated: 2020-11-26
--Max todos: #52

--#14 Drag & drop item at vendor buyback inventory list throws error:
--[[
EsoUI/Ingame/Inventory/InventorySlot.lua:2597: Attempt to access a private function 'PickupStoreBuybackItem' from insecure code. The callstack became untrusted 3 stack frame(s) from the top.
stack traceback:
EsoUI/Ingame/Inventory/InventorySlot.lua:2597: in function '(anonymous)'
|caaaaaa<Locals> inventorySlot = ud </Locals>|r
EsoUI/Ingame/Utility/ZO_SlotUtil.lua:14: in function 'RunHandlers'
|caaaaaa<Locals> handlerTable = [table:1]{}, slot = ud, handlers = [table:2]{}, i = 1 </Locals>|r
(tail call): ?
ZO_StackSplitSource_DragStart:4: in function '(main chunk)'
|caaaaaa<Locals> self = ud, button = 1 </Locals>|r
]]

--#19: 2019-12-23, Feature, Baertram:
--     Use context menu at dropdownboxes to show the last used filters from dropdown boxes at the given subfilterGroup
--     e.g. select Weapons>1hd as subfilterGroup, select "Level filter 1-49" from dropdown filterbox.
--     Right click the dropdown box and ALWAYS show entries "Invert current filter 1-49", "Select all".
--     But also show below the last selected filter 1-49 now (up to last 5 selected ones from whatever subfilterGroup).
--     Should check though if the filter of the dropdown box can be applied to the current panel and subfilterGroup! -> Possible?

--#45: 2020-10-26: Bug, Baertram:
--     Fix search box at quickslots

--#50: 2020-10-31: Bug, Baertram:
--     Opening the bank withdraw tab directly after reloadui/login will not hide the searchDivider control line
--

--==========================================================================================================================================================================
--______________________________________________________________________________________________________________________
--  UPDATE INFORMATION: since AF 1.6.0.2 - Current 1.6.0.3 - Changed 2020-11-26
--______________________________________________________________________________________________________________________


--______________________________________________________________________________________________________________________
--                                                  ADDED
--______________________________________________________________________________________________________________________
--
--
--
--
--
--
--
--______________________________________________________________________________________________________________________
--                                              ADDED ON REQUEST
--______________________________________________________________________________________________________________________


--______________________________________________________________________________________________________________________
--                                                  Changed
--______________________________________________________________________________________________________________________
--

--______________________________________________________________________________________________________________________
--                                                  FIXED
--______________________________________________________________________________________________________________________
--#51: Layouts of e.g. quickslot, guild store fixed (only was wrong after you had interacted with a crafting table e.g.)
--#52: Fence / Launder will not show an error anymore if you had the quest tab last opened in your invenory as you talk
--     to the fence


---==========================================================================================================================================================================
---==========================================================================================================================================================================
---==========================================================================================================================================================================
--______________________________________________________________________________________________________________________
--                                                  NOT REPLICABLE
--______________________________________________________________________________________________________________________
--Not replicable 2019-08-11
--1. Error message on PTS if opening the Enchanting table:
--[[
local subfilterBar = subfilterGroup[craftingType][currentFilter]
-subfilterBar was missing somehow-

user:/AddOns/AdvancedFilters/main.lua:213: attempt to index a nil value
stack traceback:
user:/AddOns/AdvancedFilters/main.lua:213: in function 'ShowSubfilterBar'
|caaaaaa<Locals> craftingType = 3, UpdateListAnchors = user:/AddOns/AdvancedFilters/main.lua:165, doDebugOutput = false, subfilterGroup = tbl </Locals>|r
user:/AddOns/AdvancedFilters/util.lua:732: in function 'Update'
]]

--Not replicable 2019-08-11
--2. Error message upon doing something at crafting station (User: Phuein)
--[[
-subfilterBar was missing somehow-
-> local subfilterBar = subfilterGroup[craftingType][currentFilter]

https://imgur.com/7btGZff
user:/AddOns/AdvancedFilters/main.lua:213 attempt o index a nil value, craftingType = 1
]]

--______________________________________________________________________________________________________________________
--                                                  TODO - END
--______________________________________________________________________________________________________________________
---==========================================================================================================================================================================

--Constants in local variables
local controlsForChecks = AF.controlsForChecks
local playerInvVar = controlsForChecks.playerInv
local smithingBaseVar = controlsForChecks.smithingBaseVar
local smithingVar = controlsForChecks.smithing
local enchantingVar = controlsForChecks.enchanting
local enchantingBaseVar = controlsForChecks.enchantingBaseVar
local retraitVar = controlsForChecks.retrait
local quickslotVar = controlsForChecks.quickslot

--local functions for speedup
local util = AF.util
local RefreshSubfilterBar                   = util.RefreshSubfilterBar
local GetCraftingType                       = util.GetCraftingType
local ThrottledUpdate                       = util.ThrottledUpdate
local CheckIfNoSubfilterBarShouldBeShown    = util.CheckIfNoSubfilterBarShouldBeShown
local UpdateCurrentFilter                   = util.UpdateCurrentFilter
local GetInventoryFromCraftingPanel         = util.GetInventoryFromCraftingPanel
local IsCraftingStationInventoryType        = util.IsCraftingStationInventoryType
local IsCraftingPanelShown                  = util.IsCraftingPanelShown
--local mapCurrentFilterItemFilterCategoryToItemFilterType = util.mapCurrentFilterItemFilterCategoryToItemFilterType

local function delayedCall(delay, functionToCall, params)
    if functionToCall then
        delay = delay or 0
        zo_callLater(function() functionToCall(params) end, delay)
    end
end

function AF.showChatDebug(functionName, chatOutputVars)
    local functionNameStr = tostring(functionName) or "n/a"
    functionNameStr = " " .. functionNameStr
    chatOutputVars = chatOutputVars or ""
    local strings = AF.strings
    local afPrefixError = ""
    --Center screen annonucenment
    local csaText
    if strings and strings["errorCheckChatPlease"] then
        csaText = strings["errorCheckChatPlease"]
        afPrefixError = strings.AFPREFIXERROR
    else
        csaText = "|cFF0000[AdvancedFilters ERROR]|r Please read the error message in the chat!"
    end
    if csaText ~= "" then
        local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.GROUP_KICK)
        params:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_DISPLAY_ANNOUNCEMENT)
        params:SetText(csaText)
        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
    end
    --Chat output
    if not strings then return end
    d(">>>======== AF ERROR - BEGIN ========>>>")
    d(afPrefixError .. "|c00ccff" .. tostring(functionNameStr) .. "|r")
    d(strings.errorWhatToDo1)
    d(strings.errorWhatToDo2)
    d("-> [" .. tostring(functionNameStr) .. "]\n")
    if chatOutputVars ~= "" then
        d(chatOutputVars)
    end
    d("<<<======== AF ERROR - END ========<<<")
end
local showChatDebug = AF.showChatDebug

--Set the last used currentFilter of the bank inventory to internal AF data tables
local function updateLastBankCurrentFilter(bankInvType)
    local bankInvTypes = AF.bankInvTypes
    --Check if current inventory is a bank withdraw panel
    local isBankInvType = bankInvTypes[bankInvType] or false
    if not isBankInvType then return end
    if not playerInvVar.inventories or not playerInvVar.inventories[bankInvType] then return end
    local currentBankFilter = playerInvVar.inventories[bankInvType].currentFilter
--d(">Current bank currentFilter: " ..tostring(currentBankFilter))
    AF.lastCurrentFilter[bankInvType] = currentBankFilter
end

--Is the last opened bank currentFilter saved then use this as new currentFilter if the current currentFilter is 0 ("All")
local function checkIfBankLastCurrentFilterIsGiven(self, filterTab)
    if AF.settings.debugSpam then d(">checkIfBankLastCurrentFilterIsGiven - START") end
    local currentInvType = AF.currentInventoryType

    local tabInvType = filterTab.inventoryType
    local tabInventory = self.inventories[tabInvType]
    local currentFilter = tabInventory.currentFilter
    --local currentFilter, _, _ = self:GetTabFilterInfo(tabInvType, filterTab) --filterData.filterType, filterData.activeTabText, filterData.hiddenColumns

--d(">invType: " ..tostring(currentInvType) ..", currentFilter: " ..tostring(currentFilter))
    if not currentFilter then currentFilter = 0 end
    if currentFilter == 0 then
        local bankInvTypes = AF.bankInvTypes
        --Check if current inventory is a bank withdraw panel
        local isBankInvType = bankInvTypes[currentInvType] or false
--d(">isBankInvType: " ..tostring(isBankInvType))
        if isBankInvType == true then
            if AF.settings.debugSpam then d(">isBank: true") end
            --Check if for this bank withdraw panel a last currentFilter was known
            if AF.lastCurrentFilter and AF.lastCurrentFilter[currentInvType] then
                currentFilter = AF.lastCurrentFilter[currentInvType]
                --Reset the last used currentFilter at the bank again so it is not re-used at next inventory:ChangeFilter() call
--d(">lastBankCurrentFilter: " ..tostring(currentFilter))
                AF.lastCurrentFilter[currentInvType] = nil
--d(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
--d(">>>>> Last bank filter deleted!")
--d(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            end
        end
    end
    if AF.settings.debugSpam then d(">checkIfBankLastCurrentFilterIsGiven - END - currentFilter: " ..tostring(currentFilter)) end
    return currentFilter
end

--Reanchor & hide some controls at the vanilla UI, like the searchBar and box.
--Based on the baseControl the controls to change are children
local function reanchorAndHideVanillaUIControls(baseControl)
--d("[AF]reanchorAndHideVanillaUIControls")
    if not baseControl then return end
    local ZOsControlNames = AF.ZOsControlNames
    local tabsName = ZOsControlNames.tabs
    local searchDividerName = ZOsControlNames.searchDivider
    --SearchDivider
    local searchDivider = GetControl(baseControl, searchDividerName)
    if searchDivider then
        searchDivider:SetHidden(true)
    end
    --Tabs
    local tabs = GetControl(baseControl, tabsName)
    if tabs then
--d(">Found tabs")
        local tabsActiveName = ZOsControlNames.active
        local tabsActive = GetControl(tabs, tabsActiveName)
        if tabsActive then
            --Hide the "All: All" text at the subfilterbar
            tabsActive:SetHidden(true)
        end
    end
    --Search filters
    local searchFiltersName = ZOsControlNames.searchFilters
    local searchFilters = GetControl(baseControl, searchFiltersName)
    if searchFilters then
--d(">Found searchFilters")
        --Text search box
        local textSearchName = ZOsControlNames.textSearch
        local searchFiltersTextSearch = GetControl(searchFilters, textSearchName)
        if searchFiltersTextSearch then
            searchFiltersTextSearch:ClearAnchors()
            searchFiltersTextSearch:SetParent(baseControl)
            searchFiltersTextSearch:SetAnchor(BOTTOMLEFT, baseControl, TOPLEFT, 0, (-1 * searchFiltersTextSearch:GetHeight()) - 10)
            if not VotanSearchBox_SavedVariables then
                searchFiltersTextSearch:SetDimensions(150, 25)
                searchFiltersTextSearch:SetAlpha(0.45)
            end
        end
        searchFilters:SetHidden(true)
        --Search filters sub tab buttons
        local subTabsName = ZOsControlNames.subTabs
        local searchFiltersSubTabs = GetControl(searchFilters, subTabsName)
        if searchFiltersSubTabs then
            searchFiltersSubTabs:SetHidden(true)
        end
    end
end

--======================================================================================================================
--=== HOOKS - BEGIN ====================================================================================================
--======================================================================================================================
--Load the hooks of the different inventories etc.
local function InitializeHooks()
    AF.currentInventoryType = INVENTORY_BACKPACK
    AF.currentInventoryCurrentFilter = 0

    AF.blockOnInventoryFilterChangedPreHookForCraftBag = false

    --Workaround for the "last opened filter" at the inventories so that closing the inv will not clear the last selected filter
    --Thanks to code65536! for the idea
    ZO_BackpackLayoutFragment.Hide = function(self)
        --PLAYER_INVENTORY:ApplyBackpackLayout(DEFAULT_BACKPACK_LAYOUT_DATA) -> This will reset the last selected filter
        self:OnHidden()
    end

    --TABLE TRACKER
    --[[
        this is a hacky way of knowing when items go in and out of an inventory.

        t = the tracked table (ZO_InventoryManager.isListDirty/playerInvVar.isListDirty)
        k = inventoryType
        v = isDirty
        pk = private key (no two empty tables are the same) where we store t
        mt = our metatable where we can do the tracking
    ]]
    --create private key
    local pk = {}
    --create metatable
    local mt = {
        __index = function(t, k)
            --d("*access to element " .. tostring(k))

            --access the tracked table
            return t[pk][k]
        end,
        __newindex = function(t, k, v)
            -->This function is called by e.g. LibFilters 3 function SafeUpdateList, which calls
            -->playerInvVar:UpdateList(INVENTORY_*) (e.g. INVENTORY_BANK)
            --d("*update of element " .. tostring(k) .. " to " .. tostring(v))

            --update the tracked table
            t[pk][k] = v

            --refresh subfilters for inventory type
            local subfilterGroup = AF.subfilterGroups[k]
            if not subfilterGroup then return end
            local craftingType = GetCraftingType()
            local invType = AF.currentInventoryType
            local currentSubfilterBar = subfilterGroup.currentSubfilterBar
            if not currentSubfilterBar then return end
            local RefreshSubfilterBarUpdaterName = "MetaTable___RefreshSubfilterBar_" .. invType .. "_" .. craftingType .. currentSubfilterBar.name
            if AF.settings.debugSpam then d("[AF]Metatable proxy: Calling ThrottledUpdate: " ..tostring(RefreshSubfilterBarUpdaterName)) end
            ThrottledUpdate(RefreshSubfilterBarUpdaterName,
                    10, RefreshSubfilterBar, currentSubfilterBar)
        end,
    }
    --tracking function. Returns a proxy table with our metatable attached.
    --t is e.g. playerInvVar.isListDirty
    local function track(t)
        local proxy = {}
        proxy[pk] = t
        setmetatable(proxy, mt)
        return proxy
    end
    --untracking function. Returns the tracked table and destroys the proxy.
    local function untrack(proxy)
        local t = proxy[pk]
        proxy = nil
        return t
    end

    --As some inventories/panels use the same parents to anchor the subfilter bars to
    --the change of the panel won't change the parent and thus doesn't hide the subfilter
    --bars properly.
    --Example: ENCHANTING creation & extraction, deconstruction/improvement for woodworking/blacksmithing/clothing & jewelry deconstruction/improvement
    --and inventory + inventory quest
    --This function checks the inventory type and hides the old subfilterbar if needed.
    local function hideSubfilterBarSameParent(inventoryType)
        if AF.settings.debugSpam then d("[AF]hideSubfilterBarSameParent - inventoryType: " .. inventoryType) end
        if not inventoryType then return end
        local mapInvTypeToInvTypeBefore = AF.mapInvTypeToInvTypeBefore
        if not mapInvTypeToInvTypeBefore then return end
        if mapInvTypeToInvTypeBefore[inventoryType] == nil then return false end
        local invTypeBefore = mapInvTypeToInvTypeBefore[inventoryType]
        if not invTypeBefore then return end
        local subfilterGroupBefore = AF.subfilterGroups[invTypeBefore]
        if subfilterGroupBefore ~= nil and subfilterGroupBefore.currentSubfilterBar then
            if AF.settings.debugSpam then d(">[AF]hideSubfilterBarSameParent - currentSubfilterBar hidden") end
            subfilterGroupBefore.currentSubfilterBar:SetHidden(true)
        end
    end

    --Show the subfilter bar of AdvancedFilters below the parent filter (e.g. button for armor, weapons, material, ...)
    --The subfilter bars are defined via the file constants.lua in table "subfilterGroups".
    --The contents of the subfilter bars are defined in file constants.lua in table "subfilterButtonNames"
    --The filter contents and their callback functions (see top of file data.lua) for each content of the subfilter bar are defined in file data.lua in the table "AF.subfilterCallbacks"
    --Their parents (e.g. the player inventory or the bank or the crafting smithing station) are defined in file constants.lua in table "filterBarParents"
    local function ShowSubfilterBar(currentFilter, craftingType, customInventoryFilterButtonsItemType, currentInvType)
        if AF.settings.debugSpam then d(">>----- SHOW SUBFILTER BAR -----\n----------------------------------------------->>") end
--d(">>-----------------------------------------------\n---ShowSubfilterBar---------------->>")
--d(">currentFilter: " ..tostring(currentFilter) .. ", craftingType: " ..tostring(craftingType) .. ", customInventoryFilterButtonsItemType: " .. tostring(customInventoryFilterButtonsItemType) ..", currentInvType: " ..tostring(currentInvType))
        ----------------------------------------------------------------------------------------------------------------
        ----------------------------------------------------------------------------------------------------------------
        ----------------------------------------------------------------------------------------------------------------
        --Update the y offsetts in pixels for the subfilter bar, so it is shown below the parent's filter buttons
        local function UpdateListAnchors(self, shiftY, p_subFilterBar, p_isCraftingInventoryType)
--d("[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[")
--d("[AF]UpdateListAnchors shiftY: " .. tostring(shiftY))
            if AF.settings.debugSpam then d(">UpdateListAnchors - shiftY: " .. tostring(shiftY)) end
            if self == nil then return end
            local invTypeUpdateListAnchor = AF.currentInventoryType
            local isQuickslot = (self == quickslotVar or invTypeUpdateListAnchor == LF_QUICKSLOT) or false
            local isGuildStoreSell = (self == playerInvVar and TRADING_HOUSE.currentMode == ZO_TRADING_HOUSE_MODE_SELL) or false

            --Check if the current layoutData (offsets of controls in the inventory) is given
            --local layoutData = (p_isCraftingInventoryType == true and util.GetCraftingInventoryLayoutData(invTypeUpdateListAnchor)) or self.appliedLayout
            local layoutData = self.appliedLayout
            if layoutData == nil or isGuildStoreSell == true then
                --Check if the layoutData or any offsets for the list are stored in AF internal constants
--d(">layoutData was taken from default AF BACKPACK LAYOUT!, isGuildStoreSell: " ..tostring(isGuildStoreSell))
                --Standard inv layout
                layoutData = BACKPACK_DEFAULT_LAYOUT_FRAGMENT.layoutData
                local additionalLayoutData = util.GetCraftingInventoryLayoutData(invTypeUpdateListAnchor)
                if additionalLayoutData ~= nil then
                    local layoutDataCopy = ZO_ShallowTableCopy(layoutData)
                    for key,value in pairs(additionalLayoutData) do
                        layoutDataCopy[key] = value
                    end
                    layoutData = layoutDataCopy
--d(">>Overwrote some layoutData settings with additional layoutdata")
                end
            end
--d(">>invTypeUpdateListAnchor: " ..tostring(invTypeUpdateListAnchor) .. "-layoutData.backpackOffsetY: " ..tostring(layoutData.backpackOffsetY) .. ", sortByOffsetY: " ..tostring(layoutData.sortByOffsetY) .. ", width: " .. tostring(layoutData.width))
            if not layoutData then
                return
            end

            --For debugging
            AF.currentayoutData = layoutData

            local list = self.list
            if not list and self.inventories ~= nil and self.inventories[invTypeUpdateListAnchor] ~= nil then
                list = self.inventories[invTypeUpdateListAnchor].listView
            end
            --No inventory list found: Detect it now (crafting research e.g.)
            if not list then
--d(">no list control found yet")
                local listData
                local moveInvBottomBarDown
                local anchorTo = (p_subFilterBar and p_subFilterBar.control) or nil
                local reanchorData
                --Get the Smithing research list(s) e.g. and reanchor it
                listData, moveInvBottomBarDown, reanchorData = util.GetListControlForSubfilterBarReanchor(invTypeUpdateListAnchor)
                if not listData then return end
                --list:SetWidth(layoutData.width)
                list = listData.control
                if list then
                    --d(">>list found by util.GetListControlForSubfilterBarReanchor")
                    list:ClearAnchors()
                    list:SetAnchor(listData.anchorPoint or TOP, listData.relativeTo or anchorTo, listData.relativePoint or BOTTOM, listData.offsetX or 0, listData.offsetY or layoutData.backpackOffsetY)
                    --Move the inventory's bottom bar more down?
                    if moveInvBottomBarDown then
                        --Do not move the bar if the addon PerfectPixel is active as it was moved already
                        if not PP then
                            moveInvBottomBarDown:ClearAnchors()
                            moveInvBottomBarDown:SetAnchor(TOPLEFT, list:GetParent(), BOTTOMLEFT, 0, shiftY)
                            moveInvBottomBarDown:SetAnchor(BOTTOMRIGHT)
                        end
                    end
                end
            else
--d(">list was found!")
                --List given
                list:SetWidth(layoutData.width)
                list:ClearAnchors()
                local offsetYList = layoutData.backpackOffsetY
                local anchorVar
                if p_isCraftingInventoryType == true or isQuickslot == true then
                    offsetYList = offsetYList + shiftY
                end
                if isQuickslot then
                    anchorVar = ZO_QuickSlot
                end
                list:SetAnchor(TOPRIGHT, anchorVar, TOPRIGHT, 0, offsetYList)
                list:SetAnchor(BOTTOMRIGHT)
--d(">ZO_ScrollList was changed to offsetY: " .. (offsetYList) .. ", height: " ..tostring(list:GetHeight()))
                ZO_ScrollList_SetHeight(list, list:GetHeight())
            end

            --For debugging
            if list then
                AF.currentList = list
            end

            --Additional controls to reanchor?
            --Get the Smithing research line horizontal scroll list, and other controls below, and reanchor it e.g.
            local _, _, reanchorData = util.GetListControlForSubfilterBarReanchor(invTypeUpdateListAnchor)
            if reanchorData ~= nil then
--d(">>>ReAnchor data was found!")
                for _, reanchorControlData in ipairs(reanchorData) do
                    local controlToReanchor = reanchorControlData.control
                    if controlToReanchor ~= nil then
                        if reanchorControlData.anchorPoint ~= nil
                                and reanchorControlData.relativeTo ~= nil and reanchorControlData.relativePoint ~= nil
                                and reanchorControlData.offsetX ~= nil and reanchorControlData.offsetY ~= nil then
                            controlToReanchor:ClearAnchors()
                            controlToReanchor:SetAnchor(reanchorControlData.anchorPoint, reanchorControlData.relativeTo, reanchorControlData.relativePoint, reanchorControlData.offsetX, reanchorControlData.offsetY)
                        end
                    end
                end
            end

            --Sort header reanchor
            local sortBy = self.sortHeaders or self.sortHeaderGroup
            if sortBy == nil and self.GetDisplayInventoryTable then
                sortBy = self:GetDisplayInventoryTable(invTypeUpdateListAnchor).sortHeaders
            end
            if sortBy == nil then return end
            sortBy = sortBy.headerContainer
            sortBy:ClearAnchors()
            local sortHeaderOffsetY = 0
            local anchorVar
            if isQuickslot == true then
                sortHeaderOffsetY = shiftY
                anchorVar = ZO_QuickSlot
            end
            local offsetYSortHeader = layoutData.sortByOffsetY + sortHeaderOffsetY
            --[[
            if p_isCraftingInventoryType == true then
                offsetYSortHeader = offsetYSortHeader + shiftY
            end
            ]]
            sortBy:SetAnchor(TOPRIGHT, anchorVar, TOPRIGHT, 0, offsetYSortHeader)
--d(">sortBy was moved on Y by: " ..tostring(offsetYSortHeader))

            --Should some inventory controls be hidden?
            -->Called in the fragment callback function for OnShow!
            --util.HideInventoryControls(invTypeUpdateListAnchor)
--d("]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]")
        end
        ----------------------------------------------------------------------------------------------------------------
        --ReAnchor other controls so that the subfilter bar will be shown properly
        local function reAnchorIncludeBankedItemsCheckbox(filterPanelId, subFilterBarHeight)
            --d("[AF]reAnchorIncludeBankedItemsCheckbox")
            --FCOCraftFilter enabled? Then do nothing as it will hide the checkbox!
            --if FCOCraftFilter ~= nil then return end
            --Currently the checkbox is only shown at the crafting panels
            if not util.IsCraftingPanelShown() then return end
            filterPanelId = filterPanelId or util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
            --d(">filterPanelId: " ..tostring(filterPanelId))
            local ZOsControlNames = AF.ZOsControlNames
            local includeBankedCBoxName = ZOsControlNames.includeBankedCheckbox
            local craftingTablePanel = util.GetCraftingTablePanel(filterPanelId)
            local includeBankedCbox = craftingTablePanel and craftingTablePanel.control and craftingTablePanel.control:GetNamedChild(includeBankedCBoxName)
            local parentCtrl = craftingTablePanel.control
            if not includeBankedCbox then
                local craftingTablePanelInv = util.GetCraftingTablePanelInventory(filterPanelId)
                includeBankedCbox = craftingTablePanelInv and craftingTablePanelInv.control and craftingTablePanelInv.control:GetNamedChild(includeBankedCBoxName)
                parentCtrl = craftingTablePanelInv.control
            end
            if includeBankedCbox and parentCtrl then
                --Unanchor the filterDivider control
                local includeBankedCBoxFilterDividerName = ZOsControlNames.filterDivider
                local filterDivider = parentCtrl:GetNamedChild(includeBankedCBoxFilterDividerName)
                if filterDivider and filterDivider.ClearAnchors then filterDivider:ClearAnchors() end
                --Unanchor the buttonDivider control
                local includeBankedCBoxButtonDividerName = ZOsControlNames.buttonDivider
                local buttonDivider = parentCtrl:GetNamedChild(includeBankedCBoxButtonDividerName)
                if buttonDivider and buttonDivider.ClearAnchors then buttonDivider:ClearAnchors() end
                --Move on the y axis the "height of a subfilter bar" pixels to the top, and an additional 5 pixels more to the top
                --SetAnchor(AnchorPosition myPoint, object anchorTargetControl, AnchorPosition anchorControlsPoint, number offsetX, number offsetY)
                includeBankedCbox:ClearAnchors()
                includeBankedCbox:SetAnchor(TOPLEFT, parentCtrl, TOPLEFT, 0, subFilterBarHeight-5)
            end
        end
        ----------------------------------------------------------------------------------------------------------------
        ----------------------------------------------------------------------------------------------------------------
        ----------------------------------------------------------------------------------------------------------------

        local invType = currentInvType or AF.currentInventoryType
        local currentFilterToUse
--d(">invType: " ..tostring(invType) .. ", currentInvType: " ..tostring(currentInvType) .. ", AF.currentInventoryType: " ..tostring(AF.currentInventoryType))
        --Check for custom added inventory filter button
        --CraftBag
        if invType == INVENTORY_CRAFT_BAG then
            local afCBCurrentFilter = AF.craftBagCurrentFilter
            if AF.settings.debugSpam then d("[AF]ShowSubfilterBar craftbag, currentFilter: " .. tostring(currentFilter) .. ", afCBCurrentFilter: " .. tostring(afCBCurrentFilter)) end
            if afCBCurrentFilter and afCBCurrentFilter ~= ITEMFILTERTYPE_ALL and afCBCurrentFilter == currentFilter then
                --Set prevention variable for function ShowSubfilterBar at the craftbag.

                --Check if the currentFilter variable changed to 0 () now (Which happens if we opened the guild store after the craftbag, and reopening the craftbag now.
                --See issue 7 at AdvancedFilters github:  https://github.com/Randactyl/AdvancedFilters/issues/7
                local currentCBFilter = playerInvVar.inventories[INVENTORY_CRAFT_BAG].currentFilter
--d(">currentCBFilter: " .. tostring(currentCBFilter))
                if currentCBFilter == ITEMFILTERTYPE_ALL then
                    --The currentfilter reset, so we need to set it to the last known value again now
                    PLAYER_INVENTORY.inventories[INVENTORY_CRAFT_BAG].currentFilter = afCBCurrentFilter
                    currentFilter = afCBCurrentFilter
                end
            end
            currentFilterToUse = currentFilter
        elseif invType == LF_QUICKSLOT then
            --Quickslots
            --Get the currentFilter
            currentFilterToUse = util.GetInvTypeCurrentFilter(invType, currentFilter)
            if currentFilterToUse == nil then return end
        else
            --Is the filterType of the current menuBar button a custom addon filter function or filterType?
            currentFilterToUse = customInventoryFilterButtonsItemType or currentFilter
        end
        if craftingType == nil then craftingType = GetCraftingType() end
        if AF.settings.debugSpam then d("[AF]ShowSubfilterBar - currentFilter: " .. tostring(currentFilter) .. ", currentFilterToUse: " ..tostring(currentFilterToUse) .. ", craftingType: " .. tostring(craftingType) .. ", invType: " .. tostring(invType) .. ", customInventoryFilterButtonsItemType: " ..tostring(customInventoryFilterButtonsItemType)) end
        --[[
            --Guild store?
            if currentFilter == ITEMFILTERTYPE_TRADING_HOUSE then
    --d(">GuildStore itemfiltertype found!")
                --Set the "block inventory filter prehook" variable
                AF.blockOnInventoryFilterChangedPreHookForCraftBag = true
            else
    --d(">NO GuildStore itemfiltertype found!")
                AF.blockOnInventoryFilterChangedPreHookForCraftBag = false
            end
        ]]
        --Error handling: Hiding old subfilter bar
        -- e.g. for missing variables, or if other addons might have changed the currentFilter or currentInventoryType (indirectly by their stuff -> loadtime was increased -> filter change did not happen in time for AF due to this)
        local doDebugOutput = AF.settings.doDebugOutput
        local subfilterGroupMissingForInvType = false
        local subfilterBarMissing = false
        local notSupportedPanel = false
        if doDebugOutput then
            local showErrorInChat = false
            if invType == nil then
                showErrorInChat = true
            end
            if AF.subfilterGroups[invType] == nil then
                showErrorInChat = true
                subfilterGroupMissingForInvType = true
            end
            if currentFilterToUse == nil then
                showErrorInChat = true
            end
            if craftingType == nil then
                showErrorInChat = true
            end
            local subFilterBarName
            if invType ~= nil and craftingType ~= nil and currentFilterToUse ~= nil then
                local nextSubfilterBar = AF.subfilterGroups[invType][craftingType][currentFilterToUse]
                if nextSubfilterBar == nil then
                    subfilterBarMissing = true
                    showErrorInChat = true
                    subFilterBarName = "N/A"
                else
                    subFilterBarName = nextSubfilterBar.name
                end
            end
            --Check if any not supported panel is given and do not show a message in chat then
            local notSupportedPanels = AF.notSupportedPanels
            local notSupportedPanelForCrafting = notSupportedPanels[craftingType]
            if notSupportedPanelForCrafting then
                if craftingType ~= CRAFTING_TYPE_NONE then
                    --Check which crafting it is and get the current crafting's mode variable/state
                    local modeVar
                    if craftingType == CRAFTING_TYPE_ENCHANTING then
                        modeVar = enchantingVar.enchantingMode
                    elseif craftingType == CRAFTING_TYPE_BLACKSMITHING or craftingType == CRAFTING_TYPE_CLOTHIER or craftingType == CRAFTING_TYPE_WOODWORKING then
                        modeVar = smithingVar.mode
                    end
                    if modeVar ~= nil then
                        if notSupportedPanelForCrafting[modeVar] == true then
                            notSupportedPanel = true
                        end
                    end
                end
            end
            --Show a debug message now and abort here?
            if showErrorInChat and AF.subFiltersBarInactive[currentFilterToUse] == nil and notSupportedPanel == false then
                showChatDebug("ShowSubfilterBar - BEGIN", "InventoryType: " ..tostring(invType) .. ", craftingType: " ..tostring(craftingType) .. "/" .. util.GetCraftingType() .. ", currentFilter: " .. tostring(currentFilterToUse) .. ", subFilterGroupMissing: " ..tostring(subfilterGroupMissingForInvType) .. ", subfilterBarMissing: " ..tostring(subfilterBarMissing) .. ", subfilterBarName: " ..tostring(subFilterBarName))
                return false
            end
        end

        --Get the old subfilterbar + the new subfilterbar group data
        local subfilterGroup = AF.subfilterGroups[invType]
        --hide old bar, if it exists
        if subfilterGroup.currentSubfilterBar ~= nil then
            subfilterGroup.currentSubfilterBar:SetHidden(true)
        end
        --hide old bar at same parent
        hideSubfilterBarSameParent(invType)
        --Old subfilterbar(s) was(were) hidden, so check if a new one should be shown now
        if CheckIfNoSubfilterBarShouldBeShown(currentFilterToUse, invType) then
            if AF.settings.debugSpam then d("<<ABORT: CheckIfNoSubfilterBarShouldBeShown: true") end
            return
        end
        --do nothing if we're in a guild store and regular filters are disabled.
        --LibCommonInventoryFilters is not used anymore!
        --[[
        if not ZO_TradingHouse:IsHidden() and (util.libCIF and util.libCIF._guildStoreSellFiltersDisabled) then
            if AF.settings.debugSpam then d("<<ABORT: Trading house libCIF:guildSToreSellFiltersDisabled!") end
            return
        end
        ]]

        --Get the new subFilterBar to show
        local subfilterBarBase = subfilterGroup[craftingType]
        if subfilterBarBase == nil then
            showChatDebug("ShowSubfilterBar - SubFilterBarBase missing", "InventoryType: " ..tostring(invType) .. ", craftingType: " ..tostring(craftingType) .. "/" .. util.GetCraftingType() .. ", currentFilter: " .. tostring(currentFilterToUse) .. ", subFilterGroupMissing: " ..tostring(subfilterGroupMissingForInvType) .. ", subfilterBarMissing: " ..tostring(subfilterBarMissing))
            return
        end
        local subfilterBar = subfilterBarBase[currentFilterToUse]
        if subfilterBar == nil and AF.subFiltersBarInactive[currentFilterToUse] == nil then
            --SubfilterBar is nil but maybe we do not need any here at teh given inventory & curerntFilter?
            if currentFilterToUse ~= nil and AF.subFiltersBarInactive[currentFilterToUse] == nil then
                showChatDebug("ShowSubfilterBar - SubFilterBar missing", "InventoryType: " ..tostring(invType) .. ", craftingType: " ..tostring(craftingType) .. "/" .. util.GetCraftingType() .. ", currentFilter: " .. tostring(currentFilterToUse) .. ", subFilterGroupMissing: " ..tostring(subfilterGroupMissingForInvType) .. ", subfilterBarMissing: " ..tostring(subfilterBarMissing))
                return
            end
        end

        --if new bar exists
        local craftingInv
        local isCraftingInventoryType = false
        local subFilterBarHeight
        if subfilterBar then
            local isCraftingPanel = IsCraftingPanelShown()
            if AF.settings.debugSpam then d(">>New subfilterBar was found, isCraftingPanel: " ..tostring(isCraftingPanel)) end
            --Crafting
            if isCraftingPanel == true then
                isCraftingInventoryType = IsCraftingStationInventoryType(subfilterBar.inventoryType)
                if isCraftingInventoryType then
                    craftingInv = GetInventoryFromCraftingPanel(subfilterBar.inventoryType)
                end
            end
            --set current bar reference
            subfilterGroup.currentSubfilterBar = subfilterBar
            if AF.settings.debugSpam then d(">subfilterBar exists, name: " .. tostring(subfilterBar.control:GetName()) .. ",  inventoryType: " ..tostring(subfilterBar.inventoryType)) end
            --Update the currentFilter to the current inventory
            UpdateCurrentFilter(subfilterBar.inventoryType, currentFilter, isCraftingInventoryType, craftingInv, currentFilterToUse)

            --For debugging
            AF.currentSubfilterBar = subfilterBar

--d(">>>subfilterBar.inventoryType: " ..tostring(subfilterBar.inventoryType))
            --activate current subfilter bar's button -> Will also update the filter dropdown box!
            subfilterBar:ActivateButton(subfilterBar:GetCurrentButton())
            --show the new subfilter bar
            subfilterBar:SetHidden(false)
            subFilterBarHeight = subfilterBar.control:GetHeight()
            --set proper inventory anchor displacement
            if subfilterBar.inventoryType == INVENTORY_TYPE_VENDOR_BUY then
                UpdateListAnchors(STORE_WINDOW, subFilterBarHeight, subfilterBar, false)
            elseif invType == LF_QUICKSLOT then
                UpdateListAnchors(quickslotVar, 0, nil, false)
            elseif isCraftingInventoryType then
                UpdateListAnchors(craftingInv, subFilterBarHeight, subfilterBar, isCraftingInventoryType)
            else
                UpdateListAnchors(playerInvVar, subFilterBarHeight, subfilterBar, isCraftingInventoryType)
            end
        else
            --Crafting
            if IsCraftingPanelShown() then
                isCraftingInventoryType = IsCraftingStationInventoryType(invType)
                if isCraftingInventoryType then
                    craftingInv = GetInventoryFromCraftingPanel(invType)
                end
            end
            if AF.settings.debugSpam then d(">>New subfilterBar was NOT found, isCraftingPanel: " ..tostring(IsCraftingPanelShown())) end
            --Update the currentfilter to the inventory so it will be the correct one (e.g. if you change after this "return false" below to the CraftBag and back to the inventory,
            --the currentFilter will be the wrong one from before, and thus the subfilterbar of the before filter wil be shown at this currentFilter).
            --Update the currentFilter to the current inventory
            UpdateCurrentFilter(invType, currentFilter, isCraftingInventoryType, craftingInv, currentFilterToUse)
            --remove all filters
            util.RemoveAllFilters()
            --set original inventory anchor displacement
            if invType == INVENTORY_TYPE_VENDOR_BUY then
                UpdateListAnchors(STORE_WINDOW, 0, nil, false)
            elseif invType == LF_QUICKSLOT then
                UpdateListAnchors(quickslotVar, 0, nil, false)
            elseif isCraftingInventoryType then
                UpdateListAnchors(craftingInv, 0, nil, true)
            else
                UpdateListAnchors(playerInvVar, 0, nil, false)
            end
            --remove current bar reference
            subfilterGroup.currentSubfilterBar = nil
            --Error handling: Showing new subfilter bar
            if doDebugOutput then
                if (currentFilterToUse == nil or (currentFilterToUse ~= nil and AF.subFiltersBarInactive[currentFilterToUse] == nil)) and notSupportedPanel == false then
                    showChatDebug("ShowSubfilterBar - END", "InventoryType: " ..tostring(invType) .. ", craftingType: " ..tostring(craftingType) .. "/" .. util.GetCraftingType() .. ", currentFilter: " .. tostring(currentFilterToUse))
                end
            end
        end
        --Reanchor the checkbox "Include banked items" at the crafting panels
        if isCraftingInventoryType then
            subFilterBarHeight = (subfilterBar and subfilterBar.control:GetHeight()) or 50
            reAnchorIncludeBankedItemsCheckbox(nil, subFilterBarHeight)
        end

    end -- function "ShowSubfilterBar"


    --=== FRAGMENTS=========================================================================================================
    --FRAGMENT HOOKS
    local function hookFragment(fragment, inventoryType)
        local function onFragmentShowing(p_fragment)
--d("[AF]OnFragmentShowing - inventoryType: " ..tostring(inventoryType) .. ", invTypeOverride: " ..tostring(AF.currentInventoryTypeOverride))
            local doNormalChecks = true
            local inventoryControl
            local inventoryTypeUpdated
            --Special treatment for qucisklots
            if p_fragment == QUICKSLOT_FRAGMENT and inventoryType == LF_QUICKSLOT then
--d(">quickslots")
                doNormalChecks = false
                AF.currentInventoryTypeOverride = nil
                AF.currentInventoryType = LF_QUICKSLOT
                inventoryControl = quickslotVar.container
                inventoryTypeUpdated = LF_QUICKSLOT
                ThrottledUpdate("ShowSubfilterBar_Quickslots", 20, ShowSubfilterBar, quickslotVar.currentFilter, nil, nil, LF_QUICKSLOT)
            end
            if doNormalChecks == true then
                --AF.currentInventoryTypeOverride will be set if the inventory's quest item tab was opened before the
                --inventory fragment get's hidden. AF.currentInventoryCurrentFilter will be ITEM_TYPE_DISPLAY_CATEGORY_QUEST
                --(8) in that case!
                --But do not override the inventoryType if the mail send/player trade panels open as they do not own a quest
                --item inventory tab!
                if inventoryType == INVENTORY_BACKPACK and
                        AF.currentInventoryTypeOverride and AF.currentInventoryTypeOverride == INVENTORY_QUEST_ITEM then
                    local sceneNames = AF.scenesForChecks
                    --Check if mail send or player trade are shown
                    local libFiltersPanelId = util.LibFilters:GetCurrentFilterTypeForInventory(inventoryType)
d(">libFiltersPanelId: " ..tostring(libFiltersPanelId))
                    if ((libFiltersPanelId and (libFiltersPanelId == LF_MAIL_SEND or libFiltersPanelId == LF_TRADE or
                                libFiltersPanelId == LF_BANK_DEPOSIT or libFiltersPanelId == LF_GUILDBANK_DEPOSIT or
                                libFiltersPanelId == LF_GUILDSTORE_SELL or
                                libFiltersPanelId == LF_FENCE_SELL or libFiltersPanelId == LF_FENCE_LAUNDER )) or
                                (MAIL_SEND.control and not MAIL_SEND.control:IsHidden()) or
                                (TRADE.control and not TRADE.control:IsHidden()) or
                                util.IsSceneShown(sceneNames.bank) or
                                util.IsSceneShown(sceneNames.guildBank) or
                                util.IsSceneShown(sceneNames.tradinghouse) or
                                (TRADING_HOUSE.currentMode == ZO_TRADING_HOUSE_MODE_SELL or (TRADING_HOUSE.control and not TRADING_HOUSE.control:IsHidden())) or
                                util.IsSceneShown(sceneNames.fence)
                            )
                    then
                        AF.currentInventoryTypeOverride = nil
d("<<Deleted: AF.currentInventoryTypeOverrid")
                    end
                end
                local currentInventoryTypeOverride = AF.currentInventoryTypeOverride
                AF.currentInventoryType = currentInventoryTypeOverride
                if AF.currentInventoryType == nil then AF.currentInventoryType = inventoryType end
--d("!!!!!!!!!!!!!!!!!!!!AF.currentInvType = " ..tostring(AF.currentInventoryType) .. " / invType: " ..tostring(inventoryType).. "/override: " ..tostring(currentInventoryTypeOverride))
                inventoryTypeUpdated = currentInventoryTypeOverride or inventoryType
                AF.currentInventoryTypeOverride = nil

                if inventoryType == INVENTORY_TYPE_VENDOR_BUY then
                    --Check if currentFilter is a function and then try to resolve the real filtervalue below it
                    local customInventoryFilterButtonsItemType = util.CheckForCustomInventoryFilterBarButton(AF.currentInventoryType, STORE_WINDOW.currentFilter)
                    if customInventoryFilterButtonsItemType then
                        if AF.settings.debugSpam then d("[AF]ChangeFilterCrafting-Found custom inventory: " .. tostring(customInventoryFilterButtonsItemType)) end
                    end
                    ThrottledUpdate("ShowSubfilterBar_" .. inventoryType, 10,
                            ShowSubfilterBar, STORE_WINDOW.currentFilter, nil, customInventoryFilterButtonsItemType)

                    inventoryControl = STORE_WINDOW.control
                else
                    -- fragmentType = "Inv"
                    local currentFilter = playerInvVar.inventories[inventoryTypeUpdated].currentFilter
--d(">>>>>>>currentFilter: " ..tostring(currentFilter) .. "; inventoryTypeUpdated: " ..tostring(inventoryTypeUpdated))
                    if inventoryTypeUpdated == INVENTORY_BACKPACK or inventoryTypeUpdated == INVENTORY_QUEST_ITEM then
                        --Ist the currentFilter the quest tab? Then change the currentInventory variable!
                        if currentFilter and currentFilter == ITEM_TYPE_DISPLAY_CATEGORY_QUEST then
                            AF.currentInventoryType = INVENTORY_QUEST_ITEM
                            inventoryTypeUpdated = INVENTORY_QUEST_ITEM
--d("!!!!!!!!!!!!!!!QUEST - AF.currentInvType = " ..tostring(AF.currentInventoryType))
                        end
                    end

                    --CraftBag
                    --if inventoryType == INVENTORY_CRAFT_BAG then
                    --local currentCBFilter = playerInvVar.inventories[INVENTORY_CRAFT_BAG].currentFilter
                    --local afCBCurrentFilter = AF.craftBagCurrentFilter
                    --d("[AF]CraftBag fragment showing, currentFilter: " .. tostring(currentCBFilter) .. ", afCBCurrentFilter: " .. tostring(afCBCurrentFilter))
                    --fragmentType = "CraftBag"
                    --end
                    if AF.settings.debugSpam then
                        d("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>")
                        d("[AF]hookFragment " .. tostring(fragment.control:GetName()) .. " - fragment OnShow -> ShowSubfilterBar")
                    end
                    --Check if currentFilter is a function and then try to resolve the real filtervalue below it
                    local customInventoryFilterButtonsItemType = util.CheckForCustomInventoryFilterBarButton(AF.currentInventoryType, currentFilter)
                    if customInventoryFilterButtonsItemType then
                        if AF.settings.debugSpam then d("[AF]ChangeFilterCrafting-Found custom inventory: " .. tostring(customInventoryFilterButtonsItemType)) end
                    end
--d(">>>ThrottledUpdate -> ShowSubfilterBar_"..tostring(inventoryTypeUpdated))
                    ThrottledUpdate("ShowSubfilterBar_" .. inventoryTypeUpdated, 20, ShowSubfilterBar, currentFilter, nil, customInventoryFilterButtonsItemType)

                    inventoryControl = playerInvVar.inventories[inventoryTypeUpdated].filterBar:GetParent()
                end
            end
            --Call RefreshSubfilterBar via "proxy" metatable function on the inventoryType
            if AF.settings.debugSpam then d("---------->Calling RefreshSubfilterBar via 'proxy' function") end
            PLAYER_INVENTORY.isListDirty = track(playerInvVar.isListDirty)

            if inventoryControl then
                --For debugging
                AF.currentInventoryControl = inventoryControl

                --Hide and move some controls like subfilter bar divider lines etc.
                reanchorAndHideVanillaUIControls(inventoryControl)
            end

            --Was anything else opened before a bank was opened?
            --Workaround to supress 2x Inventory ChangeFilter as the inventoryType detected would be the normal inv and
            --not the bank -> error messages occur
            if firstOpened == nil then
--d(">>>>FirstOpened is set")
                firstOpened = inventoryTypeUpdated
                local bankInvTypes = AF.bankInvTypes
                --Check if current inventory is a bank withdraw panel
                local isBankInvType = bankInvTypes[inventoryTypeUpdated] or false
                if isBankInvType then
--d(">>>>>>FirstOpenedIsBank: true")
                    firstOpenedIsBank = true
                end
            end
        end

        local function onFragmentShown(p_fragment)
            --[[
                local invType = AF.currentInventoryType
                local filterType = util.GetCurrentFilterTypeForInventory(invType)
                d("[AF]OnFragmentShown - inventoryType: " ..tostring(invType) .. ", filterType: " ..tostring(filterType))
            ]]
--d("[AF]OnFragmentShown")
            --Not called in OnFragmentShowing as it would be too early. The controls would just be unhidden
            util.HideInventoryControls(nil)
        end

        local function onFragmentHiding(p_fragment)
            PLAYER_INVENTORY.isListDirty = untrack(playerInvVar.isListDirty)
            --CraftBag
            if inventoryType == INVENTORY_CRAFT_BAG then
                AF.craftBagCurrentFilter = playerInvVar.inventories[INVENTORY_CRAFT_BAG].currentFilter
                if AF.settings.debugSpam then d("[AF]CraftBag fragment hiding, currentFilter: " .. tostring(AF.craftBagCurrentFilter)) end
            end
            --Reset the current inventory type to the normal inventory, or the quest (depending on the currentFilter before craftbag was opened)
            AF.currentInventoryTypeOverride = nil
            if AF.currentInventoryCurrentFilter and AF.currentInventoryCurrentFilter == ITEM_TYPE_DISPLAY_CATEGORY_QUEST then
                AF.currentInventoryTypeOverride = INVENTORY_QUEST_ITEM
                AF.currentInventoryType = INVENTORY_QUEST_ITEM
            else
                AF.currentInventoryType = INVENTORY_BACKPACK
            end
--d("!!!!!!!!!!!!!!!Fagment hide - AF.currentInvType = " ..tostring(AF.currentInventoryType) .. ", currentFilter: " ..tostring(AF.currentInventoryCurrentFilter))
        end

        local function onFragmentStateChange(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                AF.fragmentStateHiding[inventoryType] = false
                onFragmentShowing(fragment)
            elseif newState == SCENE_FRAGMENT_SHOWN then
                onFragmentShown(fragment)
            elseif newState == SCENE_FRAGMENT_HIDING then
                AF.fragmentStateHiding[inventoryType] = true
                onFragmentHiding(fragment)
            end
        end
        fragment:RegisterCallback("StateChange", onFragmentStateChange)
    end

    hookFragment(INVENTORY_FRAGMENT, INVENTORY_BACKPACK)
    hookFragment(BANK_FRAGMENT, INVENTORY_BANK)
    hookFragment(HOUSE_BANK_FRAGMENT, INVENTORY_HOUSE_BANK)
    hookFragment(GUILD_BANK_FRAGMENT, INVENTORY_GUILD_BANK) -- new value is: 5
    hookFragment(CRAFT_BAG_FRAGMENT, INVENTORY_CRAFT_BAG) -- new value is: 6
    --hookFragment(STORE_FRAGMENT, INVENTORY_TYPE_VENDOR_BUY)
    hookFragment(QUICKSLOT_FRAGMENT, LF_QUICKSLOT)


    --=== SCENES ===========================================================================================================
    --Hook some scenes to register variables as the scenes show/hide.
    -->Needed to prevent function playerInvVar:ChangeFilter to reset the internal
    -->variables to the normal inventory, if you had the CraftBag opened last in the normal inventory.
    -->See github, issue 7:   https://github.com/Randactyl/AdvancedFilters/issues/7
    local function hookScene(scene, filterPanelId)
        local function onSceneShowing(p_scene)
            if AF.settings.debugSpam then
                d("???????????????????????????????????????????????>>>")
                d("[AF]Scene showing: " .. tostring(SCENE_MANAGER.currentScene.name))
            end
            --Retrait
            if  filterPanelId == LF_RETRAIT then
                AF.currentInventoryType = LF_RETRAIT
            end
            --Mail Send
            if p_scene == MAIL_SEND_SCENE then
                AF.currentInventoryTypeOverride = nil
            end
        end
        --[[
            local function onSceneShown()
            end
        ]]
        local function onSceneHiding(p_scene)
            if AF.settings.debugSpam then
                d("<<<???????????????????????????????????????????????")
                d("[AF]Scene hiding: " .. tostring(SCENE_MANAGER.currentScene.name))
            end
            if filterPanelId then
                if      filterPanelId == LF_MAIL_SEND then
                    --d(">Mail send scene closing!")
                    --Set the "block inventory filter prehook" variable
                    AF.blockOnInventoryFilterChangedPreHookForCraftBag = true
                elseif  filterPanelId == LF_GUILDSTORE_BROWSE or LF_GUILDSTORE_SELL then
                    --d(">GuildStore scene closing!")
                    --Set the "block inventory filter prehook" variable
                    AF.blockOnInventoryFilterChangedPreHookForCraftBag = true
                    --Retrait
                elseif  filterPanelId == LF_RETRAIT then
                    --Reset inventory type to normal backpack
                    AF.currentInventoryType = INVENTORY_BACKPACK
                end
            end
        end

        local function onSceneStateChange(oldState, newState)
            if newState == SCENE_HIDING then
                onSceneHiding(scene)
                --elseif newState == SCENE_SHOWN then
                --onSceneShown()
            elseif newState == SCENE_SHOWING then
                onSceneShowing(scene)
            end
        end
        scene:RegisterCallback("StateChange", onSceneStateChange)
    end

    hookScene(MAIL_SEND_SCENE, LF_MAIL_SEND)
    hookScene(TRADING_HOUSE_SCENE, LF_GUILDSTORE_BROWSE)
    hookScene(KEYBOARD_RETRAIT_ROOT_SCENE , LF_RETRAIT)
    --Vendor, for CraftBagExtended addon as well?


    --=== INVENTORY / BANK / GUILDBANK / HOUSEBANK / GUILDSTORE SELL =======================================================
    --Filter changing function for normal inventories
    --Recognizes if a button like armor/weapons/material/... was changed at the inventory (which is a filter change internally)
    local function ChangeFilterInventory(self, filterTab)
        AF.currentInventoryTypeOverride = nil
        --self: playerInvVar, filterTab: playerInvVar.filterTab
        local tabInvType = filterTab.inventoryType
        --Was anything else opened before a bank was opened?
        --if not: Supress 2x changefilter as it will be the normal inventory changefilter (Why ever this happens!) and not the Bank ones
        if firstOpened ~= nil then
            if firstOpenedIsBank == true then
d("<<ChangeFilterInventory aborted due to bank was first opened!")
                changeFilterCallsAfterFirstOpenWasBank = changeFilterCallsAfterFirstOpenWasBank +1
                if changeFilterCallsAfterFirstOpenWasBank <= 2 then
                    return
                else
                    firstOpenedIsBank = false
                end
            end
        end
        --Special treatment for the "quest" filtertab at the player inventory. The scene says it's inventorytype 1, but
        --the quest button changes it to 2. So the invtype was used from the INVENTORY_FRAGMENT hook before!
        -->Now as the quest tab is supported switch it to the normal tab's inventory again
        --local currentInvType = AF.currentInventoryType
        local currentInvType = tabInvType
        AF.currentInventoryType = currentInvType
        --Is the bank opened but the current filterType is 0 then check if another currentFilter was set as the bank was closed last time
        --and reset the subfilter bar to the last chosen one now. Therefor the currentFilter needs to be changed to the correct "last" one again:
        local currentFilter = checkIfBankLastCurrentFilterIsGiven(self, filterTab)
        if currentInvType == INVENTORY_BACKPACK or currentInvType == INVENTORY_QUEST_ITEM then
            AF.currentInventoryCurrentFilter = currentFilter
        end
d("!!!!!!!!!!!!!!CHANGEFILTER AF.currentInvType = " ..tostring(AF.currentInventoryType) .. ", currentFilter: " ..tostring(AF.currentInventoryCurrentFilter))

        if AF.settings.debugSpam then
            d("===========================================================================================================>")
            d("[AF]playerInvVar:ChangeFilter, tabInvType: " ..tostring(tabInvType) .. ", curInvType: " .. tostring(currentInvType) .. ", currentFilter: " .. tostring(currentFilter))
        end
        --CraftBag
        if currentInvType == INVENTORY_CRAFT_BAG and AF.blockOnInventoryFilterChangedPreHookForCraftBag then
            if AF.settings.debugSpam then d("<<ABORT: CraftBag: PreHook is blocked!") end
            AF.blockOnInventoryFilterChangedPreHookForCraftBag = false
            return false
        end
        --Check if currentFilter is a function and then try to resolve the real filtervalue below it
        local customInventoryFilterButtonsItemType = util.CheckForCustomInventoryFilterBarButton(currentInvType, currentFilter)
        if customInventoryFilterButtonsItemType then
            if AF.settings.debugSpam then d("[AF]ChangeFilterInventory-Found custom inventory: " .. tostring(customInventoryFilterButtonsItemType)) end
        end
        --[[
        --Causes bug with #28
        #28 2020-06-30, FooWasHere: Talk to vendor for woodworking, sell tab, change filter from ALL to "Weapons". Leave the woodworking vendor. Open any other vendor where there is NO
        --                            Weapons subfilter given: Only weapons subfilterbar is shown and everything else is hidden, including items
        local doNotUpdateInventoriesWithInventoryChangeFilterFunction = AF.doNotUpdateInventoriesWithInventoryChangeFilterFunction
        local shouldNotUpdateWithInventoryChangeFilterFunc = doNotUpdateInventoriesWithInventoryChangeFilterFunction[currentInvType] or false
        if not shouldNotUpdateWithInventoryChangeFilterFunc then
        ]]
d(">>ThrottledUpdate - ChangeFilterInventory, currentInvType: " ..tostring(currentInvType))
        ThrottledUpdate("ShowSubfilterBar_" .. currentInvType, 20, ShowSubfilterBar, currentFilter, nil, customInventoryFilterButtonsItemType, currentInvType)
        --end
        --Update the total count for items as there are no epxlicit filterBars available until today at the panels, e.g. custom added
        --inventory filters like HarvensStolenFilter or NTakLootAndSteal addons
        local currentFilterToCheck = customInventoryFilterButtonsItemType or currentFilter
        local inactiveSubFilterBarInventoryType = AF.subFiltersBarInactive[currentFilterToCheck] or nil
        if inactiveSubFilterBarInventoryType ~= nil and inactiveSubFilterBarInventoryType ~= false then
d(">inactiveSubFilterBarInventoryType: " ..tostring(inactiveSubFilterBarInventoryType) .. ", curInvType: " .. tostring(currentInvType) .. ", tabInvType: " ..tostring(tabInvType) .. ", currentFilterToCheck: " ..tostring(currentFilterToCheck))
            if AF.settings.debugSpam then d(">inactiveSubFilterBarInventoryType: " ..tostring(inactiveSubFilterBarInventoryType) .. ", curInvType: " .. tostring(currentInvType) .. ", tabInvType: " ..tostring(tabInvType) .. ", currentFilterToCheck: " ..tostring(currentFilterToCheck)) end
            --Compare the inventory tab's inventoryType with the inactive inventoryType, and
            --set the inventory to update accordingly
            local invType
            if tabInvType == inactiveSubFilterBarInventoryType then
                invType = inactiveSubFilterBarInventoryType
            else
                invType = currentInvType
            end
            --Update the count of filtered/shown items in the inventory FreeSlot label
            --Delay this function call as the data needs to be filtered first!
            ThrottledUpdate("RefreshItemCount_" .. invType,
                    50, util.updateInventoryInfoBarCountLabel, invType, false)
        end
    end
    -->Throws error message if you open inventory after reloadui:
    SecurePostHook(playerInvVar, "ChangeFilter", ChangeFilterInventory)


    --=== QUICKLOT =========================================================================================================
    --PreHook the QuickSlotWindow change filter function
    local function ChangeFilterQuickSlot(self, filterData)
--d("[AF]ChangeFilterQuickSlot")
        AF.currentInventoryType = LF_QUICKSLOT
        ThrottledUpdate("ShowSubfilterBar_Quickslots", 20, ShowSubfilterBar, self.currentFilter, nil, nil, LF_QUICKSLOT)

        ThrottledUpdate("RefreshItemCount_Quickslots", 50, quickslotVar.UpdateFreeSlots, quickslotVar)
    end
    SecurePostHook(quickslotVar, "ChangeFilter", ChangeFilterQuickSlot)

    --[[
            Attempt to call a nil value
        stack traceback:
        [C]: in function 'PostHookFunction'
        EsoUI/Ingame/Inventory/Inventory.lua:44: in function 'HandleTabSwitch'
        |caaaaaa<Locals> tabData = [table:1]{filterType = 1, highlight = "EsoUI/Art/Inventory/inventory_...", activeTabText = "Waffen", ignoreVisibleCheck = F, inventoryType = 1, tooltipText = "Waffen", pressed = "EsoUI/Art/Inventory/inventory_...", normal = "EsoUI/Art/Inventory/inventory_...", descriptor = 1} </Locals>|r
        EsoUI/Libraries/ZO_MenuBar/ZO_MenuBar.lua:284: in function 'MenuBarButton:Release'
        |caaaaaa<Locals> self = [table:2]{m_locked = T, m_highlightHidden = F, m_state = 1}, upInside = T, skipAnimation = F, playerDriven = T, buttonData = [table:1] </Locals>|r
        EsoUI/Libraries/ZO_MenuBar/ZO_MenuBar.lua:636: in function 'ZO_MenuBarButtonTemplate_OnMouseUp'
        |caaaaaa<Locals> self = ud, button = 1, upInside = T </Locals>|r
        ZO_MainMenuCategoryBarButton1_MouseUp:3: in function '(main chunk)'
        |caaaaaa<Locals> self = ud, button = 1, upInside = T, ctrl = F, alt = F, shift = F, command = F </Locals>|r
    ]]
    --ZO_PreHook(playerInvVar, "ChangeFilter", ChangeFilterInventory)


    --=== VENDOR / STORE ===================================================================================================
    --  Store "BUY" changefilter function
    local function ChangeFilterVendor(self, filterTab)
        --d("[AF]ChangeFilterVendor")
        --AF._vendorFilterTab = filterTab
        local invType = INVENTORY_TYPE_VENDOR_BUY -- AF.currentInventoryType
        local currentFilter = filterTab.filterType

        if CheckIfNoSubfilterBarShouldBeShown(currentFilter) then return end

        ThrottledUpdate("ShowSubfilterBar_" .. tostring(invType), 10, ShowSubfilterBar, currentFilter)


        zo_callLater(function()
            local subfilterGroup = AF.subfilterGroups[invType]
            if not subfilterGroup then return end
            local craftingType = GetCraftingType()
            local currentSubfilterBar = subfilterGroup.currentSubfilterBar
            if not currentSubfilterBar then return end

            ThrottledUpdate("RefreshSubfilterBar_" .. invType .. "_" .. craftingType .. currentSubfilterBar.name, 10,
                    RefreshSubfilterBar, currentSubfilterBar)
        end, 25)

        --Update the count of filtered/shown items in the inventory FreeSlot label
        --Delay this function call as the data needs to be filtered first!
        --[[
        ThrottledUpdate("RefreshItemCount_" .. invType,
                50, util.updateInventoryInfoBarCountLabel, invType, false)
        ]]
    end
    --ZO_PreHook(STORE_WINDOW, "ChangeFilter", ChangeFilterVendor)


    --=== SMITHING =========================================================================================================
    --Hook the crafting station
    --SMITHING
    --Filter changing function for crafting stations and retrait station.
    --Recognizes if a button like armor/weapons was changed at the crafting station (which is a filter change internally)
    local function ChangeFilterCrafting(self, filterData)
        local invType = AF.currentInventoryType
        local craftingType = GetCraftingType()
        local filter = self.filterType or self.typeFilter
        local currentFilter = util.MapCraftingStationFilterType2ItemFilterType(filter, invType, craftingType)
        --Is the filterType of the current menuBar button a custom addon filter function or filterType?
        --Then try to resolve the real filtervalue below it
        local customInventoryFilterButtonsItemType = util.CheckForCustomInventoryFilterBarButton(invType, currentFilter)
        if customInventoryFilterButtonsItemType then
            if AF.settings.debugSpam then d("[AF]ChangeFilterCrafting-Found custom inventory: " .. tostring(customInventoryFilterButtonsItemType)) end
        end
        if AF.settings.debugSpam then
            d("=====================================================================>")
            d("[AF]ChangeFilterCrafting, invType: " .. tostring(invType) .. ", craftingType: " .. tostring(craftingType) .. ", filterType/typeFilter: " ..  tostring(filter) .. ", currentFilter: " .. tostring(currentFilter) .. ", customInventoryFilterButtonsItemType: " ..tostring(customInventoryFilterButtonsItemType))
        end
        --Old subfilterbar(s) was(were) hidden, so check if a new one should be shown now
        if CheckIfNoSubfilterBarShouldBeShown(currentFilter, invType, craftingType, filter) then return end

        --Update the subfilter bars
        ThrottledUpdate("ShowSubfilterBar_" .. invType .. "_" .. craftingType, 10,
                ShowSubfilterBar, currentFilter, craftingType, customInventoryFilterButtonsItemType)

        local subfilterGroup = AF.subfilterGroups[invType]
        if not subfilterGroup then return end
        zo_callLater(function()
            local currentSubfilterBar = subfilterGroup.currentSubfilterBar
            if not currentSubfilterBar then return end
            ThrottledUpdate("RefreshSubfilterBar_" .. invType .. "_" .. craftingType .. currentSubfilterBar.name, 10,
                    RefreshSubfilterBar, currentSubfilterBar)
        end, 50)
    end

    local function HookSmithingSetMode(self, mode)
        --[[
            --Smithing modes
            SMITHING_MODE_ROOT = 0
            SMITHING_MODE_REFINMENT = 1
            SMITHING_MODE_CREATION = 2
            SMITHING_MODE_DECONSTRUCTION = 3
            SMITHING_MODE_IMPROVEMENT = 4
            SMITHING_MODE_RESEARCH = 5
            SMITHING_MODE_RECIPES = 6
        ]]
        local craftType = util.GetCraftingType()
        local isJewelryCrafting = (craftType == CRAFTING_TYPE_JEWELRYCRAFTING) or false
        if AF.settings.debugSpam then
            d("....................................................>")
            d("[AF]SMITHING:SetMode - mode: " ..tostring(mode) .. ", craftingType: " ..tostring(craftType))
        end
        if     mode == SMITHING_MODE_REFINEMENT then
            if isJewelryCrafting then
                AF.currentInventoryType = LF_JEWELRY_REFINE
            else
                AF.currentInventoryType = LF_SMITHING_REFINE
            end
        elseif     mode == SMITHING_MODE_CREATION then
            if isJewelryCrafting then
                AF.currentInventoryType = LF_JEWELRY_CREATION
            else
                AF.currentInventoryType = LF_SMITHING_CREATION
            end
        elseif     mode == SMITHING_MODE_DECONSTRUCTION then
            if isJewelryCrafting then
                AF.currentInventoryType = LF_JEWELRY_DECONSTRUCT
            else
                AF.currentInventoryType = LF_SMITHING_DECONSTRUCT
            end
        elseif mode == SMITHING_MODE_IMPROVEMENT then
            if isJewelryCrafting then
                AF.currentInventoryType = LF_JEWELRY_IMPROVEMENT
            else
                AF.currentInventoryType = LF_SMITHING_IMPROVEMENT
            end
        elseif mode == SMITHING_MODE_RESEARCH then
            if isJewelryCrafting then
                AF.currentInventoryType = LF_JEWELRY_RESEARCH
            else
                AF.currentInventoryType = LF_SMITHING_RESEARCH
            end
            --Show the subfilterbar for the research panel now as the function
            --"ChangeFilterCrafting(self, filterData)" will not be called automatically here
            util.ClearResearchPanelCustomFilters()
            ChangeFilterCrafting(self.researchPanel)
        end
        util.HideInventoryControls(nil)
        return false
    end

    --ZO_PreHook(smithingVar.creationPanel,                 "ChangeTypeFilter", changeFilterCraftingNew)
    ZO_PreHook(smithingVar.refinementPanel.inventory,       "ChangeFilter",     function(...) delayedCall(15, ChangeFilterCrafting, ...) end)
    ZO_PreHook(smithingVar.deconstructionPanel.inventory,   "ChangeFilter",     function(...) delayedCall(15, ChangeFilterCrafting, ...) end)
    ZO_PreHook(smithingVar.improvementPanel.inventory,      "ChangeFilter",     function(...) delayedCall(15, ChangeFilterCrafting, ...) end)
    ZO_PreHook(smithingVar.researchPanel,                   "ChangeTypeFilter", function(...) delayedCall(15, ChangeFilterCrafting, ...) end)

    SecurePostHook(smithingBaseVar, "SetMode", HookSmithingSetMode)


    --=== ENCHANTING =======================================================================================================
    local function ChangeFilterEnchanting(self, filterTab)
        zo_callLater(function()
            local invType = AF.currentInventoryType
            local craftingType = GetCraftingType()
            local currentFilter = util.MapCraftingStationFilterType2ItemFilterType(self.owner.enchantingMode, invType, craftingType)
            --Check if currentFilter is a function and then try to resolve the real filtervalue below it
            local customInventoryFilterButtonsItemType = util.CheckForCustomInventoryFilterBarButton(AF.currentInventoryType, currentFilter)
            if customInventoryFilterButtonsItemType then
                if AF.settings.debugSpam then d("[AF]ChangeFilterCrafting-Found custom inventory: " .. tostring(customInventoryFilterButtonsItemType)) end
            end
            if AF.settings.debugSpam then
                d("=====================================================================>")
                d("[AF]ChangeFilterEnchanting - currentFilter: " ..tostring(currentFilter) .. ", currentInventoryType: " .. tostring(invType) .. ", craftingType: " ..tostring(craftingType))
            end
            --Only show subfilters at the enchanting extraction panel
            ThrottledUpdate("ShowSubfilterBar_" .. invType .. "_" .. craftingType, 10,
                    ShowSubfilterBar, currentFilter, craftingType, customInventoryFilterButtonsItemType)
            zo_callLater(function()
                local subfilterGroup = AF.subfilterGroups[invType]
                if not subfilterGroup then return end
                local currentSubfilterBar = subfilterGroup.currentSubfilterBar
                if not currentSubfilterBar then return end
                ThrottledUpdate("RefreshSubfilterBar_" .. invType .. "_" .. craftingType .. currentSubfilterBar.name, 10,
                        RefreshSubfilterBar, currentSubfilterBar)
            end, 50)
        end, 10) -- called with small delay, otherwise self.filterType is nil
    end

    --ZO_Enchanting.enchantingMode update function
    local function HookEnchantingOnModeUpdated(self, mode)
        if AF.settings.debugSpam then
            d("....................................................>")
            d("[AF]ENCHANTING:OnModeUpdated, enchantingMode: " .. tostring(mode))
        end
        --[[
            --Enchanting modes
            ENCHANTING_MODE_CREATION = 1
            ENCHANTING_MODE_EXTRACTION = 2
            ENCHANTING_MODE_RECIPES = 3
            ENCHANTING_MODE_NONE = 0
        ]]
        if     mode == ENCHANTING_MODE_CREATION then
            AF.currentInventoryType = LF_ENCHANTING_CREATION
        elseif mode == ENCHANTING_MODE_EXTRACTION then
            AF.currentInventoryType = LF_ENCHANTING_EXTRACTION
        end
        util.HideInventoryControls(nil)
        return false
    end
    --Multicraft addon breaks this addon! Disable it before you can use AdvancedFilters
    if AF.otherAddons["MultiCraft"] or MultiCraft ~= nil then
        local strings = AF.strings
        showChatDebug("PostHook ZO_Enchanting OnModeUpdated -> " .. strings.errorOtherAddonsMulticraft, strings.errorOtherAddonsMulticraftLong)
        return
    end

    --Special hooks needed if other addons like CraftStore are enabled
    --CraftStore addon is enabled?
    if CS then
        local enchantingCreateButtonCS    = CraftStoreFixed_RuneCreateButton --Create
        local enchantingExtractButtonCS   = CraftStoreFixed_RuneRefineButton --Extract
        --local enchantingFurnitureButtonCS = CraftStoreFixed_RuneFurnitureButton --Recipes
        local function enchantingMenuBarButtonClicked(ctrl, mouseButton, upInside, enchantingMode)
            --CraftStore addon is enabled?
            if not CS then return end
            if ctrl and mouseButton ~= MOUSE_BUTTON_INDEX_RIGHT and upInside == true and enchantingMode then
                local csAccountSettings = CS.Account.options
                if not csAccountSettings or not csAccountSettings.userune then return end
                local enchantingModeToCSRuneSetting = {
                    [ENCHANTING_MODE_CREATION] 		= csAccountSettings.userunecreation,
                    [ENCHANTING_MODE_EXTRACTION] 	= csAccountSettings.useruneextraction,
                    [ENCHANTING_MODE_RECIPES] 		= csAccountSettings.userunerecipe,
                }
                local csRuneSettingState = enchantingModeToCSRuneSetting[enchantingMode] or false
                --The current panel does NOT use the CraftStore rune UI but the vanilla UI?
                if csRuneSettingState == false then
                    --Call the ENCHANTING.enchantingMode update procedures via the function "ChangeFilterEnchanting" as if the inventory filter was changed
                    enchantingVar.enchantingMode = enchantingMode
                    HookEnchantingOnModeUpdated(enchantingBaseVar, enchantingMode)
                    ChangeFilterEnchanting(enchantingVar.inventory, nil)
                end
            end
        end
        ZO_PreHookHandler(enchantingCreateButtonCS,       "OnMouseUp", function(ctrl, mouseButton, upInside, ...) enchantingMenuBarButtonClicked(ctrl, mouseButton, upInside, ENCHANTING_MODE_CREATION) end)
        ZO_PreHookHandler(enchantingExtractButtonCS,      "OnMouseUp", function(ctrl, mouseButton, upInside, ...) enchantingMenuBarButtonClicked(ctrl, mouseButton, upInside, ENCHANTING_MODE_EXTRACTION) end)
        --ZO_PreHookHandler(enchantingFurnitureButtonCS,    "OnMouseUp", function(ctrl, mouseButton, upInside, ...) enchantingMenuBarButtonClicked(ctrl, mouseButton, upInside, ENCHANTING_MODE_RECIPES) end)
    end

    --ENCHANTING
    ZO_PreHook(enchantingVar.inventory, "ChangeFilter", ChangeFilterEnchanting)

    --> See function HookEnchantingOnModeUpdated above at the filter changes (needed there as well already for CraftStoreFixedAndImproved fixes!)
    SecurePostHook(enchantingBaseVar, "OnModeUpdated", function(self) HookEnchantingOnModeUpdated(self, self.enchantingMode) end)


    --=== RETRAIT ==========================================================================================================
    --Retrait
    -->Currently not working via PostHook as SetMode is not called! One needs to use the scene callback for "StateChange" (see further up!)
    local function HookRetraitSetMode(self, mode)
        if AF.settings.debugSpam then
            d("....................................................>")
            d("[AF]ZO_RetraitStation_Keyboard.SetMode - mode: " ..tostring(mode))
        end
        --[[
            --Retrait modes
            ZO_RETRAIT_MODE_ROOT        = 0
            ZO_RETRAIT_MODE_RETRAIT     = 1
        ]]
        --Get the current filterType at the retrait station
        if     mode == ZO_RETRAIT_MODE_RETRAIT  then
            --Retrait
            AF.currentInventoryType = LF_RETRAIT
            --elseif mode == ZO_RETRAIT_MODE_RECONSTRUCT then
            --Reconstruction -- Not supported!
            --AF.currentInventoryType = LF_RECONSTRUCTION
        end
        return false
    end
    --ZO_PreHook(ZO_RetraitStation_Keyboard, "SetMode", HookRetraitSetMode)
    --[[
    local origRetraitSetMode = ZO_RetraitStation_Keyboard.SetMode
    --Is currently (2019-03-11) not called! So we need to use the scene of the retrait station to set the inventory type variable for AF
    ZO_RetraitStation_Keyboard.SetMode = function(...)
        origRetraitSetMode(...)
        HookRetraitSetMode(...)
    end
    ]]
    ZO_PreHook(retraitVar.inventory,                        "ChangeFilter",     function(...) delayedCall(15, ChangeFilterCrafting, ...) end)

    SecurePostHook(retraitVar, "SetMode", HookRetraitSetMode)


    --=== INVENTORY - InfoBar, UpdateFreeSlots (auch QuickSlots) ===========================================================
    --Overwrite the standard inventory update function for the used slots/total slots
    local function hookInventoryInfoBar()
        --Callback function for ZO_InventoryManager:UpdateFreeSlots(inventoryType) -> Will be called with ThrottledUpdate to
        --prevent being run too often in short time
        local function ZO_InventoryManagerUpdateFreeSlotsCallback(self, inventoryType)
            if AF.settings.debugSpam then d("[AF]>>ZO_InventoryManagerUpdateFreeSlotsCallbacks, inventoryType: " ..tostring(inventoryType) .. ", infoBar: " ..tostring(self:GetContextualInfoBar():GetName())) end
            local inventory = self.inventories[inventoryType]
            local freeSlotType
            local altFreeSlotType
            local copyFreeSlotsInfoFromInv = INVENTORY_BACKPACK

            local cbeActive = (inventoryType == INVENTORY_CRAFT_BAG and CraftBagExtended ~= nil) or false
            --Quest/CraftBag (if addon CraftBagExtended is enabled only!) items "hack" to update the count label here too:
            -->Will use the normal inventory labels to show the output, but the itemCount from the related inventoryList
            if cbeActive or inventoryType == INVENTORY_QUEST_ITEM then
                inventory.freeSlotsLabel    = self.inventories[copyFreeSlotsInfoFromInv].freeSlotsLabel
                inventory.freeSlotType      = self.inventories[copyFreeSlotsInfoFromInv].freeSlotType
                inventory.altFreeSlotsLabel = self.inventories[copyFreeSlotsInfoFromInv].altFreeSlotsLabel
                inventory.altFreeSlotType   = self.inventories[copyFreeSlotsInfoFromInv].altFreeSlotType
            end
            if (type(inventory.freeSlotType) == "function") then
                freeSlotType = inventory.freeSlotType()
            else
                freeSlotType = inventory.freeSlotType
            end
            if (type(inventory.altFreeSlotType) == "function") then
                altFreeSlotType = inventory.altFreeSlotType()
            else
                altFreeSlotType = inventory.altFreeSlotType
            end

            local showFreeSlots    = inventory.freeSlotsLabel ~= nil
            local showAltFreeSlots = (inventory.altFreeSlotsLabel ~= nil and altFreeSlotType ~= nil)

            local settings = AF.settings
            local hideItemCount = settings.hideItemCount

            if showFreeSlots then
                local freeSlotTypeInventory = self.inventories[freeSlotType]
                local numUsedSlots, numSlots = self:GetNumSlots(freeSlotType)
                if cbeActive then freeSlotType = INVENTORY_CRAFT_BAG end
                if inventoryType == INVENTORY_QUEST_ITEM then freeSlotType = INVENTORY_QUEST_ITEM end
                local numFilteredAndShownItems = util.getInvItemCount(freeSlotType)
                local freeSlotsShown = (inventoryType == freeSlotType and numFilteredAndShownItems) or 0
                local freeSlotText = ""

                if(numUsedSlots < numSlots) then
                    freeSlotText = zo_strformat(freeSlotTypeInventory.freeSlotsStringId, numUsedSlots, numSlots)
                else
                    freeSlotText = zo_strformat(freeSlotTypeInventory.freeSlotsFullStringId, numUsedSlots, numSlots)
                end
                local newFreeSlotText
                if freeSlotsShown > 0 and (hideItemCount ~= nil and hideItemCount == false) then
                    local colorString = ""
                    local itemCountLabelColor = settings.itemCountLabelColor
                    local colorStringColorDef = ZO_ColorDef:New(itemCountLabelColor["r"], itemCountLabelColor["g"], itemCountLabelColor["b"], itemCountLabelColor["a"])
                    colorString = colorStringColorDef:Colorize(colorString .. "(" .. freeSlotsShown .. ")")
                    newFreeSlotText = zo_strformat("<<1>> <<2>>", freeSlotText, colorString)
                else
                    newFreeSlotText = freeSlotText
                end
                inventory.freeSlotsLabel:SetText(newFreeSlotText)
            end

            if showAltFreeSlots then
                local numUsedSlots, numSlots = self:GetNumSlots(altFreeSlotType)
                local altFreeSlotInventory = self.inventories[altFreeSlotType] --grab the alternateInventory to use it's string id's
                local numFilteredAndShownItems = util.getInvItemCount(altFreeSlotType)
                local altFreeSlotsShown = (inventoryType == altFreeSlotType and numFilteredAndShownItems) or 0
                local altFreeSlotText = ""

                if(numUsedSlots < numSlots) then
                    altFreeSlotText = zo_strformat(altFreeSlotInventory.freeSlotsStringId, numUsedSlots, numSlots)
                else
                    altFreeSlotText = zo_strformat(altFreeSlotInventory.freeSlotsFullStringId, numUsedSlots, numSlots)
                end
                local newAltFreeSlotText
                if altFreeSlotsShown > 0 and (hideItemCount ~= nil and hideItemCount == false) then
                    local colorString = ""
                    local itemCountLabelColor = settings.itemCountLabelColor
                    local colorStringColorDef = ZO_ColorDef:New(itemCountLabelColor["r"], itemCountLabelColor["g"], itemCountLabelColor["b"], itemCountLabelColor["a"])
                    colorString = colorStringColorDef:Colorize(colorString .. "(" .. altFreeSlotsShown .. ")")
                    newAltFreeSlotText = zo_strformat("<<1>> <<2>>", altFreeSlotText, colorString)
                else
                    newAltFreeSlotText = altFreeSlotText
                end
                inventory.altFreeSlotsLabel:SetText(newAltFreeSlotText)
            end
        end -- ZO_InventoryManagerUpdateFreeSlotsCallback

        --Overwrite the update function for the free slots label in inventories
        function ZO_InventoryManager:UpdateFreeSlots(inventoryType)
            ThrottledUpdate("ZO_InventoryManagerUpdateFreeSlotsCallback_" .. tostring(inventoryType), 100, ZO_InventoryManagerUpdateFreeSlotsCallback, self, inventoryType)
        end

        function ZO_QuickslotManager:UpdateFreeSlots()
            if AF.settings.debugSpam then d("[AF]ZO_QuickslotManager:UpdateFreeSlots") end
            local numUsedSlots, numSlots = playerInvVar:GetNumSlots(INVENTORY_BACKPACK)
            local numFilteredAndShownItems = #self.list.data
            local freeSlotsShown = numFilteredAndShownItems or 0
            local settings = AF.settings
            local hideItemCount = settings.hideItemCount

            local freeSlotText = ""
            if(numUsedSlots < numSlots) then
                freeSlotText = zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots)
            else
                freeSlotText = zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots)
            end
            local newFreeSlotText
            if freeSlotsShown > 0 and (hideItemCount ~= nil and hideItemCount == false) then
                local colorString = ""
                local itemCountLabelColor = settings.itemCountLabelColor
                local colorStringColorDef = ZO_ColorDef:New(itemCountLabelColor["r"], itemCountLabelColor["g"], itemCountLabelColor["b"], itemCountLabelColor["a"])
                colorString = colorStringColorDef:Colorize(colorString .. "(" .. freeSlotsShown .. ")")
                newFreeSlotText = zo_strformat("<<1>> <<2>>", freeSlotText, colorString)
            else
                newFreeSlotText = freeSlotText
            end
            self.freeSlotsLabel:SetText(newFreeSlotText)
        end

        --Overwrite the function UpdateInventorySlots from esoui/esoui/ingame/inventory/inventorytemplates.lua
        --for the crafting stations, in order to update the filter count amount properly in the infoBars
        function UpdateInventorySlots(infoBar)
            if AF.settings.debugSpam then d("[AF]UpdateInventorySlots: " .. tostring(infoBar:GetName())) end
            --Only for crafting station inventory types as the others are managed within function ZO_InventoryManager:UpdateFreeSlots(inventoryType) above!
            local invType = AF.currentInventoryType
            local isCraftingInvType = IsCraftingStationInventoryType(invType)
            if not isCraftingInvType then return false end
            local settings = AF.settings
            local hideItemCount = settings.hideItemCount

            local slotsLabel = infoBar:GetNamedChild("FreeSlots")
            local numUsedSlots, numSlots = playerInvVar:GetNumSlots(INVENTORY_BACKPACK)
            local numFilteredAndShownItems = util.getInvItemCount(invType, isCraftingInvType)
            local freeSlotsShown = (numFilteredAndShownItems ~= nil and numFilteredAndShownItems > 0) and numFilteredAndShownItems or 0
            --d(">numUsedSlots: " .. tostring(numUsedSlots) .. ", numSlots: " .. tostring(numSlots) .. ", numFilteredAndShownItems: " .. tostring(numFilteredAndShownItems) ..", freeSlotsShown: " ..tostring(freeSlotsShown))
            local freeSlotText = ""
            if numUsedSlots < numSlots then
                freeSlotText = zo_strformat(SI_INVENTORY_BACKPACK_REMAINING_SPACES, numUsedSlots, numSlots)
            else
                freeSlotText = zo_strformat(SI_INVENTORY_BACKPACK_COMPLETELY_FULL, numUsedSlots, numSlots)
            end
            local newFreeSlotText
            if freeSlotsShown > 0 and (hideItemCount ~= nil and hideItemCount == false) then
                local colorString = ""
                local itemCountLabelColor = settings.itemCountLabelColor
                local colorStringColorDef = ZO_ColorDef:New(itemCountLabelColor["r"], itemCountLabelColor["g"], itemCountLabelColor["b"], itemCountLabelColor["a"])
                colorString = colorStringColorDef:Colorize(colorString .. "(" .. freeSlotsShown .. ")")
                newFreeSlotText = zo_strformat("<<1>> <<2>>", freeSlotText, colorString)
                --d(">>1- newFreeSlotText: " .. tostring(newFreeSlotText))
            else
                newFreeSlotText = freeSlotText
                --d(">>2- newFreeSlotText: " .. tostring(newFreeSlotText))
            end
            slotsLabel:SetText(newFreeSlotText)
        end
    end
    --Hook the inventories info bar now for the item filtered/shown count
    hookInventoryInfoBar()


    --=== INVENTORY - EmptyBagLabel ========================================================================================
    --Update the count of items filtered if text search boxes are used (ZOs or Votans Search Box)
    ZO_PreHook(ZO_InventoryManager, "UpdateEmptyBagLabel", function(ctrl, inventoryType, isEmptyList)
        if AF.settings.debugSpam then d("[AF]ZO_InventoryManager:UpdateEmptyBagLabel - inventoryType: " ..tostring(inventoryType)) end
        --Check if the currently active focus in inside a search box
        local inventory = AF.inventories[inventoryType]
        local searchBox
        if inventory then
            local goOn = false
            local searchBoxIsEmpty = false
            searchBox = inventory.searchBox
            if searchBox and searchBox.GetText then
                local searchBoxText = searchBox:GetText()
                searchBoxIsEmpty = (searchBoxText == "") or false
                if not searchBoxIsEmpty then
                    --Check if the contents of the searchbox are not only spaces
                    local searchBoxTextWithoutSpaces = string.match(searchBoxText, "%S") -- %S = NOT a space
                    if searchBoxTextWithoutSpaces and searchBoxTextWithoutSpaces ~= "" then
                        goOn = true
                    else
                        searchBoxIsEmpty = true
                    end
                end
            end
            if not searchBoxIsEmpty then
                goOn = true
            end
            if not goOn then return false end
            --d("[AF]UpdateEmptyBagLabel, isEmptyList: " ..tostring(isEmptyList))
            --Update the count of filtered/shown items in the inventory FreeSlot label
            --Delay this function call as the data needs to be filtered first!
            ThrottledUpdate("RefreshItemCount_" .. inventoryType,
                    250, util.updateInventoryInfoBarCountLabel, inventoryType)
        end
        return false
    end)


    --=== SMITHING - Checkbox "Include banked items" ========================================================================================
    --After checking/Unchecking the checkbox "Include banked items" the number of items filtered should be updated
    --But only if FCOCraftFilter is not enabled!
    if not FCOCraftFilter then
        local function performFullRefreshFunc()
            --Delay the update as there might be several incoming refresh calls from e.g. AF_CONST_BUTTON_FILTER and AF_CONST_DROPDOWN_FILTER
            local currentInvType = AF.currentInventoryType
            ThrottledUpdate("UpdateCraftingInventoryFilteredCount_" .. tostring(currentInvType), 10, util.UpdateCraftingInventoryFilteredCount, currentInvType)
        end
        SecurePostHook(smithingVar.deconstructionPanel.inventory, "PerformFullRefresh", function() performFullRefreshFunc() end)
        --SecurePostHook(smithingVar.researchPanel, "HandleDirtyEvent", function() performFullRefreshFunc() end)
    end

end --function InitializeHooks()
--======================================================================================================================
--=== HOOKS - END ======================================================================================================
--======================================================================================================================
--Preset the crafting station panels's currentFilter variables
local function PresetCraftingStationHookVariables()
    local mapItemFilterType2CraftingStationFilterType = util.MapItemFilterType2CraftingStationFilterType
    smithingVar.refinementPanel.inventory.currentFilter     = mapItemFilterType2CraftingStationFilterType(ITEMFILTERTYPE_AF_REFINE_SMITHING,        LF_SMITHING_REFINE,         CRAFTING_TYPE_BLACKSMITHING)
    smithingVar.deconstructionPanel.inventory.currentFilter = mapItemFilterType2CraftingStationFilterType(ITEMFILTERTYPE_AF_WEAPONS_SMITHING,       LF_SMITHING_DECONSTRUCT,    CRAFTING_TYPE_BLACKSMITHING)
    smithingVar.improvementPanel.inventory.currentFilter    = mapItemFilterType2CraftingStationFilterType(ITEMFILTERTYPE_AF_WEAPONS_SMITHING,       LF_SMITHING_IMPROVEMENT,    CRAFTING_TYPE_BLACKSMITHING)
    smithingVar.researchPanel.currentFilter                 = mapItemFilterType2CraftingStationFilterType(ITEMFILTERTYPE_AF_WEAPONS_SMITHING,       LF_SMITHING_RESEARCH,       CRAFTING_TYPE_BLACKSMITHING)
    enchantingVar.inventory.currentFilter                   = mapItemFilterType2CraftingStationFilterType(ITEMFILTERTYPE_AF_GLYPHS_ENCHANTING,      LF_ENCHANTING_EXTRACTION,   CRAFTING_TYPE_ENCHANTING)
    retraitVar.inventory.currentFilter                      = mapItemFilterType2CraftingStationFilterType(ITEMFILTERTYPE_AF_RETRAIT,                LF_RETRAIT,                 CRAFTING_TYPE_INVALID)
end

local function onEndCraftingStationInteract(eventCode, craftSkill)
    --Reset the current inventory type to the normal inventory
    AF.currentInventoryType = INVENTORY_BACKPACK
end
local function onCraftingComplete(eventCode)
    --Update the counter of inventory items currently shown
    ThrottledUpdate("RefreshItemCount_" .. AF.currentInventoryType,
            50, util.updateInventoryInfoBarCountLabel, AF.currentInventoryType, true)
end

--Function to adjust/move some ZOs base game, or other addons, controls to fit into AdvancedFilters
local function AdjustZOsAndOtherAddonsVisibleStuff()
    --Move the "No items" label for an empty subfilter of the inventory a bit to the bottom
    --Not needed anymore as with API100033 Markarth
    --[[
    local invEmptyLabelCtrl = ZO_PlayerInventoryEmpty
    if invEmptyLabelCtrl ~= nil then
        local origOnEffectivelyShown = invEmptyLabelCtrl.OnEffectivelyShown
        local myOnEffectivelyShownPostHook = function(...)
            --Call original func first
            local retVarOrig = origOnEffectivelyShown(...)
            --Call my code afterwards
            local boolVal, point, relTo, relPoint, x, y, constraints = invEmptyLabelCtrl:GetAnchor(0)
            local currentAnchor = {boolVal, point, relTo, relPoint, x, y, constraints}
            if relTo == ZO_PlayerInventory then
                invEmptyLabelCtrl:ClearAnchors()
                --Try to put the "No entries" to the center of the inventory.
                --Check the text's width and move the label THIS WIDTH/2 in pixels on the x axis to the left
                --so it is really in the center
                local labelsTextWidth = invEmptyLabelCtrl:GetTextWidth()
                x = (labelsTextWidth / 2) * -1
                y = 0
                invEmptyLabelCtrl:SetAnchor(TOPLEFT, relTo, CENTER, x, y, constraints)
            end
            --Return the originals return code now
            return retVarOrig
        end
    end
    ]]
end

--Set variables in AF global namespace for function util.RefreshSubfilterBar
local function SetBankEventVariable(bankType, opened)
    if AF.settings.debugSpam then d("[AF]EVENT_OPEN/CLOSE_BANK, opened: " .. tostring(opened) .. ", bankType: " ..tostring(bankType)) end
    if bankType == nil or bankType == "" then return false end
    opened = opened or false
    local bankInvType
    --Bank
    if bankType     == "b" then
        bankInvType = INVENTORY_BANK
        AF.bankOpened = opened
        --Guild bank
    elseif bankType == "gb" then
        bankInvType = INVENTORY_GUILD_BANK
        AF.guildBankOpened = opened
        --House storage
    elseif bankType == "hb" then
        bankInvType = INVENTORY_HOUSE_BANK
        AF.houseBankOpened = opened
    end
    --Save the last opened subfilterBar button to the global AF table, so it can be used later on as the bank get's opened
    --again to re-open the samel subfilterGroup and button
    if not bankInvType then return end
    --Bank is closed
    if not opened then
        --Bank deposit
        local currentActiveSubfilterBarButtonDeposit = util.GetActiveSubfilterBarButton(INVENTORY_BACKPACK)
        if currentActiveSubfilterBarButtonDeposit then
            AF.bankLastActiveSubfilterBarButton = AF.bankLastActiveSubfilterBarButton or {}
            AF.bankLastActiveSubfilterBarButton[bankInvType] = currentActiveSubfilterBarButtonDeposit
        end
        --Bank withdraw
        --Set the currently active currentFilter of the bank inventory
        updateLastBankCurrentFilter(bankInvType)
        --Set last active button at the bank
        local currentActiveSubfilterBarButtonWithdraw = util.GetActiveSubfilterBarButton(bankInvType)
        if currentActiveSubfilterBarButtonWithdraw then
            AF.bankLastActiveSubfilterBarButton = AF.bankLastActiveSubfilterBarButton or {}
            AF.bankLastActiveSubfilterBarButton[bankInvType] = currentActiveSubfilterBarButtonWithdraw
        end
    --Bank is opened
    --else
        --Reset the last used bank currentFilter after 1/2 second
        --Disabled here. Moved to: Bank subfilterBar shown, using last used lastCurrentFilter
        --[[
        zo_callLater(function()
            AF.lastCurrentFilter[bankInvType] = nil
        end, 500)
        ]]
    end
end

--Disable the search bar controls (hide them) in some inventory layouts:
--ZO_InventoryManager:ApplyBackpackLayout e.g.
--https://github.com/esoui/esoui/blob/5f4f4fa8d40fa9a36aa17225c10b8f1b20c6c978/esoui/ingame/inventory/inventory.lua#L1836
local function disableVanillaUISearchBarsInLayouts()
    local layoutDataFragments = AF.layoutDataFragments
    for _, fragmentControl in ipairs(layoutDataFragments) do
        if fragmentControl and fragmentControl.layoutData then
            fragmentControl.layoutData.useSearchBar = false
        end
    end
    vanillaUIChangesToSearchBarsWereDone = true
end

--Check if other addons are activated and output an error message if they brak AdvancedFilters
function AF.checkForOtherAddonErrors(eventName, initial)
    --Check if needed libraries are given -> Chat is activated here so we can see error messages!
    if AF.dependenciesLoaded == false then AF.loadLibraries(true) end

    --Check for other addons
    if not AF.otherAddons then return end
    if AF.otherAddons["MultiCraft"] or MultiCraft ~= nil then
        showChatDebug(AF.strings.errorOtherAddonsMulticraft, AF.strings.errorOtherAddonsMulticraftLong)
        return
    end
end

--Add dnymic entries to the subfilterGroups
local function createAdditionalSubFilterGroups()
    local collectibleDataKeyToSubFilterBars = AF.collectibleDataKeyToSubFilterBars
    local collectibleDataKeyToCategoryTypes = AF.collectibleDataKeyToCategoryTypes

    --LF_QUICKSLOT
    --Add QuickSlot collectible categories subtables for subfilter button bars
    for categoryIndex, categoryData in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator() do
        if DoesCollectibleCategoryContainSlottableCollectibles(categoryIndex) then
            local collectibleDataKeyForAF = util.getAFQuickSlotCollectibleKey(categoryData)
            AF.subfilterGroups[LF_QUICKSLOT][CRAFTING_TYPE_INVALID][collectibleDataKeyForAF] = {}
            AF.subfilterButtonNames[collectibleDataKeyForAF] = collectibleDataKeyToSubFilterBars[collectibleDataKeyForAF]
            AF.subfilterButtonNames[collectibleDataKeyForAF] = AF.subfilterButtonNames[collectibleDataKeyForAF] or { AF_CONST_ALL }
            AF.filterTypeNames[collectibleDataKeyForAF] = collectibleDataKeyForAF
            local subfilterButtonNamesForCollectibleData = AF.subfilterButtonNames[collectibleDataKeyForAF]
            if #subfilterButtonNamesForCollectibleData > 1 then
                AF.subfilterCallbacks[collectibleDataKeyForAF] = {
                    addonDropdownCallbacks = {},
                }
                for _, subfilterButtonNameForCollectibleData in ipairs(subfilterButtonNamesForCollectibleData) do
                    --d(">>subfilterButtonNameForCollectibleData: " ..tostring(subfilterButtonNameForCollectibleData))
                    local categoryTypes
                    if subfilterButtonNameForCollectibleData ~= AF_CONST_ALL then
                        categoryTypes = collectibleDataKeyToCategoryTypes[collectibleDataKeyForAF][subfilterButtonNameForCollectibleData]
                        categoryTypes = categoryTypes or {}
                    end
                    AF.subfilterCallbacks[collectibleDataKeyForAF][subfilterButtonNameForCollectibleData] = {
                        filterCallback      = AF.GetFilterCallbackForCollectibles(categoryTypes),
                        dropdownCallbacks   = {},
                    }
                end
            else
                AF.subfilterCallbacks[collectibleDataKeyForAF] = {
                    addonDropdownCallbacks = {},
                    [AF_CONST_ALL] = {
                        filterCallback      = AF.GetFilterCallbackForCollectibles(),
                        dropdownCallbacks   = {},
                    },
                }
            end
        end
    end
end

--Build the keys for the dropdown callback tables used in AF.util.BuildDropdownCallbacks()
local function createDropdownBoxCallbackFunctionKeys()
    local keys = {
        [AF_CONST_ALL] = {},
    }
    --For each entry in AF.subfilterButtonNames:
    --Get the "key name" by mapping the subfilterButton key to it's name using filterTypeNames
    local subfilterButtonNames = AF.subfilterButtonNames
    local filterTypeNames = AF.filterTypeNames
    local subfilterButtonEntriesNotForDropdownCallback = AF.subfilterButtonEntriesNotForDropdownCallback
    for subfilterButtonKey, subfilterButtonData in pairs(subfilterButtonNames) do
        local dropDownCallbackKeyName = filterTypeNames[subfilterButtonKey] or ""
        if dropDownCallbackKeyName ~= "" then
            keys[dropDownCallbackKeyName] = {}
            local keysDropDownCallbackKeyName = keys[dropDownCallbackKeyName]
            local doNotAddToDropdownCallbacks = subfilterButtonEntriesNotForDropdownCallback[subfilterButtonKey]
            local replacementWasAdded = false
            --Loop over the subfilterButtonData and get each key, except the ALL entry
            for _, keyName in ipairs(subfilterButtonData) do
                if keyName ~= AF_CONST_ALL then
                    local doAdd = true
                    if doNotAddToDropdownCallbacks ~= nil then
                        for _, doNotAddToDropdownCallbackEntry in ipairs(doNotAddToDropdownCallbacks.doNotAdd) do
                            if keyName == doNotAddToDropdownCallbackEntry then
                                doAdd = false
                                break -- end the loop
                            end
                        end
                    end
                    if doAdd == true then
                        table.insert(keysDropDownCallbackKeyName, keyName)
                    else
                        if not replacementWasAdded and doNotAddToDropdownCallbacks ~= nil and doNotAddToDropdownCallbacks["replaceWith"] ~= nil then
                            table.insert(keysDropDownCallbackKeyName, doNotAddToDropdownCallbacks["replaceWith"])
                            replacementWasAdded = true
                        end
                    end
                end
            end
        end
    end
    AF.dropdownCallbackKeys = keys
end

local function AdvancedFilters_Loaded(eventCode, addonName)
    --Disable the searchBar of the different inventories
    if not vanillaUIChangesToSearchBarsWereDone then
        disableVanillaUISearchBarsInLayouts()
    end

    if addonName == "MultiCraft" then
        AF.otherAddons[addonName] = true
    end
    if addonName ~= AF.name then return end

    EVENT_MANAGER:UnregisterForEvent(AF.name .. "_Loaded", EVENT_ADD_ON_LOADED)

    --Create additional subfilterButtonBars for dynamic content like the quickslot collectible filters
    createAdditionalSubFilterGroups()
    createDropdownBoxCallbackFunctionKeys()

    EVENT_MANAGER:RegisterForEvent(AF.name .. "_PlayerActivated", EVENT_PLAYER_ACTIVATED,   AF.checkForOtherAddonErrors)

    --Do not load anything further if the addon MultiCraft is enabled
    if AF.otherAddons["MultiCraft"] or MultiCraft ~= nil then
        return
    end

    --Register a callback function for crafting stations: If you leave them reseet the current inventory type to INVENTORY_BACKPACK
    EVENT_MANAGER:RegisterForEvent(AF.name .. "_CraftingStationLeave",          EVENT_END_CRAFTING_STATION_INTERACT,    onEndCraftingStationInteract)
    EVENT_MANAGER:RegisterForEvent(AF.name .. "_CraftingStationCraftFinished",  EVENT_CRAFT_COMPLETED,                  onCraftingComplete)
    EVENT_MANAGER:RegisterForEvent(AF.name .. "_CraftingStationCraftFailed",    EVENT_CRAFT_FAILED,                     onCraftingComplete)
    --Events for the bank and guild bank open and close, to set variables for function util.RefreshSubfilterBar
    AF.bankOpened       = false
    AF.guildBankOpened  = false
    AF.houseBankOpened  = false
    EVENT_MANAGER:RegisterForEvent(AF.name .. "_BankOpened",                    EVENT_OPEN_BANK,                        function() SetBankEventVariable("b", true) end)
    EVENT_MANAGER:RegisterForEvent(AF.name .. "_BankClosed",                    EVENT_CLOSE_BANK,                       function() SetBankEventVariable("b", false) end)
    EVENT_MANAGER:RegisterForEvent(AF.name .. "_GuildBankOpened",               EVENT_OPEN_GUILD_BANK,                  function() SetBankEventVariable("gb", true) end)
    EVENT_MANAGER:RegisterForEvent(AF.name .. "_GuildBankClosed",               EVENT_CLOSE_GUILD_BANK,                 function() SetBankEventVariable("gb", false) end)
    --Bufix to reset "store"'s currentFilter as stable closes
    EVENT_MANAGER:RegisterForEvent(AF.name .. "_StableClosed",                  EVENT_STABLE_INTERACT_END,              function() controlsForChecks.store.currentFilter = ITEM_TYPE_DISPLAY_CATEGORY_ALL end) --ITEMFILTERTYPE_ALL

    --Create instance of library libFilters
    util.LibFilters:InitializeLibFilters()
    --SavedVariables
    AF.settings = ZO_SavedVars:NewAccountWide(AF.name .. "_Settings", AF.savedVarsVersion, "Settings", AF.defaultSettings, GetWorldName())
    --Create the subfilter bars below the normal inventories filters
    AF.CreateSubfilterBars()
    --Initialize the prehooks etc. for inventories to react on filter changes etc.
    InitializeHooks()
    --Preset some needed variables for the crafting stations
    PresetCraftingStationHookVariables()
    --Adjust some stuff for other addon compatibility, or ZOs code compatibility
    AdjustZOsAndOtherAddonsVisibleStuff()
    --Build the LAM settingsmenu if LAM is loaded
    AF.LAMSettingsMenu()

    --For debugging
    if GetDisplayName() == "@Baertram" then
        --Enable short global variable for AdvancedFilters
        A_F = AF
    end
end

--Load the addon
EVENT_MANAGER:RegisterForEvent("AdvancedFilters_Loaded", EVENT_ADD_ON_LOADED, AdvancedFilters_Loaded)