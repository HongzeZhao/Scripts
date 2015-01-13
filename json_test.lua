-- test cases
require "json"

do
	local s = [==[
	{
		"Jack" 	:
		[180, 75.4, "Beijing"],
		"\"" 	:
		[175, 70.3, "古巴\u1234"]
	}
	]==]

	--print(json.translate_str("\\/"))

	--print(string.format("%q", "\r\\\r\""))

	print(string.char(230, 177, 137))

	local t = json.Marshal(s)

	print(t.Jack[1], t.Jack[2], t.Jack[3])
	print(t["\""][1], t["\""][2], t["\""][3])
end

do
	s = [==[
	{
	    "4\"": "ff",
	    "first": [
	        2,
	        "hello",
	        7.03,
	        "\u7654"
	    ],
	    "enemy": {
	        "special": [
	            "/*[]"
	        ]
	    }
	}
	]==]

end