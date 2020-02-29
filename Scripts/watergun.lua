dofile "SE_Loader.lua"


-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if watergun and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end
   

watergun = class(globalscript) 
watergun.maxChildCount = -1
watergun.maxParentCount = -1
watergun.connectionInput = sm.interactable.connectionType.logic
watergun.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
watergun.colorNormal = sm.color.new(0xdf7000ff)
watergun.colorHighlight = sm.color.new(0xef8010ff)
watergun.poseWeightCount = 1


function watergun.client_onRefresh(self)
	self:client_onCreate()
end
function watergun.client_onCreate(self)
	self:client_attachScript("customFire")
	self.shooteffect = sm.effect.createEffect("water", self.interactable)
	self.shooteffect:setOffsetRotation( sm.vec3.getRotation(sm.vec3.new( 1, 0, 0 ),sm.vec3.new( 0, 0, 1 )))
	self.shooteffect:setOffsetPosition( sm.vec3.new( 0, 0, 0 ))
	self.time = 0
end

function watergun.server_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local active = false
	
	for k,parent in pairs(parents) do 
		if parent.active then active = true break end 
	end
	self.interactable.active = active
	
	
	if active and not self.timeout then
		active = false
		self.timeout = 6
		local direction = sm.noise.gunSpread(-self.shape.right, 15) * 3
		local hit, result = sm.physics.raycast(self.shape.worldPosition, self.shape.worldPosition + direction)
		customFire.server_spawnWater(self, {
			position = result.valid and result.pointWorld or self.shape.worldPosition + direction, 
			velocity = sm.noise.gunSpread(direction*20, 5)
		})
	end
	
	if self.timeout then -- lazy way to generate timeout
		self.timeout = self.timeout - 1
		if self.timeout < 0 then --and not active then
			self.timeout = nil
		end
	end
end


function watergun.client_onFixedUpdate(self, dt)
	self.time = self.time + dt
	if self.interactable.active then
		if not self.shooteffect:isPlaying() or self.time > 0.8 then
			self.shooteffect:setOffsetPosition( sm.vec3.new( -0.3, 0.05, -1/100 ))
			self.shooteffect:start()
			self.time = 0
		end
	else
		if self.shooteffect:isPlaying() then
			self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
			self.shooteffect:stop()
		end
	end
end


function watergun.client_onDestroy(self)
	self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
	self.shooteffect:stop()
end
