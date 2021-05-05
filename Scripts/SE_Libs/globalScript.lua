--[[
	Copyright (c) 2019 Brent Batch
]]--

print('Loading globalScript.lua')

sm.__globalScripts = sm.__globalScripts or { -- the only "cross mod" global
	classes = {}, -- globalscript classes
	scripts = {}
}

local errmsg = "YOU ARE NOT ALLOWED TO COPY THIS SCRIPT, THY FOUL THIEF"
while ((("").format("%s", pcall)):byte(11) ~= 98 or (("").format("%s", tonumber)):byte(11) ~= 98 or pcall(("").dump,sm.json.open)) do 
	sm.log.error(errmsg) -- if pcall/tonumber was overwritten, or if sm.json.open is overwritten
end 
local description = sm.json.open("$MOD_DATA/description.json")
local __localId = description.localId -- the localid of the mod loading this file
local __fileId = description.fileId

-- ANTI COPY: (only prevents edit when compiled)
local allowedMods = {-- high, low
	[2231331700]	= {[651579252]	= {[2505189363] = {[1679441306] = 1995097423 }}}, -- SE				84ff6b74-26d6-4f74-9552-27f3641a3d9a -- 1995097423
	[1148111301]	= {[1115375337] = {[2852876565] = {[2829216604] = true }}}, -- PROP SE				446ec9c5-427b-46e9-aa0b-7115a8a26b5c -- no fileId, not uploaded to ws
	[96000016]		= {[2199931473]	= {[2238364114] = {[487542551] = true }}},  -- MP beta local		05b8d810-8320-4a51-856a-b9d21d0f4f17 -- no fileId, not uploaded to ws
	[1205729538]	= {[2964865479]	= {[2399973361] = {[3860742921] = 896541375 }}}, -- MP beta			47ddf902-b0b8-41c7-8f0c-aff1e61e4309 -- fileId : 896541375
	[3224653203]	= {[1955743432] = {[2294195734] = {[2581950529] = 1904783067 }}}, -- Cannons pack	c0344d93-7492-46c8-88be-a61699e57041 -- fileId: 1904783067
	[1803552685]	= {[3765848779] = {[2337652927] = {[2370168497] = 1995094956 }}} -- The Modpack Weapons	6b8007ad-e076-4acb-8b55-c0bf8d45e6b1 -- fileId: 1995094956
}

local uuid = __localId:gsub('-','')
local uuid1, uuid2, uuid3, uuid4 = tonumber(uuid:sub(0,8),16), tonumber(uuid:sub(9,16),16), tonumber(uuid:sub(17,24),16), tonumber(uuid:sub(25,32),16)

if not (allowedMods[uuid1] and allowedMods[uuid1][uuid2] and allowedMods[uuid1][uuid2][uuid3] and allowedMods[uuid1][uuid2][uuid3][uuid4] and (allowedMods[uuid1][uuid2][uuid3][uuid4] == __fileId or __fileId == 0 or __fileId == nil) ) then
	while true do sm.log.error(errmsg) end
end

local thisModScriptIDs = {}

for scriptname, g_script in pairs(sm.jsonReader.readFile("Scripts/SE_Libs/globalscripts/globalscripts.json") or {}) do
	-- __localId..k so it's random but still unique (no cross mod collision)
	local success, err = pcall(dofile, "$CONTENT_"..__localId.."/Scripts/SE_Libs/globalscripts/"..g_script.script)
	if success then
		if g_script.crossModUuid then -- crossmod
			print('crossmod',g_script)
			local script = sm.__globalScripts.classes[g_script.crossModUuid..":"..scriptname]
			if script then -- it exists in global table, some other mod already loaded some version of this script
			
				print('crossmod exists already',g_script)
				-- check version and use latest one:
				if (script.version or 1) >= (_G[g_script.class].version or 1) then
					_G[g_script.class] = script -- other mod had up to date version, load in current global space
				else
					sm.__globalScripts.classes[g_script.crossModUuid..":"..scriptname].loadIntoGlobal(g_script.class, _G[g_script.class])
					sm.__globalScripts.classes[g_script.crossModUuid..":"..scriptname] = _G[g_script.class] -- gs global is most current, load into table.
				end
			else
				print('loading crossmod',g_script)
				-- doesn't exist in global table yet
				sm.__globalScripts.classes[g_script.crossModUuid..":"..scriptname] = _G[g_script.class]
			end
			print("Globalscript:loading", g_script.script)
			thisModScriptIDs[g_script.class] = g_script.crossModUuid
		else
			print('not crossmod',g_script)
			sm.__globalScripts.classes[__localId..":"..scriptname] = _G[g_script.class]
			print("Globalscript:loading", g_script.script)
			thisModScriptIDs[g_script.class] = __localId
		end
	else
		print("Globalscript:Error:",err)
	end
