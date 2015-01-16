--[===============================================================[
	Author: Hongze Zhao (honze@163.com)
	Date: 2015-1-10
	Module Description:
		This is a converter module of exchanging json data string
		and lua table value.
	Lua Version: 5.2
--]===============================================================]

-- module("json", package.seeall)
local json = {}

-------------------------- Marshal -----------------------------

-- notations of json
local json_table_begin = string.byte('{')
local json_table_end = string.byte('}')
local json_array_begin = string.byte('[')
local json_array_end = string.byte(']')
local json_quote = string.byte('"')         -- only double quote is allowed in json
local json_split = string.byte(',')
local json_rsolidus = string.byte('\\')

-- json_str[i] == "
local parse_quoted_str = function ( json_str, i)
	local j, strlen = i + 1, #json_str
	local tag = false -- whetehr previous character is \
	while j < strlen do
		local ch = string.byte(json_str, j)
		if not tag then
			if ch == json_quote then break
			elseif ch == json_rsolidus then tag = true end
		else tag = false end
		j = j + 1
	end
	return i, j, string.sub(json_str, i, j)
end

local parse_keyname = function ( json_str, i )
	i = string.find(json_str, "%S", i)
	if i == nil or string.byte(json_str, i) ~= json_quote then return nil end
	local k, l = parse_quoted_str(json_str, i)
	return k, l, string.sub(json_str, k + 1, l - 1)
end

-- parse the value string and get its value
-- last matched index returned
local parse_valuestr = function ( json_str, i)
	local k, l, initial_char = string.find(json_str, "[,%[%{:]?%s*(.)", i)
	if string.byte(initial_char) ~= json_quote then
 		return string.find(json_str, "[,%[%{:]?%s*(.-)%s*[,%]%}]", i)
 	else
 		return parse_quoted_str(json_str, l)
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

local translate_str = function ( valstr )
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

-- convert json data string to lua table
function json.Marshal( json_str )
	local tstack, namestack, modestack, indexstack = {{}}, {1}, {}, {}
	local strlen = #json_str

	local i = 1
	while i <= strlen do
		-- find the first bracket symbol
		i = string.find(json_str, "[,%{%[%]%}]", i)
		if i == nil then break end -- end of match
		local initial_char = string.byte(json_str, i)

		--print(string.format("i=%d : initchar=%s", i, string.char(initial_char)))

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
					indexstack[#indexstack + 1] = 1
				end
			end

			-- statck top table
			local t, mode = tstack[#tstack], modestack[#modestack]
			local is_empty = false

			-- parse or make keyname
			local k, l, keyname, valuestr
			if mode == true then -- {
				-- get key name
				k, l, keyname = parse_keyname(json_str, i + 1)

				if k == nil then -- empty object
					is_empty = true
					i = i + 1
					if string.byte(string.match(json_str, "%S", i)) ~= json_table_end then
						return nil, "json object key error"
					end
				else
					keyname = translate_str(keyname)
					i = l + 1 -- update current index
				end
			else -- [
				keyname = indexstack[#indexstack]
				indexstack[#indexstack] = keyname + 1
				i = i + 1
			end

			-- get table or array value
			if not is_empty then
				local firstchar = string.byte(string.match(json_str, "[^%s:]", i))
				if firstchar == json_table_begin or firstchar == json_array_begin then
					namestack[#namestack + 1] = keyname
					t[keyname] = keyname
				else
					k, l, valuestr = parse_valuestr(json_str, i)
					t[keyname] = to_value(valuestr)
					i = l -- update index
				end
			end

			--print(string.format("i=%d : keyname=%s(%s), val=%s(%s)", i, keyname, type(keyname), t[keyname], type(t[keyname])))

		else -- ] or }
			-- pop top table element
			local keyname = namestack[#namestack]
			if initial_char == json_array_end then
				indexstack[#indexstack] = nil
			end
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

local function tovalstr ( val )
	if val == nil then
		return "null"
	elseif type(val) == "string" then
		val = string.gsub(val, "[\"\\/\b\f\n\r\t]", reverse_translate_table)
		return string.format("\"%s\"", val)
	elseif val == true then
		return "true"
	elseif val == false then
		return "false"
	else
		return tostring(val)
	end
end

local function unmarshal_internal ( t, strs )

	-- decide is array/object, empty or not
	local is_array, is_empty = true, true
	for k in pairs(t) do
		is_empty = false
		if type(k) ~= "number" or k % 1 ~= 0 then -- is array index ?
			is_array = false
			break
		end
	end

	-- begin bracket : empty table should use object bracket {}
	if is_array and not is_empty then strs[#strs + 1] = "["
	else strs[#strs + 1] = "{" end

	-- recursively add string symbols and values
	local prevk = 1
	for k, v in pairs(t) do
		if not is_array then -- output key string
			strs[#strs + 1] = string.format("%s:", tovalstr(tostring(k)))
		else -- fill with null
			if k - prevk > 0 then
				strs[#strs + 1] = string.rep("null,", k - prevk)
			end
			prevk = k + 1
		end
		if type(v) == "table" then
			unmarshal_internal(v, strs)
		else
			strs[#strs + 1] = tovalstr(v)
		end
		strs[#strs + 1] = ","
	end
	
	if not is_empty then strs[#strs] = nil end -- remove the last comma

	if is_array and not is_empty then strs[#strs + 1] = "]"
	else strs[#strs + 1] = "}" end
end

-- convert lua table value to json data string
function json.Unmarshal ( lua_val )
	local strs = {}

	unmarshal_internal(lua_val, strs)

	return table.concat(strs)
end

return json