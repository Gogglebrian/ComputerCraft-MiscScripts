--Autobrewer script for Full Restores & Medicinal Brew (Cobblemon+Create+ComputerCraft)
--Build: 
-- 1 Computer, with 3 Redstone Links attached:
--   - 1 Sending the redHoldOntoMedicinalBrew signal (by default attached to the bottom of the computer)
--   - 1 Receiving the redOverrideFullRestore signal (by default attached to the top)
--   - 1 Receiving the redOverrideMedicinalBrew signal (by default attached to the left)
-- 1 brewingStand, connected via modem.
-- 1 hopper (brewHopper) feeding the brewingstand from above, connected via modem.
-- 2 hoppers feeding the brewingstand from the side---one for water bottles, one for blaze powder.
-- 1 Brass Funnel/Chute pulling Full Restores from the brewingStand.
-- 1 Brass Funnel/Chute pulling Medicinal Brew from the brewingStand, with a Redstone Link receiving the redHoldOntoMedicinalBrew signal
-- 4 chests from which to pull ingredients, connected via modem:
--   - Medicinal Leek
--   - Sitrus Berry
--   - Vivichoke
--   - Lum Berry
-- 2 chests to store Full Restores and Medicinal Brews, each with a Threshold Switch and Redstone Link sending the redOverrideFullRestore/redOverrideMedicinalBrew signals respectively when the chest is full

--How it works:
-- Side hoppers keep the brewingStand full of water bottles and blaze powder. (Recommended to keep the water bottles hopper fed by a spout over a belt.)
-- This script loads one of each ingredient into the brewHopper from their respective chests via the modems, in the correct sequence per the recipe.
-- The brewHopper feeds the ingredients into the brewingStand one by one.
-- The script waits until the brewHopper is empty and the last loaded ingredient is done brewing.
-- The finished product is pulled from the hopper via chute/funnel. (If brewing Full Restores, Medicinal Brews are prevented from being pulled early by the redHoldOntoMedicinalBrew signal).
-- The next ingredients are loaded, and so on.
--
-- When storage of the selected recipe is full, the respective override signal is sent, and this script will switch to the other recipe (unless you disable that feature below.)
-- When storage of both are full, the script will stall.

-- Usage: select default recipe and update peripheral names below. Timing settings can generally be left alone.

--Available recipes
--(1) Full Restores
--(2) Medicinal Brew
selectedRecipe = 1

