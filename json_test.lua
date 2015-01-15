-- test cases
local json = require "json"

print(_VERSION)

if true then

	local s = "{}"
	local t = json.Marshal(s)
	print(t)
	s = "[]"
	t = json.Marshal(s)
	print(t)
end

if true then
	local s = "{\"a\":{}}"
	local t = json.Marshal(s)
	print(t.a)
end

if true then
	local s = [==[
	{
		"Jack" 	:
		[180, 75.4, "Beijing"],
		"\"" 	:
		[175, 70.3, "古巴\u6c49"]
	}
	]==]

	local t = json.Marshal(s)

	assert(t.Jack[1] == 180)
	assert(t.Jack[2] == 75.4)
	assert(t.Jack[3] == "Beijing")

	assert(t["\""][1] == 175)
	assert(t["\""][2] == 70.3)
	assert(t["\""][3] == "古巴汉")
end

if true then
	local s = [==[
	{
	    "4\"": "ff",
	    "first": [
	        2,
	        "hello",
	        5.0e-5,
	        "\u7654"
	    ],
	    "enemy": {
	        "special": [
	            "/*[\",\u6c49]"
	        ]
	    }
	}
	]==]

	local t = json.Marshal(s)

	print(json.Unmarshal(t))

	assert(t["4\""] == "ff")
	
	assert(t.first[1] == 2)
	assert(t.first[2] == "hello")
	assert(t.first[3] == 5.0e-5)
	assert(t.first[4] == "癔")

	assert(t.enemy.special[1] == "/*[\",汉]")
end

if true then

	local s = [==[
	[null, 1, null, -2, "null"]
	]==]

	local t = json.Marshal(s)

	print(t[1], t[2], t[3], t[4], t[5])

	assert(t[1] == nil)
	assert(t[2] == 1)
	assert(t[3] == nil)
	assert(t[4] == -2)
	assert(t[5] == "null")
end

if true then
	local t1 = {[2] = 1, [4] = 2}
	print(json.Unmarshal(t1))

	local t2 = {"a", "b"; a = 3}
	print(json.Unmarshal(t2))
end