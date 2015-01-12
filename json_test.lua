-- test cases
require "json"

function test( s )
	local t = json.Marshal(s)
	print(t.Jack[1], t.Jack[2], t.Jack[3])
	print(t["\""][1], t["\""][2], t["\""][3])
end

do
	local s = [==[
	{
		"Jack":[180, 75.4, "Beijing"],
		"\"":[175, 70.3, "古巴"]
	}
	]==]

	test(s)
end