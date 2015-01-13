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

translate_str = function ( valstr )
	local sgsub = string.gsub
	local valstr = sgsub(valstr, "\\\"", "\"")
	valstr = sgsub(valstr, "\\\\", "\\")
	valstr = sgsub(valstr, "\\/", "/")
	valstr = sgsub(valstr, "\\b", "\b")
	valstr = sgsub(valstr, "\\f", "\f")
	valstr = sgsub(valstr, "\\n", "\n")
	valstr = sgsub(valstr, "\\r", "\r")
	valstr = sgsub(valstr, "\\t", "\t")
	-- translate unicode to utf-8
	-- http://blog.sina.com.cn/s/blog_415be9600100kxpm.html
	
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

-- convert lua table value to json data string
function Unmarshal( lua_val )

end