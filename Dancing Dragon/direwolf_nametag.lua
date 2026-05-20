local chatNametag = ""
local currentNametag = ""
local tagMode = 0
local tagName = ""

local prefabCol = {
	["dark_red"] = "AA0000",
	["red"] = "FF5555",
	["gold"] = "FFAA00",
	["yellow"] = "FFFF55",
	["dark_green"] = "00AA00",
	["green"] = "55FF55",
	["aqua"] = "55FFFF",
	["dark_aqua"] = "00AAAA",
	["dark_blue"] = "0000AA",
	["blue"] = "5555FF",
	["light_purple"] = "FF55FF",
	["dark_purple"] = "AA00AA",
	["white"] = "FFFFFF",
	["gray"] = "AAAAAA",
	["dark_gray"] = "555555",
	["black"] = "000000"
}

local tagOnHover =  --default hovertag
{ action = "show_text", contents = {
                { text = tagName, bold = false, color = "white" },
   		{ text = "@", bold = false, color = "gold" },
   		{ text = "That1DireWolf", bold = false, color = "white" }
}}

local function overloaded()
        local fns = {}
        local mt = {}
        
        local function oerror()
            return error("Invalid argument types to overloaded function")
        end
        
        function mt:__call(...)
            local arg = {...}
            local default = self.default
            
            local signature = {}
            for i,arg in ipairs {...} do
                signature[i] = type(arg)
            end
            
            signature = table.concat(signature, ",")
            
            return (fns[signature] or self.default)(...)
        end
        
        function mt:__index(key)
            local signature = {}
            local function __newindex(self, key, value)
                signature[#signature+1] = key
                fns[table.concat(signature, ",")] = value
            end
            local function __index(self, key)
                signature[#signature+1] = key
                return setmetatable({}, { __index = __index, __newindex = __newindex })
            end
            return __index(self, key)
        end
        
        function mt:__newindex(key, value)
            fns[key] = value
        end
        
        return setmetatable({ default = oerror }, mt)
    end

setNameplate = overloaded()
setHoverTag = overloaded()

function events.entity_init()
	setNameplate("That1DireWolf")
end

function setHoverTag.table(list)
   	table.insert(tagOnHover.contents, { text = "\n" })
   	for _, tag in ipairs(list) do
   		table.insert(tagOnHover.contents, tag)
   	end
end

local function splitString(inputstr, sep)
   -- if sep is null, set it as space
   if sep == nil then
      sep = '%s'
   end
   -- define an array
   local t={}
   -- split string based on sep   
   for str in string.gmatch(inputstr, '([^'..sep..']+)') 
   do
      -- insert the substring in table
      table.insert(t, str)
   end
   -- return the array
   return t
end

function setHoverTag.string(str)
	local tagText = str
	local tagComponent = {}
	local hoverTagContent = { { text = "\n" } }
	for _, component in ipairs(splitString(str, '}')) do
	   	for _, string in ipairs(splitString(component, ',')) do
	   		if string.match(string, "\\n") then
   				table.insert(hoverTagContent, hoverTagContent[1])
   				string = string.gsub(string, "\\n", "")
   			end
	   		if string.match(string, '"text":', 1) then
	   			data = string.sub(string.match(string, ':".*"'), 3, -2)
	   			tagComponent.text = data
	   		elseif string.match(string, '"bold":', 1) then
	   			if string.match(string.match(string, ":[tf]"), "t") ~= nil then
	   				data = true
	   				tagComponent.bold = data
	   			else
	   				data = false
	   				tagComponent.bold = data
	   			end
	   		elseif string.match(string, '"italic":', 1) then
	   			if string.match(string.match(string, ":[tf]"), "t") ~= nil then
	   				data = true
	   				tagComponent.italic = data
	   			else
	   				data = false
	   				tagComponent.italic = data
	   			end
	   		elseif string.match(string, '"color":', 1) then
	   			data = string.sub(string.match(string, ':".*"'), 3, -2)
	   			tagComponent.color = data
	   		elseif string.match(string, '"strikethrough":', 1) then
	   			if string.match(string.match(string, ":[tf]"), "t") ~= nil then
	   				data = true
	   				tagComponent.strikethrough = data
	   			else
	   				data = false
	   				tagComponent.strikethrough = data
	   			end
	   		elseif string.match(string, '"obfuscated":', 1) then
	   			if string.match(string.match(string, ":[tf]"), "t") ~= nil then
	   				data = true
	   				tagComponent.obfuscated = data
	   			else
	   				data = false
	   				tagComponent.obfuscated = data
	   			end
	   		elseif string.match(string, '"underline":', 1) then
	   			if string.match(string.match(string, ":[tf]"), "t") ~= nil then
	   				data = true
	   				tagComponent.underline = data
	   			else
	   				data = false
	   				tagComponent.underline = data
	   			end
	   		end
	   	end
	   	if component ~= "]" then
	   		table.insert(hoverTagContent, tagComponent)
	   	end
	   	tagComponent = {}
	end
	if string.find(str, '{.*}', 1) == nil then
		table.insert(hoverTagContent, { text = str, bold = false, color = "white" })
	end
	for _,v in ipairs(hoverTagContent) do
		if v.text ~= nil then
			table.insert(tagOnHover.contents, v)
		end
	end
end

function setNameplate.string(name)
	avatar:setColor(149/255, 198/255, 222/255)
	chatNametag = name
	currentNametag = name
	local isJson = false
	if string.find(name, '%[{.*}%]', 1) ~= nil then
		isJson = true
		local rawcol = string.match(name, '"color":".+",', 1)
		local color = string.sub(rawcol, 10, -3)
		if string.find(color, "#") ~= nil then
			local r = tonumber(string.sub(color, 2, 3),16)
			local g = tonumber(string.sub(color, 4, 5),16)
			local b = tonumber(string.sub(color, 6, 7),16)
			avatar:setColor(r/255, g/255, b/255)
		else
			local r = tonumber(string.sub(prefabCol[color], 1, 2),16)
			local g = tonumber(string.sub(prefabCol[color], 3, 4),16)
			local b = tonumber(string.sub(prefabCol[color], 5, 6),16)
			avatar:setColor(r/255, g/255, b/255)
		end
	end
	tagName = tagNametagFormatted(isJson, name)
	nameplate.CHAT:setText(
		chatNametagFormatted(isJson, name)
	)
	nameplate.ENTITY:setText(
		entityNametagFormatted(isJson, name)
	)
	nameplate.LIST:setText(
		listNametagFormatted(isJson, name)
	)
end

function setNameplate.string.string.string(chat, entity, list)
	avatar:setColor(149/255, 198/255, 222/255)
	chatNametag = chat
	currentNametag = chat
	local isJson = false
	if string.find(chat, '%[{.*}%]', 1) ~= nil then
		isJson = true
		local rawcol = string.match(chat, '"color":".+",', 1)
		local color = string.sub(rawcol, 10, -3)
		if string.find(color, "#") ~= nil then
			local r = tonumber(string.sub(color, 2, 3),16)
			local g = tonumber(string.sub(color, 4, 5),16)
			local b = tonumber(string.sub(color, 6, 7),16)
			avatar:setColor(r/255, g/255, b/255)
		else
			local r = tonumber(string.sub(prefabCol[color], 1, 2),16)
			local g = tonumber(string.sub(prefabCol[color], 3, 4),16)
			local b = tonumber(string.sub(prefabCol[color], 5, 6),16)
			avatar:setColor(r/255, g/255, b/255)
		end
	end
	tagName = tagNametagFormatted(isJson, chat)
	nameplate.CHAT:setText(
		chatNametagFormatted(isJson, chat)
	)
	nameplate.ENTITY:setText(
		entityNametagFormatted(isJson, entity)
	)
	nameplate.LIST:setText(
		listNametagFormatted(isJson, list)
	)
end

function chatNametagFormatted(isJson, chat)
	local clientVersionRaw = client:getVersion()
	local clientVersion = {}
	clientVersion[1] = tonumber(string.sub(clientVersionRaw, 1, string.find(clientVersionRaw, "%.", 1) - 1))
	clientVersionRaw = string.sub(clientVersionRaw, string.find(clientVersionRaw, "%.", 1) + 1, -1)
	clientVersion[2] = tonumber(string.sub(clientVersionRaw, 1, string.find(clientVersionRaw, "%.", 1) - 1))
	clientVersionRaw = string.sub(clientVersionRaw, string.find(clientVersionRaw, "%.", 1) + 1, -1)
	clientVersion[3] = tonumber(clientVersionRaw)
	tagOnHover["contents"][1]["text"] = tagName
	if isJson and clientVersion[2] <= 21 and clientVersion[3] < 8 then 
		return string.gsub(string.gsub(chat, "}", ',"hoverEvent":' .. toJson(tagOnHover) .. "}"), "%[{", '["${badges} ",{', 1)
	elseif isJson and clientVersion[2] >= 21 and clientVersion[3] >= 8 then
		return string.gsub(string.gsub(chat, "}", ',"hover_event":' .. toJson(tagOnHover) .. "}"), "%[{", '["${badges} ",{', 1)
	elseif clientVersion[2] >= 21 and clientVersion[3] >= 8 then
		return '[{"color":"#95c6de","text":"${badges} ' .. chat .. '","hover_event":' .. toJson(tagOnHover) .. "}]"
	end
	return '[{"color":"#95c6de","text":"${badges} ' .. chat .. '","hoverEvent":' .. toJson(tagOnHover) .. "}]"
end

function tagNametagFormatted(isJson, entity)
	if isJson then return string.gsub(entity, "%[{", '[{"text":"${badges} "},{') .. " " end
	return entity .. " "
end

function entityNametagFormatted(isJson, entity)
	if isJson then return string.gsub(entity, "%[{", '[{"text":"${badges} "},{') end
	return '[{"text":"${badges} ' .. entity .. '","color":"#95c6de"}]'
end

function listNametagFormatted(isJson, list)
	if isJson then return string.gsub(string.gsub(list, "%[{", '[{"text":"${badges} "},{'), "}%]", '},{"text":" @","color":"gold"},{"text":"That1DireWolf","color":"white"}]') end
	if list == "That1DireWolf" then 
		return '[{"text":"${badges} That1DireWolf","color":"#95c6de"}]'
	else
		return '[{"text":"${badges} ' .. list .. '","color":"#95c6de"},{"text":" @","color":"gold"},{"text":"That1DireWolf","color":"white"}]'
	end
end

function events.chat_send_message(msg)
	local rptag = (string.find(msg, ".nick ", 1))
	if rptag ~= nil then
		if rptag == 1 then
			local rpname = string.match(msg, "%[.+%] ")
			local endrpname = string.find(msg, "%] ", 1)
			if rpname ~= nil then
				rpname = string.sub(rpname, 2, -3)
				currentNametag = rpname
				pings.changeName(false, rpname)
				nameplate.CHAT:setText(
					chatNametagFormatted(false, rpname)
				)
				local returnstring = string.sub(msg, endrpname + 2, -1)
				return returnstring
			end
		end
	end
	if currentNametag ~= chatNametag then
		local isJson = false
		if string.find(chatNametag, '%[{.*}%]', 1) ~= nil then
			isJson = true
		end
		pings.changeName(isJson, chatNametag)
		nameplate.CHAT:setText(
			chatNametagFormatted(isJson, chatNametag)
		)
	end
	return msg
end

function pings.changeName(isJson, name)
	nameplate.CHAT:setText(
		chatNametagFormatted(isJson, name)
	)
end
