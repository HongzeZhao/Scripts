--[[
	Author: Hongze Zhao (honze@163.com)
	Date: 2015-1-10
	Module Description:
		This is a converter module of exchanging json data string and
		lua table value.
]]

module("json", package.seeall)

-------------------------- Marshal -----------------------------

-- notations of json
json_table_begin = string.byte('{')
json_table_end = string.byte('}')
json_array_begin = string.byte('[')
json_array_end = string.byte(']')
json_quote = string.byte('"')         -- only double quote is allowed in json


-- get the key string of a json object (table) item, i is the start index
-- where the key begins. A valid name string should be quoted.
local parse_keyname = function ( json_str, i )
	-- body
end

local marshal_internal = function( json_str, i)
	local retval = {} -- a table or array

	local begin_char = string.byte(json_str, i)
	if begin_char == json_table_begin then

		retval["a"] = 1

	elseif begin_char == json_array_begin then

		retval[1] = 1
		
	else
		print("Error: Unknown begin char.")
	end

	return retval
end

-- convert json data string to lua table
function Marshal( json_str )
	
end

-------------------------- Unmarshal ---------------------------

-- convert lua table value to json data string
function Unmarshal( lua_val )

end