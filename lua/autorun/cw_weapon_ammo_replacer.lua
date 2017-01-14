
if !ConVarExists("cw_crate_content_replacer") then
    CreateConVar("cw_crate_content_replacer", 1, { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE }, "Replace the content of dynamic crates to include CW Ammo. Needs restart to apply.")
end

if !ConVarExists("cw_crate_replacer_ratio") then
    CreateConVar("cw_crate_replacer_ratio", 0.3 , { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE }, "Replace crates themselves with CW Ammo crates. 0 = no crates replaced, 0.5 = 50% replaced etc., 1 = all crates replaced. Needs restart to apply.")
end

CWWeaponReplacerSettings = { weapon_pistol = {{"cw_deagle",1}}, 
                             weapon_smg1 = {{}},
                             weapon_ar2 = {{}},
                             weapon_shotgun = {{}},
                             weapon_rpg = {{}},
                             weapon_frag = {{}},
                             weapon_357 = {{}},
                             weapon_crossbow = {{}},
                             weapon_crowbar = {{}}
                           }

if SERVER then
util.AddNetworkString("CWWeaponReplacerSettings")
net.Receive( "CWWeaponReplacerSettings", function( len, ply )
    if !ply:IsAdmin() then return end
	CWWeaponReplacerSettings = net.ReadTable()
end)
end

function CWWeaponReplacerSettingsPanel(CPanel)
	CPanel:AddControl( "Header", { 
		Text = "CW Weapon Replacement Settings", 
		Description = "Adjust the settings for CW Weapon Replacement" 
		})
    local WepList
    local DComboBox = vgui.Create( "DComboBox")
    --DComboBox:SetPos( 20, 60 )
    DComboBox:SetSize( 100, 20 )
    for name,_ in pairs(CWWeaponReplacerSettings) do
        DComboBox:AddChoice( name )
    end
    DComboBox:ChooseOptionID(1)
    DComboBox.OnSelect = function( panel, index, value )
	    print( value .." was selected!" )
        WepList:Clear()
        local entry = CWWeaponReplacerSettings[value]
        if(entry ~= nil) then
            for _,subentry in pairs(entry) do
                WepList:AddLine(subentry[1],subentry[2])
            end
        end
    end
    CPanel:AddItem(DComboBox)

    WepList = vgui.Create( "DListView" )
    WepList:SetSize(100, 300)
    WepList:SetMultiSelect( false )
    WepList:AddColumn( "Replacement" ):SetFixedWidth(200)
    WepList:AddColumn( "Weight" )
    --WepList:AddLine( "weapon_silverballer", "1" )
    CPanel:AddItem(WepList)

    local TextEntry = vgui.Create( "DTextEntry" )
    TextEntry:SetSize( 100, 20 )
    --TextEntry:SetText( "Sample String" )
    TextEntry.OnEnter = function( self )
        chat.AddText( self:GetValue() )	-- print the form's text as server text
    end
    CPanel:AddItem(TextEntry)

    local AddButton = vgui.Create( "DButton" )
    AddButton:SetText( "Add" )
    AddButton:SetSize( 40, 20 )
    AddButton.DoClick = function()
        print( "Button was clicked!" )
        --print( "Selected lines "..WepList:GetSelectedLine())
        --PrintTable(WepList:GetSelected():GetColumnText())
        local textentry = TextEntry:GetValue()
        local entry,_ = DComboBox:GetSelected()
        local found
        for i,listent in pairs(CWWeaponReplacerSettings[entry]) do
            if listent[1] == TextEntry:GetValue() then
                found = i
            end
        end
        if (found == nil) then
            local len = #CWWeaponReplacerSettings[entry]
            CWWeaponReplacerSettings[entry][len+1] = {textentry,1}
            WepList:AddLine(textentry,1)
        else
            CWWeaponReplacerSettings[entry][found] = {textentry,1}
        end
        --found = nil
        --for k,v in pairs(list:GetLines()) do
        --    if(v ==  textentry)
        --        found = i
        --    end
        --end
        --if found == nil then  
        --end
        net.Start( "CWWeaponReplacerSettings" )
        net.WriteTable(CWWeaponReplacerSettings)
        net.SendToServer()
    end
    CPanel:AddItem(AddButton)

    local RemoveButton = vgui.Create( "DButton" )
    RemoveButton:SetText( "Remove" )
    RemoveButton:SetSize( 40, 20 )
    RemoveButton.DoClick = function()
        print( "Button was clicked also!" )
        local entry,_ = DComboBox:GetSelected()
        local line = WepList:GetSelected()[1]
        if line ~= nil then
            for k,v in pairs(CWWeaponReplacerSettings[entry]) do
                if v[1] == line:GetColumnText(1) then
                    print(v)
                    PrintTable(CWWeaponReplacerSettings[entry])
                    CWWeaponReplacerSettings[entry][k] = {}
                end
            end
            WepList:RemoveLine(WepList:GetSelectedLine())
        end
        net.Start( "CWWeaponReplacerSettings" )
        net.WriteTable(CWWeaponReplacerSettings)
        net.SendToServer()
    end
    CPanel:AddItem(RemoveButton)

end

function CWWeaponReplacerSettingsAddPanel()
	spawnmenu.AddToolMenuOption( "Options", "Weapon Replacer", "CWWeaponReplacer", "Weapon Replacement Settings", "", "", CWWeaponReplacerSettingsPanel, {} )
end
hook.Add( "PopulateToolMenu", "CWWeaponReplacerSettings", CWWeaponReplacerSettingsAddPanel )

function cw_replace_crates()
    for _,crate in pairs( ents.FindByClass("item_item_crate") ) do
        --PrintTable(crate:GetKeyValues())
        if (math.random() < GetConVar("cw_crate_replacer_ratio"):GetFloat()) and (crate:GetKeyValues()["ItemClass"] == "item_dynamic_resupply") then
            print("Replacing crate")
            local cwcrate = ents.Create("cw_ammo_crate_small")
            --print("old crate pos: ")
            --print(Vector(crate:GetPos()))
            cwcrate:SetPos(crate:GetPos())
            print("new crate pos: ")
            print(Vector(cwcrate:GetPos()))
            crate:Remove()
            cwcrate:Spawn()
        end
    end
end

function cw_replace_weapons()

end

hook.Add( "InitPostEntity", "cw_replace_crates", cw_replace_crates )