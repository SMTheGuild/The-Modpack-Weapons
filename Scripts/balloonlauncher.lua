dofile "SE_Loader.lua"

if not bigWatergun then
	dofile("bigWatergun.lua") -- required, contains water physics.
end

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if balloonlauncher and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end
   

balloonlauncher = class(globalscript) 
balloonlauncher.maxChildCount = -1
balloonlauncher.maxParentCount = -1
balloonlauncher.connectionInput = sm.interactable.connectionType.logic
balloonlauncher.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
balloonlauncher.colorNormal = sm.color.new(0xdf7000ff)
balloonlauncher.colorHighlight = sm.color.new(0xef8010ff)
balloonlauncher.poseWeightCount = 1
balloonlauncher.fireDelay = 60 --ticks
balloonlauncher.minForce = 40
balloonlauncher.maxForce = 45
balloonlauncher.spreadDeg = 4



function balloonlauncher.client_onRefresh(self)
	self:client_onCreate()
end
function balloonlauncher.client_onCreate(self)
	self:client_attachScript("customFire")
	self:client_attachScript("customProjectile")
end

function balloonlauncher.server_onCreate(self)
	self.projectileConfiguration = {
		localPosition = true,			-- when true, position is relative to shape position and rotation
	    localVelocity = true,			-- when true, position is relative to shape position and rotation
	    position = sm.vec3.new(-0.5,0,0), -- required
	    velocity = sm.vec3.new(-20,0,0), -- required
	    --acceleration = 0, 			-- default: 0  				adds (acceleration*normalized velocity) to velocity each tick,
	    --friction = 0.003, 			-- default: 0.003			velocity = velocity*(1-friction)
	    --gravity = 10, 				-- default: gamegrav or 10	adds (gravity*dt) to velocity each tick
	    effect = "BalloonShot", 			-- default: "CannonShot"	effect used for the projectile
	    size = 0.3, 						-- default: 1 (blocks)		used for projectile collision detection
	    lifetime = 15, 					-- default: 30 (seconds)	projectile will explode after this amount of time in air
	    --spawnAudio = "CannonAudio", 	-- default: nil (no audio)	effect used for the audio upon spawn
	    destructionLevel = 0, 			-- default: 6				1: cardboard, 2: cautionblock(plastic), 3: wood, 4: concrete(stone), 5: metal, 6: everything?
	    destructionRadius = 0.13, 		-- default: 0.13 (meters)	1 meter = 4 blocks
	    impulseRadius = 1, 				-- default: 0.5	(meters)	radius in which players/blocks will be pushed
	    magnitude = 3, 					-- default: 10				defines how hard players/blocks will be pushed
		--explodeEffect = "PropaneTank - ExplosionSmall", 			-- default: "PropaneTank - ExplosionSmall" 	effect used for explosion
		server_onCollision = "balloonlauncher.server_onProjectileCollision"
	}
	self.server_spawnProjectile = customProjectile.server_spawnProjectile
end

function balloonlauncher.server_onProjectileCollision(projectile)
	
	local position = (projectile.hit and projectile.hit.pointWorld or projectile.position) + sm.vec3.new(0,0,0.25)
	local normal = sm.vec3.new(0,0,1)
	
	customFire.server_spawnWater({}, {
		position = position, 
		velocity = normal,
		radius = 35,
		power = 400
	})
	
	for x = 1,30 do
		local random = sm.vec3.random() * math.random(40)/20 -- 0.05-2.0 meters
		local tangent = random - normal * random:dot(normal)
		local randomUp = sm.vec3.new(0,0, math.random(30)/20 - 0.5) -- -0.5 - 1.0
		customProjectile.server_spawnProjectile({},
		{
			position = position, -- required
			velocity = (randomUp + tangent)*5, -- required
			--acceleration = 0, 			-- default: 0  				adds (acceleration*normalized velocity) to velocity each tick,
			--friction = friction, 			-- default: 0.003			velocity = velocity*(1-friction)
			gravity = 8, 				-- default: gamegrav or 10	adds (gravity*dt) to velocity each tick
			effect = "waters", 			-- default: "CannonShot"	effect used for the projectile
			size = 0.2, 						-- default: 1 (blocks)		used for projectile collision detection
			lifetime = 7, 					-- default: 30 (seconds)	projectile will explode after this amount of time in air
			--spawnAudio = "CannonAudio", 	-- default: nil (no audio)	effect used for the audio upon spawn
			destructionLevel = 0, 			-- default: 6				1: cardboard, 2: cautionblock(plastic), 3: wood, 4: concrete(stone), 5: metal, 6: everything?
			destructionRadius = 0.13, 		-- default: 0.13 (meters)	1 meter = 4 blocks
			impulseRadius = 1, 				-- default: 0.5	(meters)	radius in which players/blocks will be pushed
			magnitude = 3, 					-- default: 10				defines how hard players/blocks will be pushed
			explodeEffect = "PropaneTank - ExplosionSmall", 			-- default: "PropaneTank - ExplosionSmall" 	effect used for explosion
			server_onCollision = "bigWatergun.server_onProjectileCollision"
		})
	end

end

function balloonlauncher.server_onFixedUpdate(self, dt)
	local parents = self.interactable:getParents()
	local active = false
	
	for k,parent in pairs(parents) do 
		if parent.active then active = true break end 
	end
	self.interactable.active = active
	
	
	if active and not self.timeout then
		active = false
		self.timeout = self.fireDelay
		local fireForce = math.random( self.minForce, self.maxForce )
		local dir = sm.noise.gunSpread( sm.vec3.new(-1,0,0), self.spreadDeg )
		
		self.projectileConfiguration.velocity = dir * fireForce
		self:server_spawnProjectile(self.projectileConfiguration)
		
		local mass = 20
		local impulse = -dir * fireForce * mass
		sm.physics.applyImpulse( self.shape, impulse, false )
	end
	
	if self.timeout then -- lazy way to generate timeout
		self.timeout = self.timeout - 1
		if self.timeout < 0 and not active then --and not active then
			self.timeout = nil
		end
	end
end








