dofile "SE_Loader.lua"



napalm = class(globalscript)
napalm.explodeDelay = 80
napalm.exploded = false
napalm.client_fireDelayProgress = 0

function napalm.server_onCreate(self)

end


function napalm.server_onFixedUpdate(self, dt)
	if self.count then 
		self.count = self.count + 1
		if self.count >= self.explodeDelay and not self.exploded then
			self.exploded = true
			self.count = false
			
			local position = self.shape.worldPosition + sm.vec3.new(0,0,0.25)
			local normal = sm.vec3.new(0,0,1)
			
			for i=1,30 do
				local random = sm.vec3.random() * math.random(40)/20 -- 0.05-2.0 meters
				local tangent = random - normal * random:dot(normal)
				local randomUp = sm.vec3.new(0,0, math.random(30)/20 - 0.5) -- -0.5 - 1.0
				
				customFire.server_spawnFire(self, {
					position = position,
					velocity = (randomUp + tangent)*5,
					oil = true,
					priority = true
				})
			end
			
			sm.physics.explode( self.shape.worldPosition, 3, 2, 3, 20, "PropaneTank - ExplosionBig", self.shape )
			sm.shape.destroyPart( self.shape )
		end
	end
end


function napalm.server_onProjectile(self, position, time, velocity, type )
	if self.count then
		self.count = self.count + 40
	else
		self.count = 0
		self.network:sendToClients( "client_hitActivation", collisionPosition )
	end
end

function napalm.server_onSledgehammer(self, position, player ) 
	if self.count then
		self.count = self.count + 40
	else
		self.count = 0
		self.network:sendToClients( "client_hitActivation", collisionPosition )
	end
end

function napalm.server_onExplosion(self, position, destructionLevel )
	if not self.count and sm.exists(self.shape) then
		self.network:sendToClients( "client_hitActivation", collisionPosition )
	end
	self.count = (self.count or 0) + self.explodeDelay - 5
end

function napalm.server_onCollision(self, other, position, velocity, otherVelocity, normal )
	local impactTime = sm.game.getCurrentTick()
	
	if self.impactTime and self.impactTime + 3 > impactTime then
		self.impactTime = impactTime
		return -- stupid server_onCollision triggers multiple times on impact
	end
	self.impactTime = impactTime
	
	local impactVelocity = (velocity - otherVelocity):length()
	
	if impactVelocity > 20 then
		self.count = self.explodeDelay
	elseif impactVelocity > 5 then
		if not self.count then
			self.network:sendToClients( "client_hitActivation", collisionPosition )
		end
		self.count = (self.count or 0) + 20
	end	
end



function napalm.client_onCreate(self )
	self:client_attachScript("customFire")
	local activateEffects = {
		{sm.effect.createEffect( "PropaneTank - ActivateSmall", self.interactable ), sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, -1, 0 )), sm.vec3.new(0,0.2,0) },
		{sm.effect.createEffect( "PropaneTank - ActivateSmall", self.interactable ), sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 1, 0 ) ), sm.vec3.new(0,-0.2,0) },
		{sm.effect.createEffect( "PropaneTank - ActivateSmall", self.interactable ), sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 1, 0, 0 ) ), sm.vec3.new(-0.2,0,0) },
		{sm.effect.createEffect( "PropaneTank - ActivateSmall", self.interactable ), sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( -1, 0, 0 )), sm.vec3.new(0.2,0,0) }
	}
	self.activateEffects = {}
	for k, data in pairs(activateEffects) do
		local eff, rotation, offset = unpack(data)
		eff:setOffsetRotation(rotation)
		eff:setOffsetPosition(offset)
		table.insert(self.activateEffects, eff)
	end
end

function napalm.client_onUpdate(self, dt )
	if self.client_counting then
		self.client_fireDelayProgress = self.client_fireDelayProgress + dt
		for k, v in pairs(self.activateEffects) do
			v:setParameter( "progress", self.client_fireDelayProgress / ( self.explodeDelay * ( 1 / 40 ) ) )
		end
	end
end

function napalm.client_hitActivation(self, position)
	self.client_counting = true
	for k, v in pairs(self.activateEffects) do
		v:start()
	end
end


