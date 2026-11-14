-- GAG AUTO HUB V9.4.2 NEON | Delta Android
-- Includes V9.4.1 core unchanged: Anubis Arc, shops, auto jump and guarded paid restart.
-- Adds READ-ONLY Ancient Trials tracking + strict mutated-fruit inventory audit.
-- IMPORTANT: Does NOT fire Trial offering requests or click "Offer all"; request not verified.
-- Preserve older working V9.4.1 separately. All automation toggles start OFF.
-- Anubis crop categories are provisional; verify with event results.
local PROFILE_IMAGE_ASSET_ID = ""
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local events = RS:WaitForChild("GameEvents", 12)
if not events then warn("GAG V8.5: GameEvents missing") return end
local env = (getgenv and getgenv()) or _G
if type(env.GAG_V9_4_2_Close) == "function" then pcall(env.GAG_V9_4_2_Close) end
if type(env.GAG_V9_4_1_Close) == "function" then pcall(env.GAG_V9_4_1_Close) end
if type(env.GAG_V8_Close) == "function" then pcall(env.GAG_V8_Close) end
local state = {
    alive=true, switches={}, connections={}, logLines={}, lastLog="Ready",
    count=0, capacity=250, inventoryKnown=false,
    lastNormal=0, lastAnubisHarvest=0,
    lastSubmit=0, lastRestart=0, pending=nil, token=math.random(100000,900000),
    submitted=0, accepted=0, harvestBatches=0, restarts=0,
    trait="?", stage="?", eventStatus="Stopped", restartBusy=false,
    done=false, completeAt=0, paymentLocked=false, awaitingNewCycle=false,
    lastJump=os.clock(), jumpCount=0, lastResult=0, restartFault=false, unknown={}, detected=0, lastCrop="—", completed=0, fruitRequests=0, afkEvents=0, afkStatus="OFF", lastIdle=0
}
env.GAG_V9_4_2 = state
local function new(class, props, parent)
    local obj=Instance.new(class)
    for k,v in pairs(props or {}) do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function connect(signal, fn)
    local c=signal:Connect(fn)
    state.connections[#state.connections+1]=c
    return c
end
local function log(s)
    s=tostring(s)
    state.lastLog=s
    state.logLines[#state.logLines+1]=os.date("%H:%M:%S").." "..s
    if #state.logLines>120 then table.remove(state.logLines,1) end
end
local function remote(path)
    local obj=events
    for part in path:gmatch("[^/]+") do
        obj=obj and obj:FindFirstChild(part)
    end
    return obj
end
local function fire(path,...)
    local r=remote(path)
    if not r or not r:IsA("RemoteEvent") then return false end
    return pcall(r.FireServer,r,...)
end
local C={
    bg=Color3.fromRGB(14,12,25), panel=Color3.fromRGB(28,23,43),
    tile=Color3.fromRGB(37,29,55), accent=Color3.fromRGB(166,86,255),
    white=Color3.fromRGB(244,235,255), muted=Color3.fromRGB(175,162,192),
    green=Color3.fromRGB(106,241,164), red=Color3.fromRGB(130,48,76)
}
local function corner(obj,r)
    new("UICorner",{CornerRadius=UDim.new(0,r or 9)},obj)
end
local function btn(parent,text,pos,size,color)
    local b=new("TextButton",{
        Position=pos,Size=size,BackgroundColor3=color or C.tile,
        Text=text,TextColor3=C.white,Font=Enum.Font.GothamBold,
        TextSize=10,AutoButtonColor=true
    },parent)
    corner(b,8)
    return b
end
local gui=new("ScreenGui",{
    Name="GAG_AutoHub_V942",ResetOnSpawn=false,IgnoreGuiInset=true,
    DisplayOrder=900
},pg)
local main=new("Frame",{
    Size=UDim2.fromOffset(310,388),Position=UDim2.new(.5,-155,.5,-194),
    BackgroundColor3=C.bg,BorderSizePixel=0,Active=true
},gui)
corner(main,14)
new("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(32,19,56)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(12,12,27))
}),Rotation=90},main)
new("UIStroke",{Color=C.accent,Thickness=1,Transparency=.3},main)
local header=new("Frame",{
    Size=UDim2.new(1,0,0,44),BackgroundColor3=C.panel,
    BorderSizePixel=0,Active=true
},main)
corner(header,14)
local avatarSource=PROFILE_IMAGE_ASSET_ID~="" and
    (PROFILE_IMAGE_ASSET_ID:match("^rbxassetid://") and PROFILE_IMAGE_ASSET_ID or "rbxassetid://"..PROFILE_IMAGE_ASSET_ID)
    or ("rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=150&h=150")
