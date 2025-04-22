
LegionSpecialForces = LibStub("AceAddon-3.0"):NewAddon("LegionSpecialForces", "AceConsole-3.0", "AceEvent-3.0" );
local raid, guild = {}

function LegionSpecialForces:OnInitialize()
		self:Print("loaded")
end

function LegionSpecialForces:OnEnable()
		self:Print("enabled")
	    self:Print("используй в рейде /LegionRaidInfo")
end

function LegionSpecialForces:OnDisable()
		-- Called when the addon is disabled
		self:Print("enabled")
end

local GuildMemberInfo = function(i)
	local name, rank, rankIndex, level, class, location, note, officernote, online, status, classFileName = GetGuildRosterInfo(i)
	if name == nil then return nil end
	local ilvl = GUILD_CHARACTER_ILEVEL_DATA[name]
	if ilvl== nil then return nil end
	local info = name .. " is " .. tostring(ilvl)
	return name, rank, rankIndex, level, class, location, note, officernote, online, status, classFileName, ilvl
end

function LegionSpecialForces:RaidStatusInfo()
    local numRaidMembers = GetNumRaidMembers()
    if numRaidMembers == 0 then return nil end

    local classCounts = {}
    local factionCounts = {}
    local namesByClassAndFaction = {}
    local nameRaidLider
    local zoneRaidLider
    local zoneCounts = {}
    local ilvlSum = 0
    local ilvlFarFarAway = 0
    local ilvlAvg = 0
    local playersNotWithLeader = 0

    for i = 1, numRaidMembers, 1 do
        local name, rank, _, _, class, _, zone, online, _, _, _ = GetRaidRosterInfo(i)
        if online then
            if not classCounts[class] then
                classCounts[class] = 0
            end
            classCounts[class] = classCounts[class] + 1

            local faction = UnitFactionGroup("raid".. i)
            if not factionCounts[faction] then
                factionCounts[faction] = {}
            end
            if not factionCounts[faction][class] then
                factionCounts[faction][class] = 0
            end
            factionCounts[faction][class] = factionCounts[faction][class] + 1

            if not namesByClassAndFaction[faction] then
                namesByClassAndFaction[faction] = {}
            end
            if not namesByClassAndFaction[faction][class] then
                namesByClassAndFaction[faction][class] = {}
            end

            -- Получение локации рейд-лидера
            if rank == 2 then
                nameRaidLider = name
                zoneRaidLider = zone
            end

            -- Подсчёт участников по локациям
            if not zoneCounts[zone] then
                zoneCounts[zone] = {count = 0, names = {}}
            end
            zoneCounts[zone].count = zoneCounts[zone].count + 1
            table.insert(zoneCounts[zone].names, name)

            -- Получение Невидимки
            local visible = UnitIsVisible(name)
            local visibleColor
            if visible then
                visibleColor = "|cFFFFFFFF"
            else
                visibleColor = "|cFF999999"
            end

            -- Получение Item Level
            local ilvl = GUILD_CHARACTER_ILEVEL_DATA[name] or 0
            ilvlSum = ilvlSum + ilvl
            if zoneRaidLider ~= zone then
                ilvlFarFarAway = ilvlFarFarAway + ilvl
                playersNotWithLeader = playersNotWithLeader + 1
            end

            local ilvlColor
            if ilvl == 0 then
                ilvlColor = "|cFFCC66FF" -- Розовый цвет для нечленов гильдии
            elseif ilvl < 230 then
                ilvlColor = "|cFF999999" -- Серый цвет
            elseif ilvl >= 230 and ilvl < 240 then
                ilvlColor = "|cFF1EFF00" -- Зелёный цвет
            elseif ilvl >= 240 and ilvl < 250 then
                ilvlColor = "|cFF0070DD" -- Синий цвет
            elseif ilvl >= 250 and ilvl < 260 then
                ilvlColor = "|cFF9400D3" -- Фиолетовый цвет
            else
                ilvlColor = "|cFFFF8000" -- Цвет легендарного оружия
            end
            table.insert(namesByClassAndFaction[faction][class], visibleColor.. name.. "|r (ilvl: ".. ilvlColor.. ilvl.. "|r)")
        end
    end
    if numRaidMembers > 0 then
        ilvlAvg = math.floor(ilvlSum / numRaidMembers)
    end

    -- Форматирование вывода
    local result = {}
    if ilvlAvg >= 250 and playersNotWithLeader == 0 then
        table.insert(result, "|cFF1EFF00ЛЕГИОН взвешен, измерен и признан готовым к бою!|r")
    else
        table.insert(result, "|cFFCC66FFЛЕГИОН взвешен, измерен и, к сожалению, пока не готов к бою.|r")
    end
    table.insert(result, "Нас в рейде: ".. numRaidMembers .. "/40 суммарный ilvl: " .. ilvlSum .. " средний ilvl: " .. ilvlAvg)
    table.insert(result, "Игроков не в локации с рейд-лидером: " .. playersNotWithLeader)

    for faction, classes in pairs(factionCounts) do
        local factionColor
        if faction == "Alliance" then
            factionColor = "|cFF33CCFF"
        elseif faction == "Horde" then
            factionColor = "|cFFFF3333"
        else
            factionColor = "|cFFFFFF66" -- Оранжевый цвет для ренегатов
        end
        table.insert(result, factionColor.. faction.. "|r:")

        for class, count in pairs(classes) do
            local classColor = RAID_CLASS_COLORS[class]
            if classColor then
                local formattedClass = "|c".. classColor.colorStr.. class.. "|r"
                local namesString = table.concat(namesByClassAndFaction[faction][class], ", ")
                table.insert(result, "-- ".. formattedClass.. " (".. count.. "): ".. namesString)
            else
                local namesString = table.concat(namesByClassAndFaction[faction][class], ", ")
                table.insert(result, "-- ".. class.. " (".. count.. "): ".. namesString)
            end
        end
    end

    table.insert(result, "\nРейд-лидер: ".. nameRaidLider .. ", локация: ".. zoneRaidLider)
    table.insert(result, "Игроки не с нами:")
    for zone, data in pairs(zoneCounts) do
        if zone ~= zoneRaidLider then
            table.insert(result, "-- ".. zone.. " (".. data.count.. "): ".. table.concat(data.names, ", "))
        end
    end

    return table.concat(result, "\n")
end





-- Регистрация команды rinfo
LegionSpecialForces:RegisterChatCommand("LegionRaidInfo", function() 
    raidStatusInfo = LegionSpecialForces:RaidStatusInfo()
    if raidStatusInfo then
        LegionSpecialForces:Print(raidStatusInfo)
    else
        LegionSpecialForces:Print("В рейде нет участников.")    
    end
end)


