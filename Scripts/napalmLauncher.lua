dofile "SE_Loader.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if napalmLauncher and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end


napalmLauncher = class(globalscript)
napalmLauncher.maxChildCount = -1                           
napalmLauncher.maxParentCount = 1                          
napalmLauncher.connectionInput = sm.interactable.connectionType.logic
napalmLauncher.connectionOutput = sm.interactable.connectionType.none -- none, logic, power, bearing, seated, piston, any
napalmLauncher.colorNormal = sm.color.new(0xdf7000ff)
napalmLauncher.colorHighlight = sm.color.new(0xef8010ff)
napalmLauncher.fireDelay = 60 --ticks
napalmLauncher.minForce = 40
napalmLauncher.maxForce = 45
napalmLauncher.spreadDeg = 4


function napalmLauncher.client_onRefresh(self)
	self:client_onCreate()
end
function napalmLauncher.client_onCreate(self)
	self:client_attachScript("customFire")
	self:client_attachScript("customProjectile")
	self.shooteffect = sm.effect.createEffect( "MountedPotatoRifle - Shoot", self.interactable )
	self.shooteffect:setOffsetRotation( sm.vec3.getRotation(sm.vec3.new( 1, 0, 0 ),sm.vec3.new( 0, 0, 1 )))
	self.shooteffect:setOffsetPosition( sm.vec3.new( 0, 0, 0 ))
	self.time = 0
end

function napalmLauncher.server_onCreate( self )
	self.projectileConfiguration = {
		localPosition = true,			-- when true, position is relative to shape position and rotation
	    localVelocity = true,			-- when true, position is relative to shape position and rotation
	    position = sm.vec3.new(-0.5,0,0), -- required
	    velocity = sm.vec3.new(0,0,0), -- required
	    --acceleration = 0, 			-- default: 0  				adds (acceleration*normalized velocity) to velocity each tick,
	    --friction = 0.003, 			-- default: 0.003			velocity = velocity*(1-friction)
	    --gravity = 10, 				-- default: gamegrav or 10	adds (gravity*dt) to velocity each tick
	    effect = "napalmBomb", 			-- default: "CannonShot"	effect used for the projectile
	    size = 1, 						-- default: 1 (blocks)		used for projectile collision detection
	    lifetime = 60, 					-- default: 30 (seconds)	projectile will explode after this amount of time in air
	    spawnAudio = "CannonAudio", 	-- default: nil (no audio)	effect used for the audio upon spawn
	    destructionLevel = 6, 			-- default: 6				1: cardboard, 2: cautionblock(plastic), 3: wood, 4: concrete(stone), 5: metal, 6: everything?
	    destructionRadius = 0.13, 		-- default: 0.13 (meters)	1 meter = 4 blocks
	    impulseRadius = 1, 				-- default: 0.5	(meters)	radius in which players/blocks will be pushed
	    magnitude = 3, 					-- default: 10				defines how hard players/blocks will be pushed
		explodeEffect = "PropaneTank - ExplosionSmall", 			-- default: "PropaneTank - ExplosionSmall" 	effect used for explosion
		server_onCollision = "napalmLauncher.server_projectileCollision"
	}
	self.server_spawnProjectile = customProjectile.server_spawnProjectile
end

function napalmLauncher.server_projectileCollision(projectile)

	local position = (projectile.hit and projectile.hit.pointWorld or projectile.position) + sm.vec3.new(0,0,0.25)
	local normal = sm.vec3.new(0,0,1)
	
	for i=1,30 do
		local random = sm.vec3.random() * math.random(40)/20 -- 0.05-2.0 meters
		local tangent = random - normal * random:dot(normal)
		local randomUp = sm.vec3.new(0,0, math.random(30)/20 - 0.5) -- -0.5 - 1.0
		
		customFire.server_spawnFire({}, {
			position = position,
			velocity = (randomUp + tangent)*5,
			oil = true,
			priority = true
		})
	end
	
	sm.physics.explode( position, 3, 2, 3, 20, "PropaneTank - ExplosionBig" )
end

function napalmLauncher.server_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if active and not self.timeout then
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
		if self.timeout < 0 and not active then
			self.timeout = nil
		end
	end
end

function napalmLauncher.client_onShoot(self)
	self.shootEffect:start()
end













