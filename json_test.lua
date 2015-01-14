<<<<<<< HEAD
-- test cases
require "json"

print(_VERSION)

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
	s = [==[
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
=======
-- test cases
require "json"

print(_VERSION)

if false then
	local s = [==[
	{
		"Jack" 	:
		[180, 75.4, "Beijing"],
		"\"" 	:
		[175, 70.3, "古巴\u6c49"]
	}
	]==]

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
	            "/*[\",]"
	        ]
	    }
	}
	]==]

	local t = json.Marshal(s)

	assert(t["4\""] == "ff")
	for _, x in ipairs(t.first) do
		io.write(tostring(x) .. ", ")
	end
	io.write("\n")
>>>>>>> FETCH_HEAD
end