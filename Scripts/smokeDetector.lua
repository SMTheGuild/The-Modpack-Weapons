dofile "SE_Loader.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.
if smokeDetector and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end


smokeDetector = class(globalscript) 
smokeDetector.maxChildCount = -1
smokeDetector.maxParentCount = -1
smokeDetector.connectionInput = sm.interactable.connectionType.power
smokeDetector.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
smokeDetector.colorNormal = sm.color.new(0xdf7000ff)
smokeDetector.colorHighlight = sm.color.new(0xef8010ff)

smokeDetector.range = math.sqrt(16*4) -- length2 range comparison!


function smokeDetector.client_onRefresh(self)
	self:client_onCreate()
end

function smokeDetector.client_onCreate(self)

end

function smokeDetector.server_onFixedUpdate(self)
	if not customFire then return end
	local position = self.shape.worldPosition
	local active = false
	local range;
	
	local parents = self.interactable:getParents()
	for k, v in pairs(parents) do
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"--[[tickbutton]] then
			range = (range or 0) + math.sqrt(v.power * 4)
		else
			--logic
			if not v.active then
				self.interactable.active = false
				return
			end
		end
	end
	
	range = range or self.range
	
	for k, v in pairs(customFire.fires) do
		if (position - v.position):length2() < range then
			active = true
			break
		end
	end
	self.interactable.active = active
	self.interactable.power = active and 1 or 0
end
