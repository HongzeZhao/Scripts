--[===============================================================[
	Author: Hongze Zhao (honze@163.com)
	Date: 2015-1-10
	Module Description:
		This is a converter module of exchanging json data string
		and lua table value.
	Lua Version: 5.2.3
  ]===============================================================]

module("json", package.seeall)

-------------------------- Marshal -----------------------------

-- notations of json
local json_table_begin = string.byte('{')
local json_table_end = string.byte('}')
local json_array_begin = string.byte('[')
local json_array_end = string.byte(']')
local json_quote = string.byte('"')         -- only double quote is allowed in json
local json_split = string.byte(',')
local json_rsolidus = string.byte('\\')


-- get the key string of a json object (table) item, i is the start index
-- where the key begins. A valid name string should be quoted with ".
local parse_keyname = function ( json_str, i )
	return string.find(json_str, "\"(.-)\"%s*:", i)
end

-- parse the value string and get its value
-- last matched index returned
local parse_valuestr = function ( json_str, i )
	local k, l, initial_char = string.find(json_str, "[,%[%{]?%s*(.)", i)
	if string.byte(initial_char) ~= json_quote then
 		return string.find(json_str, "[,%[%{]?%s*(.-)%s*[,%]%}]", i)
 	else
 		local j, strlen = l + 1, #json_str
 		local tag = false -- whetehr previous character is \
 		while j < strlen do
 			local ch = string.byte(json_str, j)
 			if not tag and ch == json_quote then break
 			elseif ch == json_rsolidus then tag = true
 			else tag = false end
 			j = j + 1
 		end
 		return l, j, string.sub(json_str, l, j)
 	end
end

-- unicode to utf8
-- http://blog.sina.com.cn/s/blog_415be9600100kxpm.html
local unicode_utf8 = function ( unicode_str )
	local x = tonumber(unicode_str, 16)
	if x <= 0x007f then
		return string.char(x)
	elseif x <= 0x07ff then
		return string.char(
			bit32.bor(bit32.band(bit32.rshift(x, 6), 0x1f), 0xc0),
			bit32.bor(bit32.band(x, 0x3f), 0x80))
	else
		return string.char(
			bit32.bor(bit32.band(bit32.rshift(x, 12), 0x0f), 0xe0),
			bit32.bor(bit32.band(bit32.rshift(x, 6), 0x3f), 0x80),
			bit32.bor(bit32.band(x, 0x3f), 0x80))
	end
end

local translate_table = {
	["\\\""] = "\"",
	["\\\\"] = "\\",
	["\\/"]  = "/" ,
	["\\b"]  = "\b",
	["\\f"]  = "\f",
	["\\n"]  = "\n",
	["\\r"]  = "\r",
	["\\t"]  = "\t"
}

translate_str = function ( valstr )
	local valstr = string.gsub(valstr, "\\[\\\"/bfnrt]" , translate_table)
	-- translate unicode to utf-8
	valstr = string.gsub(valstr, "\\u(%x%x%x%x)", unicode_utf8)
	
	return valstr
end

-- conver value string to coresponding lua value
local to_value = function ( valstr )
	if string.byte(valstr) == json_quote then  -- a string value
		return translate_str(string.sub(valstr, 2, -2))
	elseif valstr == "null" then -- nil value
		return nil
	elseif valstr == "true" then
		return true
	elseif valstr == "false" then
		return false
	else
		return tonumber(valstr)
	end
end

-- get first unempty char
local get_firstchar = function ( json_str, i )
	return string.byte(string.match(json_str, "^%s*(%S)", i))
end

-- convert json data string to lua table
function Marshal( json_str )
	local tstack, namestack, modestack = {{}}, {1}, {}
	local strlen = #json_str

	local i = 1
	while i <= strlen do
		-- find the first bracket symbol
		i = string.find(json_str, "[,%{%[%]%}]", i)
		if i == nil then break end -- end of match
		local initial_char = string.byte(json_str, i)

		--print('initial_char' .. string.char(initial_char))

		-- a table key-value table
		if initial_char == json_table_begin or    -- {
			initial_char == json_array_begin or   -- [
			initial_char == json_split then       -- ,

			-- push empty table to stack if begins with { or [
			if initial_char == json_table_begin or initial_char == json_array_begin then
				tstack[#tstack + 1] = {}
				-- push mode stack
				if initial_char == json_table_begin then
					modestack[#modestack + 1] = true        -- table begin
				else
					modestack[#modestack + 1] = false
				end
			end

			-- statck top table
			local t, mode = tstack[#tstack], modestack[#modestack]

			-- parse or make keyname
			local k, l, keyname, valuestr
			if initial_char == json_table_begin or (initial_char == json_split and mode == true) then
				-- get key name
				k, l, keyname = parse_keyname(json_str, i + 1)
				keyname = translate_str(keyname)
				i = l + 1 -- update current index
			elseif initial_char == json_array_begin or (initial_char == json_split and mode == false) then
				keyname = #t + 1
				i = i + 1
			end

			-- whether value or table
			local firstchar = get_firstchar(json_str, i)
			if firstchar == json_table_begin or firstchar == json_array_begin then
				namestack[#namestack + 1] = keyname
				t[keyname] = keyname
			else
				k, l, valuestr = parse_valuestr(json_str, i)
				t[keyname] = to_value(valuestr) -- ? how about nil
				i = l -- update index
			end
		else -- ] or }
			-- pop top table element
			local keyname = namestack[#namestack]
			--print("pop keyname=" .. keyname)
			tstack[#tstack - 1][keyname] = tstack[#tstack]
			tstack[#tstack] = nil
			namestack[#namestack] = nil
			modestack[#modestack] = nil
			i = i + 1
		end
	end

	return tstack[1][1]
end

-------------------------- Unmarshal ---------------------------

local reverse_translate_table = {
	["\""] = "\\\"",
	["\\"] = "\\\\",
--	["/" ] = "\\/" ,
	["\b"] = "\\b" ,
	["\f"] = "\\f" ,
	["\n"] = "\\n" ,
	["\r"] = "\\r" ,
	["\t"] = "\\t"
}

local function tovalstr( val )
	if val == nil then
		return "null"
	elseif type(val) == "string" then
		val = string.gsub(val, "[\"\\/\b\f\n\r\t]", reverse_translate_table)
		return "\"" .. val .. "\""
	elseif val == true then
		return "true"
	elseif val == false then
		return "false"
	else
		return tostring(val)
	end
end

local function unmarshal_internal( t, depth, strs )
	local is_array = true

	for k, v in pairs(t) do
		if type(k) ~= "number" or k % 1 ~= 0 then
			is_array = false
			break
		end
	end 

	if is_array then strs[#strs + 1] = "["
	else strs[#strs + 1] = "{" end

	local has_val = false
	for k, v in pairs(t) do
		has_val = true
		if not is_array then
			strs[#strs + 1] = tovalstr(k) .. ":"
		end
		if type(v) == "table" then
			unmarshal_internal(v, depth + 1, strs)
		else
			strs[#strs + 1] = tovalstr(v)
		end
		strs[#strs + 1] = ","
	end
	if has_val then strs[#strs] = nil end -- remove the last comma

	if is_array then strs[#strs + 1] = "]"
	else strs[#strs + 1] = "}" end
end

-- convert lua table value to json data string
function Unmarshal( lua_val )
	local strs = {}

	unmarshal_internal(lua_val, 0, strs)

	return table.concat(strs)
end