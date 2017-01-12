
if !ConVarExists("cw_crate_content_replacer") then
    CreateConVar("cw_crate_content_replacer", 1, { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE }, "Replace the content of dynamic crates to include CW Ammo. Needs restart to apply.")
end

if !ConVarExists("cw_crate_replacer_ratio") then
    CreateConVar("cw_crate_replacer_ratio", 0.3 , { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE }, "Replace crates themselves with CW Ammo crates. 0 = no crates replaced, 0.5 = 50% replaced etc., 1 = all crates replaced. Needs restart to apply.")
end

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

hook.Add( "InitPostEntity", "cw_replace_crates", cw_replace_crates )