local avatar=new("ImageLabel",{
    Position=UDim2.fromOffset(9,7),Size=UDim2.fromOffset(30,30),
    BackgroundColor3=C.tile,Image=avatarSource,ScaleType=Enum.ScaleType.Crop
},header)
new("UICorner",{CornerRadius=UDim.new(1,0)},avatar)
new("TextLabel",{
    Position=UDim2.fromOffset(46,5),Size=UDim2.fromOffset(155,19),
    BackgroundTransparency=1,Text="GAG HUB V9.4.2",
    TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left
},header)
new("TextLabel",{
    Position=UDim2.fromOffset(46,23),Size=UDim2.fromOffset(155,15),
    BackgroundTransparency=1,Text="NEON  •  SMART CROPS  •  DELTA",
    TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left
},header)
local minimize=btn(header,"-",UDim2.new(1,-64,0,9),UDim2.fromOffset(26,26))
local exit=btn(header,"X",UDim2.new(1,-34,0,9),UDim2.fromOffset(26,26),C.red)
local mini=new("ImageButton",{
    Size=UDim2.fromOffset(44,44),Position=UDim2.new(1,-58,.65,0),
    BackgroundColor3=C.panel,Image=avatarSource,ScaleType=Enum.ScaleType.Crop,
    Visible=false,Active=true
},gui)
new("UICorner",{CornerRadius=UDim.new(1,0)},mini)
local tabs=new("Frame",{
    Position=UDim2.fromOffset(8,49),Size=UDim2.new(1,-16,0,28),
    BackgroundTransparency=1
},main)
local pages,tabButtons={},{}
local tabNames={"EVENT","TRIALS","SHOPS","INFO"}
for i,name in ipairs(tabNames) do
    tabButtons[name]=btn(tabs,name,UDim2.new((i-1)/#tabNames,2,0,0),
        UDim2.new(1/#tabNames,-4,1,0),i==1 and C.accent or C.tile)
    local sc=new("ScrollingFrame",{
        Position=UDim2.fromOffset(8,82),Size=UDim2.new(1,-16,1,-119),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=i==1
    },main)
    new("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},sc)
    pages[name]=sc
end
local function selectTab(name)
    for n,p in pairs(pages) do
        p.Visible=n==name
        tabButtons[n].BackgroundColor3=n==name and C.accent or C.tile
    end
end
for name,b in pairs(tabButtons) do
    connect(b.MouseButton1Click,function() selectTab(name) end)
end
local function section(page,text)
    new("TextLabel",{
        Size=UDim2.new(1,-5,0,18),BackgroundTransparency=1,Text=text,
        TextColor3=C.accent,Font=Enum.Font.GothamBold,TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left
    },pages[page])
end
local function hint(page,text,height)
    local label=new("TextLabel",{
        Size=UDim2.new(1,-5,0,height or 39),BackgroundColor3=C.panel,
        Text=text,TextWrapped=true,TextColor3=C.muted,TextSize=9,
        Font=Enum.Font.Gotham,BorderSizePixel=0
    },pages[page])
    corner(label,8)
    return label
end
local function toggle(page,key,text,desc)
    local box=new("Frame",{
        Size=UDim2.new(1,-5,0,43),BackgroundColor3=C.panel,
        BorderSizePixel=0
    },pages[page])
    corner(box,9)
    new("TextLabel",{
        Position=UDim2.fromOffset(9,5),Size=UDim2.new(1,-66,0,17),
        BackgroundTransparency=1,Text=text,TextColor3=C.white,
        Font=Enum.Font.GothamBold,TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left
    },box)
    new("TextLabel",{
        Position=UDim2.fromOffset(9,23),Size=UDim2.new(1,-66,0,14),
        BackgroundTransparency=1,Text=desc,TextColor3=C.muted,
        Font=Enum.Font.Gotham,TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left
    },box)
    local b=btn(box,"OFF",UDim2.new(1,-53,0,9),UDim2.fromOffset(45,25))
    state.switches[key]=false
    connect(b.MouseButton1Click,function()
        state.switches[key]=not state.switches[key]
        b.Text=state.switches[key] and "ON" or "OFF"
        b.BackgroundColor3=state.switches[key] and C.accent or C.tile
        if key=="autoJump" and state.switches[key] then
            state.lastJump=os.clock()
            log("Auto Jump armed (every 5 minutes)")
        end
        if key=="anubis" then
            if state.switches[key] then
                state.done=false
                state.completeAt=0
                state.pending=nil
                -- Do not unlock a possibly charged restart by toggling.
                state.eventStatus="Running"
                log("Anubis started")
            else
                state.pending=nil
                state.eventStatus="Stopped"
                log("Anubis stopped")
            end
        end
    end)
end
section("EVENT","ANUBIS CONTROL CENTER")
toggle("EVENT","anubis","Auto Anubis Event","Collect + submit")
toggle("EVENT","anubisRestart","Auto Paid Restart","1T per confirmed restart")
toggle("EVENT","autoJump","Auto Jump (5 Min)","Jump every 300 seconds")
toggle("EVENT","antiAFK","Anti-AFK Protection","Idle input on Roblox Idled event")
local afkLabel=hint("EVENT","Anti-AFK: OFF | Triggers: 0",24)
local arcLabel=hint("EVENT","Trait: ? | Stage: ?\nStopped",38)
local dashboard=hint("EVENT","Accepted: 0 | Complete: 0 | Restart: 0",38)
local paymentLabel=hint("EVENT","Paid restart (1T): UNLOCKED",24)
local cropLabel=hint("EVENT","Crop: — | Unknown: 0",27)
local copyResults=btn(pages.EVENT,"COPY RESULTS",UDim2.new(0,0,0,0),UDim2.new(1,-5,0,28),C.accent)

section("TRIALS","ANCIENT TRIALS | SAFE OFFERING PREVIEW")
toggle("TRIALS","trialMonitor","Track Ancient Trials","Read-only trait, points, inventory and replies")
local trialSummary=hint("TRIALS","Requested: ? | Offering progress: ?/900",37)
local trialInventoryLabel=hint("TRIALS","Fruit audit: enable tracker or tap SCAN",59)
local trialFeedback=hint("TRIALS","Last offering: none observed",35)
local trialScanButton=btn(pages.TRIALS,"SCAN FRUITS + TRIAL",UDim2.new(),UDim2.new(1,-5,0,28),C.accent)
local trialCopyButton=btn(pages.TRIALS,"COPY TRIAL REPORT",UDim2.new(),UDim2.new(1,-5,0,28),C.accent)
hint("TRIALS","SAFE MODE: Mutated, favorited, unknown and off-category fruits are NEVER auto-offered. The Trial submission call is not verified, so this version only tracks and audits; use the NPC manually. All fruits may be consumed by Offer All.",96)

section("SHOPS","STANDARD SHOPS")
toggle("SHOPS","seeds","Auto Buy Seeds","Uses visible stock entries")
toggle("SHOPS","gear","Auto Buy Gear","Uses visible stock entries")
toggle("SHOPS","eggs","Auto Buy Eggs","Uses visible stock entries")
section("INFO","SMART CROP DETECTION")
local unknownLabel=hint("INFO","Unknown plants: none",65)
local copyUnknown=btn(pages.INFO,"COPY CROP REPORT",UDim2.new(),UDim2.new(1,-5,0,28),C.accent)
section("INFO","ABOUT V9.4.2")
hint("INFO","GAG HUB V9.4.2 NEON\n\nPreserves V9.4.1 Ancient Arc automation and shops.\nNEW: Ancient Trials trait/progress/inventory monitor.\nNEW: strict mutated-fruit protection audit.\nTrials offering is manual until its server request is verified.\nPaid restart remains 1T, opt-in and guarded.\nAuto Jump every 5 min, opt-in.\nAll toggles OFF on startup.\nClose X disconnects.",160)
local footer=new("Frame",{
    Position=UDim2.new(0,8,1,-30),Size=UDim2.new(1,-16,0,24),
    BackgroundColor3=C.panel
},main)
corner(footer,8)
local status=new("TextLabel",{
    Position=UDim2.fromOffset(7,0),Size=UDim2.new(1,-14,1,0),
    BackgroundTransparency=1,Text="Ready",TextColor3=C.green,
    Font=Enum.Font.Gotham,TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left,
    TextTruncate=Enum.TextTruncate.AtEnd
},footer)
local function drag(target,handle)
    local active=false
    local start,initial,dragInput
    connect(handle.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or
           input.UserInputType==Enum.UserInputType.MouseButton1 then
            active=true
            start=input.Position
            initial=target.Position
            dragInput=input
        end
    end)
    connect(UIS.InputChanged,function(input)
        if not active or not dragInput then return end
        if input~=dragInput and not (
            dragInput.UserInputType==Enum.UserInputType.MouseButton1 and
            input.UserInputType==Enum.UserInputType.MouseMovement) then return end
        local delta=input.Position-start
        target.Position=UDim2.new(initial.X.Scale,initial.X.Offset+delta.X,
            initial.Y.Scale,initial.Y.Offset+delta.Y)
    end)
    connect(UIS.InputEnded,function(input)
        if input==dragInput then active=false dragInput=nil end
    end)
end
drag(main,header)
drag(mini,mini)
connect(minimize.MouseButton1Click,function() main.Visible=false mini.Visible=true end)
connect(mini.MouseButton1Click,function() main.Visible=true mini.Visible=false end)
local function cleanup()
    if not state.alive then return end
    state.alive=false
    for k in pairs(state.switches) do state.switches[k]=false end
    state.afkStatus="OFF"
    for _,c in ipairs(state.connections) do pcall(function() c:Disconnect() end) end
    if gui then gui:Destroy() end
    if env.GAG_V9_4_2_Close==cleanup then env.GAG_V9_4_2_Close=nil end
end
env.GAG_V9_4_2_Close=cleanup
connect(exit.MouseButton1Click,cleanup)
-- Anti-AFK is opt-in. This listener is owned by this UI and cleaned up by X.
connect(player.Idled,function()
    if not state.alive or not state.switches.antiAFK then return end
    state.afkEvents+=1
    state.lastIdle=os.clock()
    local ok,err=pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0,0))
    end)
    state.afkStatus=ok and "SIGNAL SENT" or "UNSUPPORTED"
    log(ok and "Anti-AFK input attempted" or ("Anti-AFK failed: "..tostring(err)))
end)

connect(copyResults.MouseButton1Click,function()
    local text=table.concat(state.logLines,"\n")
    if type(setclipboard)=="function" then
        local ok=pcall(setclipboard,text)
        log(ok and "Results copied" or "Clipboard failed")
    else
        log("Clipboard not supported")
    end
end)
local function getCapacity()
    for _,obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local a,b=obj.Text:match("Fruit%s*Items%s*%(%s*(%d+)%s*/%s*(%d+)%s*%)")
            if a and b then return tonumber(a),tonumber(b) end
        end
    end
end
local function ownFarm()
    local root=workspace:FindFirstChild("Farm")
    if not root then return end
    for _,farm in ipairs(root:GetChildren()) do
        local imp=farm:FindFirstChild("Important")
        local data=imp and imp:FindFirstChild("Data")
        local owner=data and data:FindFirstChild("Owner")
        if owner and tostring(owner.Value)==player.Name then return farm end
    end
end
local function plantsFolder()
    local farm=ownFarm()
    local imp=farm and farm:FindFirstChild("Important")
    return imp and imp:FindFirstChild("Plants_Physical")
end
local function stockAvailable(stock)
    if not stock or not stock:IsA("TextLabel") then return false end
    local n=tostring(stock.Text):match("(%d+)")
    return n~=nil and tonumber(n)>0
end
local function normalShop(kind)
    local rootName=kind=="seeds" and "Seed_Shop" or
        (kind=="gear" and "Gear_Shop" or "PetEggShop")
    local root=pg:FindFirstChild(rootName)
    if not root then return end
    local calls=0
    for _,obj in ipairs(root:GetDescendants()) do
        if obj.Name=="Stock_Text" and stockAvailable(obj) then
            local frame=obj.Parent and obj.Parent.Parent
            local name=frame and frame.Name
            if name and name~="" and name~="ScrollingFrame" and name~="Main_Frame" then
                local ok=false
                if kind=="seeds" then ok=fire("BuySeedStock","Shop",name)
                elseif kind=="gear" then ok=fire("BuyGearStock",name)
                else ok=fire("BuyPetEgg",name) end
                if ok then calls+=1 end
            end
            if calls>=10 then break end
        end
    end
    if calls>0 then log("Shop "..kind..": "..calls.." requests") end
end
-- Provisional crop categories. Never assume a crop qualifies for Root.
-- Add or change categories only after verifying the event accepts them.
local cropTraits={
    ["Beanstalk"]={"Leafy","Stalky","Vegetable"},
    ["Blue Candypop"]={"Flower"},
    ["Bone Blossom"]={"Flower"},
    ["Candy Blossom 2026"]={"Flower","Sweet"},
    ["Celestiberry"]={"Berry","Fruit","Leafy","Prickly"},
    ["Dragon Fruit"]={"Fruit","Prickly","Tropical"},
    ["Moon Mango"]={"Fruit","Leafy","Woody"},
    ["Poison Apple"]={"Fruit","Leafy","Prickly","Sour","Sweet","Woody"},
    ["Tomato"]={"Fruit","Leafy"},
    ["Cocomango"]={"Fruit","Leafy","Sour","Sweet","Woody"},
    -- Root crops from community listings; confirm acceptance in-game.
    ["Carrot"]={"Root"},["Potato"]={"Root"},["Radish"]={"Root"},
    ["Octobloom"]={"Root","Flower"},["Ghoul Root"]={"Root"},
    ["Wild Carrot"]={"Root"},["Onion"]={"Root"},
    ["Spring Onion"]={"Root"},["Firefly Spiral"]={"Root"},
    ["Beach Brella"]={"Root"},["Bear Claw Flower"]={"Root"},
    ["Evo Beetroot II"]={"Root"},["Evo Beetroot I"]={"Root"},
    ["Evo Beetroot III"]={"Root"},["Evo Beetroot IV"]={"Root"},
    ["Halloween Fang Root"]={"Root"},["Fang Root"]={"Root"},
    ["Auburn Pine"]={"Root"},["Aurora Vine"]={"Root"},
    ["Mangrove"]={"Root"},["Reindeer Root"]={"Root"},
    ["Trinity Fruit"]={"Root"},["Rhubarb"]={"Root"},
    ["Tall Asparagus"]={"Root"},["Turnip"]={"Root"},
    ["Anubis Bramble"]={"Root"},["Wraproot"]={"Root"},
    ["Bumble Bulb"]={"Root"},["Taro Flower"]={"Root"},
    ["Mummy's Hand"]={"Root"},["Marshmallow Root"]={"Root"},
    ["Shadow Spine"]={"Root"},["Smoke Stalk"]={"Root"},
    ["Obby Oddvine"]={"Root"},["Egg Shroom"]={"Root"}
}
-- Prefer live plant metadata. Fallback categories are not exhaustive.
-- A newly added crop is supported automatically when the game exposes
-- its category/trait information to the client.
local knownTraits={}
for _,types in pairs(cropTraits) do
    for _,t in ipairs(types) do knownTraits[string.lower(t)]=t end
end
for _,t in ipairs({"Berry","Fruit","Leafy","Prickly","Tropical","Sweet","Sour","Woody","Root","Flower","Stalky","Vegetable","Spicy","Night","Summer","Fall","Zen","Fungus","Candy","Nutty","Citrus","Aquatic","Prehistoric","Magical","Christmas"}) do
    knownTraits[string.lower(t)]=t
end
local function normalizeName(v)
    return tostring(v or ""):gsub("%s+Seed$", ""):gsub("^%s+", ""):gsub("%s+$", "")
end
local function addTypes(set,value)
    if type(value)=="string" then
        for word in value:gmatch("[^,;|/]+") do
            local clean=word:match("^%s*(.-)%s*$")
            local recognized=knownTraits[string.lower(clean)]
            if recognized then set[recognized]=true end
        end
    elseif type(value)=="table" then
        for k,v in pairs(value) do
            if type(k)=="number" then addTypes(set,v)
            elseif type(k)=="string" and (v==true or v==1) then
                addTypes(set,k)
            elseif type(v)=="string" then addTypes(set,v) end
        end
    end
end
local metaKeys={"Traits","Trait","Types","Type","PlantTraits","PlantTypes","Categories","Category","CropTypes"}
local function fromInstance(obj,set)
    if not obj then return end
    for _,key in ipairs(metaKeys) do
        local v=obj:GetAttribute(key)
        if v~=nil then addTypes(set,v) end
        local child=obj:FindFirstChild(key)
        if child then
            if child:IsA("StringValue") then addTypes(set,child.Value)
            elseif child:IsA("Folder") then
                for _,v in ipairs(child:GetChildren()) do
                    if v:IsA("BoolValue") and v.Value then addTypes(set,v.Name)
                    elseif v:IsA("StringValue") then
                        addTypes(set,v.Name);addTypes(set,v.Value)
                    end
                end
            end
        end
    end
    for key in pairs(knownTraits) do
        local v=obj:GetAttribute(key)
        if v==true then addTypes(set,key) end
    end
end
-- Load only named crop/trait data modules, never arbitrary game scripts.
-- A slow/unavailable module does not block the working event loop.
local moduleCache={}
local moduleNames={PlantTraits=true,PlantTypes=true,CropTraits=true,CropTypes=true,PlantTypeData=true,PlantTraitData=true}
task.spawn(function()
    for _,obj in ipairs(RS:GetDescendants()) do
        if not state.alive then return end
        if obj:IsA("ModuleScript") and moduleNames[obj.Name] then
            local done=false
            task.spawn(function()
                local ok,data=pcall(require,obj)
                if ok and type(data)=="table" and state.alive then
                    moduleCache[#moduleCache+1]=data
                    log("Crop metadata loaded: "..obj.Name)
                end
                done=true
            end)
            local started=os.clock()
            while state.alive and not done and os.clock()-started<2 do task.wait(.1) end
        end
    end
end)
local function fromModules(name,set)
    for _,data in ipairs(moduleCache) do
        local entry=data[name]
        if not entry and type(data.Plants)=="table" then entry=data.Plants[name] end
        if not entry and type(data.Crops)=="table" then entry=data.Crops[name] end
        if type(entry)=="table" then
            for _,key in ipairs(metaKeys) do addTypes(set,entry[key]) end
            -- Some trait modules index by category, with crop-name arrays.
        end
        for category,list in pairs(data) do
            if type(category)=="string" and knownTraits[string.lower(category)] and type(list)=="table" then
                if list[name]==true then addTypes(set,category) end
                for _,item in ipairs(list) do
                    if item==name then addTypes(set,category);break end
                end
            end
        end
    end
end
local function getPlantTraits(plant)
    local name=normalizeName(plant.Name)
    local set={}
    fromInstance(plant,set)
    fromModules(name,set)
    -- Preserve known fallback categories as additional candidates.
    addTypes(set,cropTraits[name])
    return name,set
end
local function qualifies(plant,trait)
    local name,types=getPlantTraits(plant)
    if next(types)==nil then state.unknown[name]=true;return false end
    state.unknown[name]=nil
    return types[trait]==true
end
connect(copyUnknown.MouseButton1Click,function()
    local names={}
    for name in pairs(state.unknown) do names[#names+1]=name end
    table.sort(names)
    local text="GAG V9.4.2 unknown crops:\n"..table.concat(names,"\n")
    if type(setclipboard)=="function" then
        log(pcall(setclipboard,text) and "Crop report copied" or "Copy failed")
    else log("Clipboard not supported") end
end)
-- Ancient Trials V9.4.2: passive diagnostics only.
-- Do not infer an outgoing offer remote from the TrialsSubmitted client response.
local trial={
    requested="?", progress=nil, target=900,
    candidates=0, protected=0, wrongCategory=0, unrecognized=0,
    fruitCount=0, lastOffer="none", remoteNames={},
    reportLines={}, scanning=false
}
local function trialReport(message)
    message=tostring(message)
    trial.reportLines[#trial.reportLines+1]=os.date("%H:%M:%S").." "..message
    if #trial.reportLines>85 then table.remove(trial.reportLines,1) end
end
local function trialStripped(s)
    return tostring(s or ""):gsub("<[^>]*>",""):gsub("%s+"," ")
end
local function trialBoolAttr(obj, key)
    local ok,v=pcall(function() return obj:GetAttribute(key) end)
    return ok and (v==true or v==1)
end
local function trialAudit()
    local count,safe,protected,wrong,unknown=0,0,0,0,0
    local seen={}
    local function examine(root)
        if not root then return end
        for _,item in ipairs(root:GetChildren()) do
            if item:IsA("Tool") and not seen[item] then
                seen[item]=true
                local raw=tostring(item.Name)
                local lower=raw:lower()
                local isFruit=lower:match("%[%d+%.?%d*%s*kg%]")~=nil
                    and not lower:find("%[age%s",1,false)
                if isFruit then
                    count+=1
                    local mutated=raw:match("^%b[]")~=nil
                    local base=raw:gsub("^%b[]%s*","")
                        :gsub("%s*%[[%d%.]+%s*[Kk][Gg]%]","")
                        :gsub("^%s+",""):gsub("%s+$","")
                    local types=cropTraits[base]
                    local fits=false
                    for _,kind in ipairs(types or {}) do
                        if kind==trial.requested then fits=true break end
                    end
                    local isProtected=mutated or
                        trialBoolAttr(item,"Favorite") or
                        trialBoolAttr(item,"Favorited") or
                        trialBoolAttr(item,"IsFavorite") or
                        trialBoolAttr(item,"Locked")
                    if isProtected then
                        protected+=1
                    elseif not types then
                        unknown+=1
                    elseif trial.requested=="?" or not fits then
                        wrong+=1
                    else
                        safe+=1
                    end
                end
            end
        end
    end
    examine(player:FindFirstChild("Backpack"))
    examine(player.Character)
    trial.candidates=safe
    trial.protected=protected
    trial.wrongCategory=wrong
    trial.unrecognized=unknown
    trial.fruitCount=count
end
local function trialReadUI()
    local discovered,points=nil,nil
    local roots={
        workspace:FindFirstChild("Interaction"),
        workspace:FindFirstChild("AncientArcLocal"),
        pg
    }
    for _,root in ipairs(roots) do
        if root and state.alive then
            local objs=root:GetDescendants()
            for n,obj in ipairs(objs) do
                if not state.alive then return end
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    local value=trialStripped(obj.Text)
                    local want=value:lower():match("looking%s+for%s+([%a]+)%s+plants")
                    if want and knownTraits[want] then discovered=knownTraits[want] end
                    local a,b=value:match("(%d+)%s*/%s*(900)")
                    if a and b and tonumber(a)<=900 then
                        local lowPath=obj:GetFullName():lower()
                        if lowPath:find("anubis",1,true) or
                           lowPath:find("trial",1,true) or
                           lowPath:find("pyramid",1,true) or points==nil then
                            points=tonumber(a)
                        end
                    end
                end
                if n%600==0 then task.wait() end
            end
        end
    end
    if discovered and discovered~=trial.requested then
        trial.requested=discovered
        trialReport("Requested trait changed to "..discovered)
        log("Ancient Trials wants: "..discovered)
    end
    if points~=nil and points~=trial.progress then
        trialReport("Entrance points: "..tostring(trial.progress or "?")..
            " -> "..tostring(points).."/900")
        trial.progress=points
    end
end
local function trialRefresh()
    if not state.alive or trial.scanning then return end
    trial.scanning=true
    local ok,err=pcall(function()
        trialReadUI()
        trialAudit()
        trialSummary.Text="Requested: "..trial.requested..
            " | Points: "..tostring(trial.progress or "?").."/900"
        local blockCount=trial.protected+trial.wrongCategory+trial.unrecognized
        trialInventoryLabel.Text=string.format(
            "Fruits: %d | Matching plain: %d\nProtected mutated/favorite: %d | Off-category: %d | Unknown: %d",
            trial.fruitCount,trial.candidates,trial.protected,
            trial.wrongCategory,trial.unrecognized)
        if trial.progress and trial.progress>=900 then
            trialFeedback.Text="Entrance ready (900/900). No more offering needed."
        elseif blockCount>0 then
            trialFeedback.Text="BULK OFFER UNSAFE: "..blockCount..
                " fruits require protection. Offer manually."
        else
            trialFeedback.Text="Manual NPC offering only | Last: "..trial.lastOffer
        end
    end)
    trial.scanning=false
    if not ok then trialReport("Scan error: "..tostring(err)) end
end
local function trialWatchRemote(obj)
    if not obj or not obj:IsA("RemoteEvent") or obj.Name~="TrialsSubmitted" then
        return
    end
    connect(obj.OnClientEvent,function(result)
        if not state.alive then return end
        local count=type(result)=="table" and result.Count or "?"
        trial.lastOffer="Count="..tostring(count)
        trialReport("SERVER TrialsSubmitted Count="..tostring(count))
        log("Trial submitted: "..tostring(count).." fruits (NOT points)")
        if state.switches.trialMonitor then task.spawn(trialRefresh) end
    end)
end
local trialRemotePaths={}
for _,obj in ipairs(events:GetDescendants()) do
    local low=obj.Name:lower()
    if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and
        (low:find("trial",1,true) or low:find("offer",1,true) or
         low:find("anubis",1,true)) then
        trialRemotePaths[#trialRemotePaths+1]=obj:GetFullName()..
            " ["..obj.ClassName.."]"
    end
    trialWatchRemote(obj)
end
table.sort(trialRemotePaths)
for _,path in ipairs(trialRemotePaths) do trialReport("REMOTE: "..path) end
connect(events.DescendantAdded,function(obj)
    if state.alive then trialWatchRemote(obj) end
end)
connect(trialScanButton.MouseButton1Click,function()
    if state.alive then task.spawn(trialRefresh) end
end)
connect(trialCopyButton.MouseButton1Click,function()
    local content="GAG V9.4.2 TRIAL REPORT (read-only)\n"..
        "Trait="..trial.requested.." Points="..
        tostring(trial.progress or "?").."/900\n"..
        "Fruits="..trial.fruitCount..
        " PlainMatching="..trial.candidates..
        " Protected="..trial.protected..
        " WrongCategory="..trial.wrongCategory..
        " Unknown="..trial.unrecognized.."\n"..
        table.concat(trial.reportLines,"\n")
    if type(setclipboard)=="function" then
        log(pcall(setclipboard,content) and "Trial report copied" or "Trial copy failed")
    else log("Clipboard unsupported") end
end)
task.spawn(function()
    while state.alive and gui.Parent do
        if state.switches.trialMonitor then trialRefresh() end
        task.wait(8)
    end
end)

local arc=remote("Events/AnubisEvent/AncientArc")
local submit=arc and arc:FindFirstChild("Submit")
local submitResult=arc and arc:FindFirstChild("SubmitResult")
local restart=arc and arc:FindFirstChild("Restart")
local function anubisCollect(now)
    if now-state.lastAnubisHarvest<5 then return end
    state.lastAnubisHarvest=now
    local trait=arc and arc:GetAttribute("Trait")
    if type(trait)~="string" or trait=="" then
        state.eventStatus="Trait unavailable" return
    end
    state.trait=trait
    local plants=plantsFolder()
    local collect=remote("Crops/Collect")
    if not plants or not collect or not collect:IsA("RemoteEvent") then
        state.eventStatus="Farm/collect missing" return
    end
    if state.inventoryKnown and state.count>=state.capacity then
        state.eventStatus="Inventory full" return
    end
    local serverNow=workspace:GetServerTimeNow()
    local batch,selected,eligible={},0,0
    local function sendBatch()
        if #batch==0 then return end
        local ok=pcall(collect.FireServer,collect,batch)
        if ok then state.harvestBatches+=1;state.fruitRequests+=#batch end
        batch={}
    end
    for _,plant in ipairs(plants:GetChildren()) do
        if not state.alive or not state.switches.anubis then return end
        if qualifies(plant,trait) then
            state.lastCrop=plant.Name
            eligible+=1
            local fruits=plant:FindFirstChild("Fruits")
            if fruits then
                for _,fruit in ipairs(fruits:GetChildren()) do
                    if fruit:IsA("Model") then
                        local done=fruit:GetAttribute("DoneGrowTime")
                        local weight=fruit:FindFirstChild("Weight")
                        if type(done)=="number" and done<=serverNow and
                           weight and weight:IsA("NumberValue") and weight.Value>0 then
                            batch[#batch+1]=fruit
                            selected+=1
                            if #batch>=20 then
                                sendBatch()
                                task.wait(.2)
                                if selected>=100 then break end
                            end
                        end
                    end
                end
            end
        end
        if selected>=100 then break end
    end
    sendBatch()
    if selected>0 then
        state.eventStatus="Collect sent: "..selected
        log("Anubis "..trait..": "..selected.." fruit refs")
    elseif eligible==0 then
        state.eventStatus="No planted crops for "..trait
    else
        state.eventStatus="Waiting for ripe "..trait
    end
end
local function requestSubmit(now)
    if not submit or not submit:IsA("RemoteEvent") then
        state.eventStatus="Submit remote missing" return
    end
    if state.pending then
        if now-state.pending.sent<10 then return end
        log("Submit timeout; retry later")
        state.pending=nil
        state.lastSubmit=now
        return
    end
    if now-state.lastSubmit<3 then return end
    state.lastSubmit=now
    state.token+=1
    local token=state.token
    state.pending={token=token,sent=now}
    local ok=pcall(submit.FireServer,submit,{Token=token,Mode="All"})
    if not ok then
        state.pending=nil
        state.eventStatus="Submit send failed"
    else
        state.submitted+=1
        state.eventStatus="Awaiting submit result"
    end
end
local function requestRestart(now)
    if not state.done or not state.switches.anubisRestart or
       state.restartBusy or state.restartFault or state.paymentLocked or
       state.awaitingNewCycle then return end
    if not restart or not restart:IsA("RemoteFunction") then
        state.eventStatus="Restart remote missing"
        return
    end
    if state.completeAt==0 then state.completeAt=now end
    local remaining=2-(now-state.completeAt)
    if remaining>0 then
        state.eventStatus=string.format("Done - restart in %.1fs (1T)",remaining)
        return
    end
    -- Lock BEFORE calling the paid endpoint: a timeout may still charge 1T.
    state.paymentLocked=true
    state.restartBusy=true
    state.lastRestart=now
    state.eventStatus="Invoking paid restart ONCE (1T)"
    log("V9.4.1: 2s delay complete; invoking paid restart ONCE")
    task.spawn(function()
        local finished=false
        local success,result=false,nil
        task.spawn(function()
            success,result=pcall(restart.InvokeServer,restart)
            finished=true
        end)
        local started=os.clock()
        while state.alive and not finished and os.clock()-started<12 do
            task.wait(.1)
        end
        if not state.alive then return end
        if not finished then
            state.restartFault=true
            state.eventStatus="Restart timed out; payment LOCKED"
            log("Restart timeout: payment LOCKED to prevent double charge")
        elseif success and type(result)=="table" and result.Success==true then
            state.restarts+=1
            state.done=false
            state.completeAt=0
            state.pending=nil
            state.awaitingNewCycle=true
            state.lastSubmit=0
            state.eventStatus="Restart confirmed; awaiting new cycle"
            log("Restart confirmed #"..state.restarts.." (1T)")
        else
            state.restartFault=true
            state.eventStatus="Restart not confirmed; payment LOCKED"
            log("Restart failed/uncertain: payment LOCKED ("..
                tostring(type(result)=="table" and result.Reason or result)..")")
        end
        state.restartBusy=false
    end)
end
if submitResult and submitResult:IsA("RemoteEvent") then
    connect(submitResult.OnClientEvent,function(result)
        if not state.alive or not state.switches.anubis or type(result)~="table" then return end
        local pending=state.pending
        if not pending then return end
        if result.Token~=nil and tonumber(result.Token)~=pending.token then return end
        state.pending=nil
        state.lastResult=os.clock()
        if result.Stage~=nil then state.stage=tostring(result.Stage) end
        if result.Success==true then
            if state.awaitingNewCycle then
                -- The first accepted new-cycle submission unlocks future restarts.
                state.awaitingNewCycle=false
                state.paymentLocked=false
                state.restartFault=false
                log("New cycle confirmed; payment lock reset")
            end
            state.accepted+=1
            state.eventStatus="Submission accepted"
            log("Submit OK | stage "..state.stage.." | added "..tostring(result.Added or "?"))
        else
            local reason=tostring(result.Reason or "Unknown")
            state.eventStatus=reason
            if reason=="Done" then
                if not state.done then
                    state.done=true
                    state.completeAt=os.clock()
                    state.completed+=1
                    log("Excavation complete; waiting 2s for 1T restart")
                end
            elseif reason=="AlreadyReady" then
                state.lastSubmit=os.clock()+2
            elseif reason=="NoneFound" then
                state.lastSubmit=os.clock()+12
            elseif reason=="TooFar" then
                state.lastSubmit=os.clock()+8
                log("Too far: stand near Anubis")
            else
                log("Submit: "..reason)
            end
        end
    end)
else
    log("SubmitResult remote unavailable")
end
-- Core automation loop
log("V9.4.2 Neon loaded - all toggles OFF; Trial monitor is read-only")
task.spawn(function()
    while state.alive and gui.Parent do
        local now=os.clock()
        local count,cap=getCapacity()
        if count and cap and cap>0 then
            state.count=count
            state.capacity=cap
            state.inventoryKnown=true
        else
            state.inventoryKnown=false
        end
        local full=state.inventoryKnown and state.count>=state.capacity
        if now-state.lastNormal>=15 then
            state.lastNormal=now
            for _,kind in ipairs({"seeds","gear","eggs"}) do
                if state.switches[kind] then normalShop(kind) end
            end
        end
        if state.switches.anubis then
            if arc then state.trait=tostring(arc:GetAttribute("Trait") or "?") end
            if state.done then
                if state.switches.anubisRestart then requestRestart(now)
                else state.eventStatus="Done - restart OFF" end
            elseif not state.restartBusy then
                anubisCollect(now)
                requestSubmit(now)
            end
        end
        if state.switches.autoJump and now-state.lastJump>=300 then
            state.lastJump=now
            local character=player.Character
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health>0 then
                humanoid.Jump=true
                state.jumpCount+=1
                log("Auto Jump #"..state.jumpCount)
            end
        end
        if not state.switches.antiAFK then
            state.afkStatus="OFF"
        elseif state.afkStatus=="OFF" then
            state.afkStatus="ARMED"
        end
        afkLabel.Text=string.format("Anti-AFK: %s | Triggers: %d",state.afkStatus,state.afkEvents)
        arcLabel.Text=string.format(
            "Trait: %s | Stage: %s\n%s | Restarts: %d",
            state.trait,state.stage,state.eventStatus,state.restarts
        )
        dashboard.Text=string.format("Accepted: %d  |  Complete: %d  |  Restart: %d\nFruit requests: %d | Auto Jump: %d",state.accepted,state.completed,state.restarts,state.fruitRequests,state.jumpCount)
        paymentLabel.Text="Paid restart (1T): "..(state.restartFault and "HALTED - CHECK PAYMENT"
            or state.awaitingNewCycle and "WAITING NEW CYCLE"
            or state.paymentLocked and "LOCKED" or "UNLOCKED")
        local unknownNames={}
        for name in pairs(state.unknown) do unknownNames[#unknownNames+1]=name end
        table.sort(unknownNames)
        cropLabel.Text="Crop: "..tostring(state.lastCrop).." | Unknown: "..#unknownNames
        unknownLabel.Text=#unknownNames==0 and "Unknown plants: none" or ("Unknown (skipped): "..table.concat(unknownNames,", "))
        status.Text=string.format("%s | Fruit: %s/%s",
            state.lastLog,
            state.inventoryKnown and tostring(state.count) or "?",
            state.inventoryKnown and tostring(state.capacity) or "?")
        task.wait(1)
    end
end)
