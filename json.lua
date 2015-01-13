--[===============================================================[
	Author: Hongze Zhao (honze@163.com)
	Date: 2015-1-10
	Module Description:
		This is a converter module of exchanging json data string
		and lua table value.
  ]===============================================================]

module("json", package.seeall)

-------------------------- Marshal -----------------------------

-- notations of json
json_table_begin = string.byte('{')
json_table_end = string.byte('}')
json_array_begin = string.byte('[')
json_array_end = string.byte(']')
json_quote = string.byte('"')         -- only double quote is allowed in json
json_split = string.byte(',')


-- get the key string of a json object (table) item, i is the start index
-- where the key begins. A valid name string should be quoted with ".
local parse_keyname = function ( json_str, i )
	return string.find(json_str, "\"(.-)\"%s*:", i)
end

-- parse the value string and get its value
-- last matched index returned
local parse_valuestr = function ( json_str, i )
 	return string.find(json_str, "[,%[%{]?%s*(.-)%s*[,%]%}]", i)
end

-- conver value string to coresponding lua value
local to_value = function ( valstr )
	if string.byte(valstr) == json_quote then  -- a string value
		return string.sub(valstr, 2, -2)
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
	local tstack, namestack = {}, {}
	local strlen = string.find(json_str, "[%]%}]%s*$") -- search the last end char
	local mode = true  -- true:table ; false:array

	local i = 1
	while i < strlen do
		-- find the first bracket symbol
		i = string.find(json_str, "[,%{%[%]%}]", i)
		local initial_char = string.byte(json_str, i)

		print("init char = " .. string.char(initial_char), string.sub(json_str, i, i + 5), "###")

		-- a table key-value table
		if initial_char == json_table_begin or    -- {
			initial_char == json_array_begin or   -- [
			initial_char == json_split then       -- ,

			-- push empty table to stack if begins with { or [
			if initial_char == json_table_begin or initial_char == json_array_begin then
				tstack[#tstack + 1] = {}
				print("push stack size = " .. #tstack)
			end

			-- statck top table
			local t = tstack[#tstack]
			
			-- parse or make keyname
			local k, l, keyname, valuestr
			if initial_char == json_table_begin or (initial_char == json_split and mode == true) then
				mode = true
				-- get key name
				k, l, keyname = parse_keyname(json_str, i + 1)
				i = l + 1 -- update current index
			elseif initial_char == json_array_begin or (initial_char == json_split and mode == false) then
				mode = false
				keyname = tostring(#t + 1)
				i = i + 1
			end

			-- whether value or table
			local firstchar = get_firstchar(json_str, i)
			if firstchar == json_table_begin or firstchar == json_array_begin then
				namestack[#namestack + 1] = keyname
			else
				k, l, valuestr = parse_valuestr(json_str, i)
				t[keyname] = to_value(valuestr) -- ? how about nil
				i = l -- update index
			end
			--print("first char = ".. string.char(firstchar) .." keyname = " .. keyname .. " value = " .. tostring(t[keyname]))

		else -- ] or }
			-- pop top table element
			local keyname = namestack[#namestack]
			tstack[#tstack - 1][keyname] = tstack[#tstack]
			tstack[#tstack] = nil
			namestack[#namestack] = nil
			print("stacksize(after) = " .. tostring(#tstack))
			i = i + 1
		end
	end

	return tstack[1]
end

-------------------------- Unmarshal ---------------------------

-- convert lua table value to json data string
function Unmarshal( lua_val )

end