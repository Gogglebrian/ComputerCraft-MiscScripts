--Runs a Create mod pseudo-garagedoor.
--In the open position, the door is flat against the ceiling.
--To close, it first slides out past the doorway on a gantry,
--   then swings 90 degrees until perpendicular to the ground.
--To open, it swings 90 degrees outward past the doorway until parallel to the ground,
--   then slides back inside on a gantry.

--settings
gantryLength = 13
doorSwingSpeed = 4
doorMoveSpeed = 64
leverCheckDelay = 1
gantryRunningCheckDelay = 1

--Redstone sides
inRedSide = "bottom"
gearshiftRedSide = "right"
gantryRedSide = "left"

--sequenced-gearshift peripheral used to control gantry
gantry = peripheral.wrap("back")

--networked rotation speed controller
speed = peripheral.wrap("Create_RotationSpeedController_0")


--runtime vars
isOpening = false
isOpen = false
isClosing = false
isClosed = false

function setStateClosed()
	isClosed = true
	isOpening = false
	isOpen = false
	isClosing = false
end

function setStateOpen()
	isOpen = true
	isOpening = false
	isClosing = false
	isClosed = false
end

function setStateOpening()
	isOpening = true
	isOpen = false
	isClosing = false
	isClosed = false
end

function setStateClosing()
	isClosing = true
	isOpening = false
	isOpen = false
	isClosed = false
end

function setGearshiftActive(b)
	redstone.setOutput(gearshiftRedSide,b)
end

function setGantryRedActive(b)
	redstone.setOutput(gantryRedSide,b)
end

--shut: bool
function swingDoor(closing)
	speed.setTargetSpeed(doorSwingSpeed)
	setGantryRedActive(true)
	setGearshiftActive(not closing)
	--print("rotating door")
	os.sleep(0.5)
	gantry.rotate(90)
	while (gantry.isRunning()) do
		os.sleep(gantryRunningCheckDelay)
	end
end

--toShutPosition: bool
function moveDoorToPosition(closing)
	speed.setTargetSpeed(doorMoveSpeed)
	setGearshiftActive(closing)
	setGantryRedActive(false)
	os.sleep(0.5)
	gantry.move(gantryLength)
	while (gantry.isRunning()) do
		os.sleep(gantryRunningCheckDelay)
	end
end

function runOpenRoutine()
	setStateOpening()
	swingDoor(false)
	moveDoorToPosition(false)
	setStateOpen()
end

function runCloseRoutine()
	setStateClosing()
	moveDoorToPosition(true)
	swingDoor(true)
	setStateClosed()
end


----Main program starts here
--assume that the door matches the lever to begin with
if (redstone.getInput(inRedSide)) then
	print("Red input is ON, assuming door is currently closed")
	setStateClosed()
else
	print("Red input is OFF, assuming door is currently open")
	setStateOpen()
end

while true do
	if (gantry.isRunning()) then
		print("Gantry running, waiting for it to finish")
		os.sleep(gantryRunningCheckDelay)
	elseif (redstone.getInput(inRedSide) and isOpen) then
		print("Closing door")
		runCloseRoutine()
	elseif (not redstone.getInput(inRedSide) and isClosed) then
		print("Opening door")
		runOpenRoutine()
	else
		os.sleep(leverCheckDelay)
	end
end