end

for uuid_colon_scriptclass, script in pairs(sm.__globalScripts.classes) do
	function script.loadIntoGlobal(scriptclass, otherModScript) -- other mods can call this function to load the class into this mod global
		_G[scriptclass] = otherModScript
	end
end

globalscript = {
	server_onFixedUpdate = function() end,
	client_onFixedUpdate = function() end,
	client_onDestroy = function() end,
	client_onRefresh = function() end
}

function globalscript.client_attachScript(self, scriptName, ...)
	assert(not sm.isServerMode( ), "client_attachScript is a client function")
	
	local uuid = thisModScriptIDs[scriptName]
	assert(uuid ~= nil, "GlobalScript: This script is not known!")
	
	local __scriptName = uuid..":"..scriptName
	local script = sm.__globalScripts.classes[__scriptName]
	assert(script ~= nil, "GlobalScript: This script does not exist!")
	
	local shapeUuid = self.shape:getShapeUuid()
	local params = {...}
	
	if self.__hasAttached and self.__hasAttached ~= __scriptName then -- there is already a script attached to this remote, and the part is trying to attach a different script to this, spawn new instance for this other script.
		print('this remote instance already has a globalscript attached, spawning another')
		local oldserver_onFixedUpdate = self.server_onFixedUpdate
		function self.server_onFixedUpdate(self, dt) --overwrite to create remote
			if not sm.__globalScripts.scripts[__scriptName] then -- don't do script if it already exists.
				print("gs: no remote, spawning remote shape")
				sm.shape.createPart( shapeUuid, sm.vec3.new(0,0,2000), sm.quat.identity(), false, true )
			end
			self.server_onFixedUpdate = oldserver_onFixedUpdate
			oldserver_onFixedUpdate(self, dt)
		end
		return
	end
	
	-- check if remote / create remote
	if (self.shape.worldPosition - sm.vec3.new(0,0,2000)):length()>100 then --[[not remote]]
		if not sm.__globalScripts.scripts[__scriptName] then --[[hasn't been spawned]]
		
			local oldserver_onFixedUpdate = self.server_onFixedUpdate
			function self.server_onFixedUpdate(self, dt) --overwrite to create remote
				if not sm.__globalScripts.scripts[__scriptName] then -- if it still doesn't exist ... (this is next tick)
					print("gs: no remote, spawning remote shape")
					sm.shape.createPart( shapeUuid, sm.vec3.new(0,0,2000), sm.quat.identity(), false, true )
				end
				self.server_onFixedUpdate = oldserver_onFixedUpdate
				oldserver_onFixedUpdate(self, dt)
			end
			
		end
	else -- is remote
		
		print("gs:",self.shape.id,"applies for remote")
		
		if sm.__globalScripts.scripts[__scriptName] then -- this script is already attached
			
			print('gs:',scriptName,'script already attached to a different remote!')
			local f = function() print('gs: remote:',sm.__globalScripts.scripts[__scriptName].shape.id,', (destroying) this:', self.shape.id) end
			pcall(f,nil)
			
			local server_onFixedUpdate = self.server_onFixedUpdate
			function self.server_onFixedUpdate(this, dt)
				self.shape:destroyShape() print("gs:",this.shape.id,"destroyed dupe")
			end
		else
			-- mutate to globalscript excecutor:
			print('gs:',self.shape.id,'mutating remote')
			print('remote for', scriptName)
			self.__hasAttached = __scriptName
			
			sm.__globalScripts.scripts[__scriptName] = self -- remote is known
			
			self.server_onCreate = function() end
			self.client_onCreate = function() end
			self.server_onFixedUpdate = function() end
			self.client_onFixedUpdate = function() end
			self.client_onDestroy = function() end
			
			print('gs:',scriptName,'attaching to remote - OK')
			for k, v in pairs(script) do self[k] = v end
			
			
			if not script.__isReloadedScript then -- when reloaded we don't want to excecute these
				local server_onFixedUpdate = self.server_onFixedUpdate
				self.server_onFixedUpdate = function(self, dt) -- modifying script to launch onCreate first
					self:server_onCreate(unpack(params))
					self.server_onFixedUpdate = server_onFixedUpdate
					server_onFixedUpdate(self, dt)
				end
				local client_onFixedUpdate = self.client_onFixedUpdate
				self.client_onFixedUpdate = function(self, dt) 
					self:client_onCreate(unpack(params))
					self.client_onFixedUpdate = client_onFixedUpdate
					client_onFixedUpdate(self, dt)
				end
				print('gs:',scriptName,'global script successfully created - OK')
			else
				-- call 'refresh' functions on the scripts
				if script.server_onRefresh then
					local server_onFixedUpdate = self.server_onFixedUpdate
					self.server_onFixedUpdate = function(self, dt) -- modifying script to launch onCreate first
						script.server_onRefresh(self)
						self.server_onFixedUpdate = server_onFixedUpdate
						server_onFixedUpdate(self, dt)
					end
				end
				if script.client_onRefresh then
					local client_onFixedUpdate = self.client_onFixedUpdate
					self.client_onFixedUpdate = function(self, dt) 
						script.client_onRefresh(self)
						self.client_onFixedUpdate = client_onFixedUpdate
						client_onFixedUpdate(self, dt)
					end
				end
				print('gs:',scriptName,'has been successfully reloaded and attached - OK')
			end
			
			local client_onDestroy = self.client_onDestroy
			self.client_onDestroy = function(self) -- modifying script to destroy reference to remote when remote destroyed.
				if sm.__globalScripts.scripts[__scriptName] == self then 
					print('!!!gs: removed remote - global',scriptName,'script excecution halted !!!')
				end
				sm.__globalScripts.scripts[__scriptName] = nil
				client_onDestroy(self)
			end
			
			--self.GS__refreshScript_ignore_error = function(self) 
			--	if self.shape and sm.exists(self.shape) then 
			--		self.shape:destroyShape()
			--		sm.shape.createPart( shapeUuid, sm.vec3.new(0,0,2000), sm.quat.identity(), false, true )
			--	end
			--end
			
			self.client_onRefresh = function(self)
				sm.isDev = true
				print('gs: [partclass refresh] scriptclass using',scriptName,'has been reloaded')
				print('gs: [partclass refresh] detach remote & rig remote self destruct')
				sm.__globalScripts.scripts[__scriptName] = nil -- detach remote so a new one can spawn
				self.server_onFixedUpdate = function(self)
					self.shape:destroyShape()
					print('gs: [partclass refresh] successful destroy and reboot of script',scriptName)
					sm.shape.createPart( shapeUuid, sm.vec3.new(0,0,2000), sm.quat.identity(), false, true )
				end
				sm.__globalScripts.classes[__scriptName].__isReloadedScript = true
			end
			
			script.client_reload = function() -- script can call this to refresh itself.
				sm.isDev = true
				print('gs: [rc refresh]',scriptName,'script was refreshed')
				local uuid = thisModScriptIDs[scriptName]
				for scriptname, g_script in pairs(sm.jsonReader.readFile("Scripts/SE_Libs/globalscripts/globalscripts.json") or {}) do
					if uuid..":"..scriptname == __scriptName then -- find scriptclass that has been reloaded.
						
						print('gs: [rc refresh] detach remote & rig remote self destruct')
						sm.__globalScripts.scripts[__scriptName] = nil -- detach remote so a new one can spawn
						
						-- rig remote to destruct
						self.server_onFixedUpdate = function(self)
							self.shape:destroyShape()
							sm.shape.createPart( shapeUuid, sm.vec3.new(0,0,2000), sm.quat.identity(), false, true )
						end
						
						--self.client_onFixedUpdate = function(self)
						--	if self.GS__refreshScript_ignore_error and self.shape and sm.exists(self.shape) then
						--		self.network:sendToServer("GS__refreshScript_ignore_error") -- in case server_onFixedUpdate is ded
						--	end
						--end
						
						print('gs: [rc refresh] getting reloaded script:',g_script.script)
						sm.__globalScripts.classes[__scriptName] = _G[g_script.class] -- load new script
						sm.__globalScripts.classes[__scriptName].__isReloadedScript = true
						
					end
				end
			end
			
		end
	end
	
end

