dofile "SE_Loader.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.
if smokeDetector and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end


smokeDetector = class(globalscript) 
smokeDetector.maxChildCount = -1
smokeDetector.maxParentCount = 0
smokeDetector.connectionInput = sm.interactable.connectionType.none
smokeDetector.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
smokeDetector.colorNormal = sm.color.new(0xdf7000ff)
smokeDetector.colorHighlight = sm.color.new(0xef8010ff)

smokeDetector.range = math.sqrt(8*4) -- length2 comparison!


function smokeDetector.client_onRefresh(self)
	self:client_onCreate()
end

function smokeDetector.client_onCreate(self)

end

function smokeDetector.server_onFixedUpdate(self)
	if not customFire then return end
	local position = self.shape.worldPosition
	local active = false
	local range = self.range
	for k, v in pairs(customFire.fires) do
		if (position - v.position):length2() < range then
			active = true
			break
		end
	end
	self.interactable.active = active
	self.interactable.power = active and 1 or 0
end