--should we change to next brewing recipe if current one has its redstone override set (such as when that item's storage is full)
autoSwitchRecipeOnRedOverride = true

--peripheral names
brewingStand = peripheral.wrap("minecraft:brewing_stand_0")
brewHopper = peripheral.wrap("minecraft:hopper_0")

--material chest names
leekChest = peripheral.wrap("minecraft:chest_93")
sitrusChest = peripheral.wrap("minecraft:chest_71")
vivichokeChest = peripheral.wrap("minecraft:chest_94")
lumChest = peripheral.wrap("minecraft:chest_70")

--redstone input side to halt process, depending on selected recipe (useful for shutting down when storage is full)
redOverrideFullRestore = "top"
redOverrideMedicinalBrew = "left"

--redstone output side to disable Medicinal Brew from being removed from brewing stand prematurely when brewing Full Restores
redHoldOntoMedicinalBrew = "bottom"

--timing settings
fourItemBrewDelay = 80.5
oneItemBrewDelay = 20.5
hopperNotEmptyDelay = 5
failDelay = 5


--runtime vars
hopperWasEmpty = true
startup = true
activeRecipe = 1 --recipe we're currently brewing, irrespective of the selectedRecipe setting
numberOfRecipes = 2

function incrementActiveRecipe()
	activeRecipe = activeRecipe + 1
	if activeRecipe > numberOfRecipes then
		activeRecipe = 1
	end
end

function isRedOverrideSetForAllRecipes()
	return redstone.getInput(redOverrideFullRestore) and redstone.getInput(redOverrideMedicinalBrew)
end

function isRedOverrideSetForSelectedRecipe()
	if (selectedRecipe == 1) then
		return redstone.getInput(redOverrideFullRestore)
	elseif (selectedRecipe == 2) then
		return redstone.getInput(redOverrideMedicinalBrew)
	end
end

function isRedOverrideSetForActiveRecipe()
	if (activeRecipe == 1) then
		return redstone.getInput(redOverrideFullRestore)
	elseif (activeRecipe == 2) then
		return redstone.getInput(redOverrideMedicinalBrew)
	end
end

function getFirstSlotForItem(fromChest, targetItem)
	contents = fromChest.list()
	if (contents == nil) then
		return nil
	end
	
	--loop through the fromChest's contents
	for k, v in pairs(contents) do
		--skip this item if it's not a match to our target item, if any
		if (targetItem ~= nil) then
			if (v.name ~= targetItem) then
				goto continueItemSearch
			else
				--It's a target item so return the k value or slot number
				return k
			end
		end
		
		::continueItemSearch::
	end
	
	-- no match found,
	return nil
end

function pullOneFromChestToHopper(fromChest, fromSlot, hopperSlot)
	pulled = fromChest.pushItems(peripheral.getName(brewHopper),fromSlot,1,hopperSlot)
	if (pulled >= 1) then
		return true
	end
	
	--didn't successfully grab one, quit
	return false
end

--Precondition: brew hopper empty
function loadBrewHopperForMedicinalBrew()
	--Verify we have one of each and get the slot to take from
	leekSlot = getFirstSlotForItem(leekChest, "cobblemon:medicinal_leek")
	if (leekSlot == nil) then print("Waiting for medicinal leeks") return false end
	
	--Get the items into the brewer
	if not pullOneFromChestToHopper(leekChest,leekSlot, 1) then return false end
	return true
end

--Precondition: brew hopper empty
function loadBrewHopperForFullRestore()
	--Verify we have one of each and get the slot to take from
	leekSlot = getFirstSlotForItem(leekChest, "cobblemon:medicinal_leek")
	if (leekSlot == nil) then print("Waiting for medicinal leeks") return false end
	
	sitrusSlot = getFirstSlotForItem(sitrusChest, "cobblemon:sitrus_berry")
	if (sitrusSlot == nil) then print("Waiting for sitrus berries") return false end
	
	viviSlot = getFirstSlotForItem(vivichokeChest, "cobblemon:vivichoke")
	if (viviSlot == nil) then print("Waiting for vivichokes") return false end
	
	lumSlot = getFirstSlotForItem(lumChest, "cobblemon:lum_berry")
	if	(lumSlot == nil) then print("Waiting for lum berries") return false end

	--Get the items into the brewer
	if not pullOneFromChestToHopper(leekChest,leekSlot, 1) then return false end
	if not pullOneFromChestToHopper(sitrusChest, sitrusSlot, 2) then return false end
	if not pullOneFromChestToHopper(vivichokeChest, viviSlot, 3) then return false end
	if not pullOneFromChestToHopper(lumChest, lumSlot, 4) then return false end
	return true
end

function loadBrewHopper()
	if activeRecipe == 1 then 
		return loadBrewHopperForFullRestore()
	elseif activeRecipe == 2 then 
		return loadBrewHopperForMedicinalBrew()
	else 
		return false
	end
end

function isHopperEmpty()
	return isEmpty(brewHopper)
end

function isEmpty(inventory)
	if inventory == nil then
		return false
	end
	contents = inventory.list()
	if contents == nil then
		return false
	else
		count = 0
		for k, v in pairs(contents) do
			count = count + 1
		end
		if count > 0 then
			return false
		else
			return true
		end
	end
end

function contains(inventory, item)
	if inventory == nil then
		return false
	end
	contents = inventory.list()
	if contents == nil then
		return false
	else
		for k, v in pairs(contents) do
			if (v.name == item) then
				return true
			end
		end
	end
	return false
end

--main loop
while true do

	if not isHopperEmpty() then
		hopperWasEmpty = false
		print("Waiting for hopper to empty...")
		os.sleep(hopperNotEmptyDelay)
		goto continue
	else
		--hopper IS empty
		--if it wasn't empty the last time we checked, then do a little delay to let the last ingredient brew
		if (not hopperWasEmpty) then
			os.sleep(oneItemBrewDelay)
		end
		--mark that it was empty
		hopperWasEmpty = true
	end
	
	--if there's still a lum berry or medicinal herb brewing, then wait for it to finish
	if contains(brewingStand,"cobblemon:lum_berry") or contains(brewingStand,"cobblemon:medicinal_leek") then
		os.sleep(hopperNotEmptyDelay)
		goto continue
	end
	
	if isRedOverrideSetForAllRecipes() then
		print("All redstone overrides active, halting.")
		while isRedOverrideSetForAllRecipes() do
			os.sleep(failDelay)
		end
		print("Redstone override released, resuming.")
	end
	
	--determine which recipe to brew next based on redstone overrides
	activeRecipe = selectedRecipe
	if isRedOverrideSetForSelectedRecipe() then
		if not autoSwitchRecipeOnRedOverride then
			print("Redstone override active for selected recipe, halting.")
			while isRedOverrideActiveForSelectedRecipe() do
				os.sleep(failDelay)
			end
			print("Redstone override released, resuming.")
		else
			incrementActiveRecipe()
			while isRedOverrideSetForActiveRecipe() do
				incrementActiveRecipe()
			end
			print("Selected recipe's redstone override is set. Proceeding with next recipe.")
		end
	end
	
	redstone.setOutput(redHoldOntoMedicinalBrew, activeRecipe == 1)
	
	if loadBrewHopper() then
		if (activeRecipe == 1) then 
			print("Hopper loaded for Full Restore, waiting for brewing...") 
			os.sleep(fourItemBrewDelay)
		elseif (activeRecipe == 2) then 
			print("Hopper loaded for Medicinal Brew, waiting for brewing...") 
			os.sleep(oneItemBrewDelay)
		end
	else
		os.sleep(failDelay)
	end
	::continue::
end
