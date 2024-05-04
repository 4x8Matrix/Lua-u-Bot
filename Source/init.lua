local DiscordLuau = require("../Submodules/Discord-Luau")
local Env = require("../.env")

local Luau = require("@lune/luau")
local Task = require("@lune/task")

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

local startTime = os.time(os.date("!*t"))

local function handleExecuteCommand(interaction: DiscordLuau.DiscordInteraction)
	local executeCodeModel = DiscordLuau.DiscordModal.new("code-modal")

	executeCodeModel:setTitle("Discord-Lua(u) Code Input")
	
	executeCodeModel:addComponent(
		DiscordLuau.Components.ActionRowComponent.new()
			:addComponent(
				DiscordLuau.Components.TextInputComponent.new("text-input-0")
					:setLabel("Lua(u) source code")
					:setMinLength(1)
					:setRequired(true)
					:setStyle(DiscordLuau.Components.TextInputComponent.Style.Paragraph)
			)
	)

	interaction:sendModalAsync(executeCodeModel)
end

local function handleLifetimeCommand(interaction: DiscordLuau.DiscordInteraction)
	local currentTime = os.time(os.date("!*t"))
	local deltaTime = startTime - currentTime

	local seconds: number = math.round(deltaTime)
	local minutes: number = (seconds - deltaTime % 60) / 60
	local hours: number = (minutes - minutes % 60) / 60

	interaction:sendMessageAsync({
		content = `Alive for; {string.format("%02i:%02i:%02i", hours, minutes - hours * 60, seconds - minutes * 60)} seconds!`
	})
end

local function handleExecution(interaction: DiscordLuau.DiscordInteraction)
	local actionRowComponent = interaction.data.components["1"]
	local textInputComponent = actionRowComponent.components["1"]
	local textInputText = textInputComponent.value

	local output = ""

	local bytecode = Luau.compile(textInputText)
	local callable = Luau.load(bytecode, {
		debugName = `LuauObject<'{interaction.user.id}'>`,
		environment = {
			string = string,
			os = os,
			utf8 = utf8,
			math = math,
			debug = debug,
			buffer = buffer,
			bit32 = bit32,
			table = table,

			_VERSION = _VERSION,
			_G = { },

			unpack = unpack,
			getfenv = getfenv,
			setfenv = setfenv,
			next = next,
			pairs = pairs,
			ipairs = ipairs,
			error = error,
			newproxy = newproxy,
			assert = assert,
			rawlen = rawlen,
			tonumber = tonumber,
			rawequal = rawequal,
			getmetatable = getmetatable,
			rawset = rawset,
			gcinfo = gcinfo,
			typeof = typeof,
			type = type,
			pcall = pcall,
			xpcall = xpcall,
			tostring = tostring,
			print = function(...)
				local source = ``

				for index, value in { ... } do
					source ..= tostring(value)
				end

				output ..= source .. "\n"
			end,
			warn = function(...)
				local source = ``

				for index, value in { ... } do
					source ..= tostring(value)
				end

				output ..= `[WARN]:\n{source}\n`
			end
		}
	})

	interaction:deferAsync()

	local osTime = os.time()
	local osTimeDeferred = os.time()

	local success, yielded
	local functionExecuted = false

	Task.spawn(function()
		callable()

		functionExecuted = true
	end)

	while not functionExecuted do
		task.wait(1)

		if os.time() - osTimeDeferred > 5 then
			interaction:deferAsync()
		end

		if os.time() - osTime > 15 then
			yielded = true
			success = false

			functionExecuted = true
		end
	end

	interaction:sendMessageAsync({
		content = `**Success:** {(yielded and "🟡" or success and "🟢" or "🔴")}\n**Output:**\`\`\`lua\n{output}\`\`\``
	})
end

DiscordClient:on("Interaction", function(interaction: DiscordLuau.DiscordInteraction)
	if interaction.data.name == "execute" then
		handleExecuteCommand(interaction)
	elseif interaction.data.name == "lifetime" then
		handleLifetimeCommand(interaction)
	elseif interaction.data.customId == "code-modal" then
		handleExecution(interaction)
	end
end)

DiscordClient:on("Ready", function()
	print(`🎉 {DiscordClient.discordUser.username} is online!`)

	local permissions = DiscordLuau.DiscordPermissions.new()
		:addPermission(DiscordLuau.DiscordPermissions.Permissions.UseApplicationCommands)

	local slashCommand = DiscordLuau.ApplicationCommand.new()
		:setName("execute")
		:setDescription("Execute lua(u) code inside of the Applications sandbox.")
		:SetGuildPermissions(permissions)
	
	local lifetimeCommand = DiscordLuau.ApplicationCommand.new()
		:setName("lifetime")
		:setDescription("Query the lifetime of the current discord bot")
		:SetGuildPermissions(permissions)

	local discordPresence = DiscordLuau.DiscordPresence.new()
	local discordActivity = DiscordLuau.DiscordActivity.new()

	discordActivity:setActivityName("Lua(u) repository for updates!")
	discordActivity:setActivityType(DiscordLuau.DiscordActivity.Type.Watching)

	discordPresence:setStatus(DiscordLuau.DiscordPresence.Status.Idle)
	discordPresence:addActivity(discordActivity)
	discordPresence:setSince(0)

	DiscordClient:updatePresenceAsync(discordPresence):after(function()
		print(`Updated '{DiscordClient.discordUser.username}' preasence!`)
	end)

	DiscordClient.discordApplication:setSlashCommandsAsync({
		slashCommand, lifetimeCommand
	}):after(function(data)
		print(`🎯 Discord Slash Commands have been updated!`)
	end)
end)

DiscordClient:setVerbose(true)
DiscordClient:connectAsync()