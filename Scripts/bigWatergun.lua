dofile "SE_Loader.lua"


-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if bigWatergun and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end


bigWatergun = class(globalscript) 
bigWatergun.maxChildCount = -1
bigWatergun.maxParentCount = -1
bigWatergun.connectionInput = sm.interactable.connectionType.logic
bigWatergun.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
bigWatergun.colorNormal = sm.color.new(0xdf7000ff)
bigWatergun.colorHighlight = sm.color.new(0xef8010ff)
bigWatergun.poseWeightCount = 1


function bigWatergun.client_onRefresh(self)
	self:client_onCreate()
end
function bigWatergun.client_onCreate(self)
	self:client_attachScript("customProjectile")
	self.shooteffect = sm.effect.createEffect("water", self.interactable)
	self.shooteffect:setOffsetRotation( sm.vec3.getRotation(sm.vec3.new( 1, 0, 0 ),sm.vec3.new( 0, 0, 1 )))
	self.shooteffect:setOffsetPosition( sm.vec3.new( 0, 0, 0 ))
	self.time = 0
end

function bigWatergun.server_onRefresh(self)
	sm.isDev = true
	self:server_onCreate()
end
function bigWatergun.server_onCreate(self)
	self.projectileConfiguration = {
		localPosition = true,			-- when true, position is relative to shape position and rotation
	    localVelocity = true,			-- when true, position is relative to shape position and rotation
	    position = sm.vec3.new(-0.5,0,0), -- required
	    velocity = sm.vec3.new(-20,0,0), -- required
	    --acceleration = 0, 			-- default: 0  				adds (acceleration*normalized velocity) to velocity each tick,
	    --friction = 0.003, 			-- default: 0.003			velocity = velocity*(1-friction)
	    --gravity = 10, 				-- default: gamegrav or 10	adds (gravity*dt) to velocity each tick
	    effect = "waters", 			-- default: "CannonShot"	effect used for the projectile
	    size = 1, 						-- default: 1 (blocks)		used for projectile collision detection
	    lifetime = 15, 					-- default: 30 (seconds)	projectile will explode after this amount of time in air
	    --spawnAudio = "CannonAudio", 	-- default: nil (no audio)	effect used for the audio upon spawn
	    destructionLevel = 0, 			-- default: 6				1: cardboard, 2: cautionblock(plastic), 3: wood, 4: concrete(stone), 5: metal, 6: everything?
	    destructionRadius = 0.13, 		-- default: 0.13 (meters)	1 meter = 4 blocks
	    impulseRadius = 1, 				-- default: 0.5	(meters)	radius in which players/blocks will be pushed
	    magnitude = 3, 					-- default: 10				defines how hard players/blocks will be pushed
		explodeEffect = "PropaneTank - ExplosionSmall", 			-- default: "PropaneTank - ExplosionSmall" 	effect used for explosion
		server_onCollision = "bigWatergun.server_onCollision"
	}
	self.server_spawnProjectile = customProjectile.server_spawnProjectile
end

local waterinteractions = {} -- [tick] = val
local lastTick = sm.game.getCurrentTick()

function bigWatergun.server_onCollision(projectile)
	
	local tick = sm.game.getCurrentTick()
	local tickmod40 = tick%40+1
	if lastTick < tick then
		local diff = tick - lastTick
		if diff < 40 and diff > 1 then
			for x = lastTick,tick,1 do
				waterinteractions[x%40+1] = 0
			end
		end
		waterinteractions[tickmod40] = 0
		lastTick = tick
	end
	
	local lifetime = projectile.lifetime
	if lifetime < 0 or projectile.hit == true --[[no raycast]] then return end
	
	waterinteractions[tickmod40] = waterinteractions[tickmod40] + 1
	local total = 0
	for k, v in pairs(waterinteractions) do
		total = total + v
	end
	
	if total > 340 then return end
	
	
	local raycast = projectile.hit
	local projectileSpeed = projectile.velocity:length()
	
	local up = sm.vec3.new(0,0,1)
	local speed = 1
	local direction;
	local friction;
	local updown = up:dot(raycast.normalWorld) -- 1: up, -1 down
	if updown == 0 then updown = 1 end
	
	if projectileSpeed > 12 then
		speed = 5
		friction = 0.05
		direction = 
			sm.noise.gunSpread( raycast.normalWorld * 0.05, 90) + 
			sm.vec3.rotate(-projectile.velocity * 0.1, math.pi, raycast.normalWorld) -- velocity
		--print('hard',direction, projectile.velocity)
	else
		speed = 1
		friction = 0.0005
		direction = 
			sm.noise.gunSpread(up * updown * 0.15, 90) + 
			sm.vec3.rotate(-projectile.velocity*0.7, math.pi, raycast.normalWorld) + -- velocity
			(raycast.normalWorld - up * raycast.normalWorld:dot(up))*15 -- on a slant
		direction = sm.noise.gunSpread(direction, 2)
		--print('softhit',raycast.normalWorld, projectile.velocity, direction)
		if direction:length() > 5 then direction = direction/2 end
		
	end
	
	if raycast.type == "character" then
		local character = raycast:getCharacter()
		local dir = (character.worldPosition - projectile.position):normalize() * speed * 150
		dir.z = dir.z/2
		sm.physics.applyImpulse(character, dir)
	end
	
	customProjectile.server_spawnProjectile({},
	{
	    position = projectile.position - projectile.velocity:normalize()/3 + sm.vec3.new(0,0,0.1), -- required
	    velocity = direction * speed, -- required
	    --acceleration = 0, 			-- default: 0  				adds (acceleration*normalized velocity) to velocity each tick,
	    friction = friction, 			-- default: 0.003			velocity = velocity*(1-friction)
	    gravity = 8, 				-- default: gamegrav or 10	adds (gravity*dt) to velocity each tick
	    effect = "waters", 			-- default: "CannonShot"	effect used for the projectile
	    size = 1, 						-- default: 1 (blocks)		used for projectile collision detection
	    lifetime = lifetime, 					-- default: 30 (seconds)	projectile will explode after this amount of time in air
	    --spawnAudio = "CannonAudio", 	-- default: nil (no audio)	effect used for the audio upon spawn
	    destructionLevel = 0, 			-- default: 6				1: cardboard, 2: cautionblock(plastic), 3: wood, 4: concrete(stone), 5: metal, 6: everything?
	    destructionRadius = 0.13, 		-- default: 0.13 (meters)	1 meter = 4 blocks
	    impulseRadius = 1, 				-- default: 0.5	(meters)	radius in which players/blocks will be pushed
	    magnitude = 3, 					-- default: 10				defines how hard players/blocks will be pushed
		explodeEffect = "PropaneTank - ExplosionSmall", 			-- default: "PropaneTank - ExplosionSmall" 	effect used for explosion
		server_onCollision = "bigWatergun.server_onCollision"
	}
	
	
	)
end

function bigWatergun.server_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local active = false
	
	for k,parent in pairs(parents) do 
		if parent.active then active = true break end 
	end
	self.interactable.active = active
	
	
	if active and not self.timeout then
		active = false
		self.timeout = 6
		self:server_spawnProjectile(self.projectileConfiguration )
	end
	
	if self.timeout then -- lazy way to generate timeout
		self.timeout = self.timeout - 1
		if self.timeout < 0 then --and not active then
			self.timeout = nil
		end
	end
end


function bigWatergun.client_onFixedUpdate(self, dt)
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


function bigWatergun.client_onDestroy(self)
	self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
	self.shooteffect:stop()
end
