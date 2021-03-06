if CustomizableWeaponry and GetConVar("cw_crate_content_replacer"):GetBool() then
AddCSLuaFile()

ENT.Type = "point"

local healthRatio = 0.5
local armorRatio = 0.5
local ammoRatio = 0.5
local itemSpread = 10

local ammoEntPrefixes = {"cw_ammo_",  --Add custom prefixes here, if your entity ends with the ammotype name (stripped of spaces and non-alphanumeric characters)
						 "item_ammo_"
						}

if cwreplaceAmmoEntTable == nil then
cwreplaceAmmoEntTable = {  Pistol = "item_ammo_pistol", 
						SMG1 =   "item_ammo_smg1",
						SMG1_Grenade = "item_ammo_smg1_grenade",
						AR2 = "item_ammo_ar2",
						Buckshot = "item_box_buckshot",
						RPG_Round = "item_rpg_round",
						Grenade = "weapon_frag",
						[357] = "item_ammo_357",
						XBowBolt = "item_ammo_crossbow",
						AR2AltFire = "item_ammo_ar2_altfire"
					 }
end

cwreplaceIgnoreClass = {"cw_ammo_ent_base", "cw_bullet_"}

function ENT:Initialize()
	print("item_dynamic_resupply initialized")

	local p = FindNearestEntity("player", self:GetPos(), 0)
	local weapons = p:GetWeapons()
	--PrintTable(weapons)
	local playerHealthRatio = p:Health() / p:GetMaxHealth()
	local playerArmorRatio = p:Armor() / 100
	local spawnents = {}
	if( playerHealthRatio <= healthRatio) then
		table.insert(spawnents,"item_healthkit")
	end
	if( playerArmorRatio <= armorRatio) then
		table.insert(spawnents, "item_battery")
	end
	for _, wep in pairs(weapons) do
		local pammo = wep:GetPrimaryAmmoType()
		local sammo = wep:GetSecondaryAmmoType()
		local pratio = p:GetAmmoCount(pammo) / game.GetAmmoMax(pammo)
		local sratio = p:GetAmmoCount(sammo) / game.GetAmmoMax(sammo)
		local pammoname = game.GetAmmoName(pammo)
		local sammoname = game.GetAmmoName(sammo)
		if(pammoname ~= nil) then
			table.insert(spawnents, ammoNameToEntityName(pammoname))
		end

		if(sammoname ~= nil) then
			table.insert(spawnents, ammoNameToEntityName(sammoname))
		end
	end

	PrintTable(spawnents)
	shuffleTable(spawnents)

	undo.Create( "prop" )
	undo.AddEntity( self )

	local amount = math.random(3)
	for i,entname in pairs(spawnents) do
		local temp = ents.Create(entname)
		temp:SetPos(self:GetPos()+Vector(math.random(-itemSpread,itemSpread),math.random(-itemSpread,itemSpread),0))
		--temp:SetOwner(p)
		temp:Spawn()
		undo.AddEntity( temp )
		if(i == amount) then break end
	end
	spawnents = {}
	undo.SetPlayer(p) --TODO: Find better way of doing this
	undo.Finish()

	self:Remove()
end

function ammoNameToEntityName(ammoname)
	local entname = cwreplaceAmmoEntTable[ammoname]
	if entname ~= nil then
		return entname
	else
		print(ammoname)
		ammoname = ammoname:gsub("%W", "")
		for _,prefix in pairs(ammoEntPrefixes) do
			local tempname = prefix..ammoname
			print(tempname)
			local temp = ents.Create(tempname)
			if IsValid(temp) then
				temp:Remove()
				return tempname
			end
		end
	end

	return nil
end

function ENT:KeyValue(key, value)
	print("item_dynamic_resupply key: " .. key .. " value: " .. value .. " set")
end

function ENT:AcceptInput(name, activator, caller, data)
	print("item_dynamic_resupply called with name: " .. name .. " activator: " .. activator .. " caller: " .. caller .. " data: " .. data)
end

-- set range to 0 for unlimited range
function FindNearestEntity( className, pos, range)
    local nearestEnt;
    range = range ^2
    for _, ent in pairs( ents.FindByClass( className ) ) do
        local distance = (pos - ent:GetPos()):LengthSqr()
		if( distance <= range ) or (range == 0) then
            nearestEnt = ent
            range = distance
        end
    end
    
    return nearestEnt;
end
end

function shuffleTable( t )
    local rand = math.random 
    assert( t, "shuffleTable() expected a table, got nil" )
    local iterations = #t
    local j
    
    for i = iterations, 2, -1 do
        j = rand(i)
        t[i], t[j] = t[j], t[i]
    end
end

function get_crates_for_ammo()
	for i,ent in pairs(scripted_ents.GetList()) do
		local skip = false
		for _,word in pairs(cwreplaceIgnoreClass) do
			if string.find(ent["t"]["ClassName"],word) then skip = true end
		end
		local cal = ent["t"]["Caliber"]
		if(cal ~= nil) and !skip then
			print("Found ammo ent "..i.." for ammo "..cal)
			cwreplaceAmmoEntTable[cal] = i
		end
	end
end

hook.Add( "InitPostEntity", "get_crates_for_ammo", get_crates_for_ammo )