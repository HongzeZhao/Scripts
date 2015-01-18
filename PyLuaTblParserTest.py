# -* - coding: UTF-8 -* -
#! /usr/bin/env python

import PyLuaTblParser

test_str = '{ {  3, nil, [ [=[x]]=] ] = [==[{4}==]]]=]]==], {[3]=5}, "nil", true}, ["\\\\}]:.,f40x\\\""] = {[3]=0x45,-23e-4  ,5,},["di\\"\\tct"] = {mixed = {43,54.33e+2,false,[78e-3]=9,string = "value"},array = {3,6,4,},string = [===[value]]=]]===],},}'

# 创建解析器对象
parser = PyLuaTblParser.PyLuaTblParser()

# 加载解析lua table构造字符串
parser.load(test_str)

# print parser.dump()

# 获取字典
dump_dict = parser.dumpDict()

# 测试断言们
arr = dump_dict["\\}]:.,f40x\""]
assert(arr[3] == 0x45)
assert(arr[1] == -23e-4)
assert(arr[2] == 5)
assert(type(arr) == dict)
assert(len(arr) == 3)

d = dump_dict["di\"\tct"]
assert(type(d) == dict)
d1 = d["mixed"]
assert(d1[1] == 43)
assert(d1[2] == 54.33e+2)
assert(d1[3] == False)
assert(d1[78e-3] == 9)
assert(d1["string"] == "value")
assert(type(d1) == dict)
d2 = d["array"]
assert(d2[0] == 3)
assert(d2[1] == 6)
assert(d2[2] == 4)
assert(type(d2) == list)
assert(len(d2) == 3)
assert(d["string"] == "value]]=]")
assert(len(dump_dict) == 3)

arr2 = dump_dict[1]
assert(arr2[1] == 3)
assert(arr2["x]"] == "{4}==]]]=]")
assert(arr2[2][3] == 5)
assert(arr2[3] == "nil")
assert(arr2[4] == True)

test_str3 = r'''
{
	["root"] = {
		--[===[
		    this is a long comment, should be ignored
		    ]==]]]][[[]]]
		    .}{}!=<>,;
		--]===]
		[=[-1211111111111113e+819]=], -- a long string
		-- single line comment
		["test11111111111111111111"] = 3,
		["test string"] = 1,
		["test table"] = {["1str"] = {"array of 1 elm"}},
		["test mixed table"] = {1, 2, ["1"] = 5, nil},
		["test empty"] = {},
		["test array"] = {'a', 1, nil, true, false},
		["test array of array"] = {{}},
		["test array of arrays"] = {{}, {}},
		["test array of objects1"] = {{}, 1, 2, nil},
		["test array of objects2"] = {1, 2, {["1"] = 1}},
		["test array of objects3"] = {{["1"]=1, ["2"]=2}, {["1"]=1, ["2"]=2}},
		["99"] = -42,
		["true"] = true,
		["null"] = nil,
		["\a\b\n\\'\""] = '"\n\t\r\\\r\n',
		[ [[abcdefg]] ] = [=[helloworld]=],    
		["NULLLLLLLLLLLLLLLLLLLLLLLL"] = nil,
		["array with nil"] = {nil,nil,['3'] = 3.14,nil,nil,key = 183};
		[7] = {
			["integer"] = 1234567890,
			["real"] = -9876.543210,
			e = 0.123456789e-12,
			E = 1.234567890E+34,
			zero = 0,
			one = 1,
			empty = "",
			space = " ",
			quote = "\"",
			backslash = "\\",
			abackslash = "\\\'\'\\",
			ctrls = "\b\f\n\r\t",
			slash = "/ & \\/",
			alpha = "abcdefghijklmnopqrstuvwxyz",
			ALPHA = "ABCD",
			digit = "01234'56789",
			["special"] = "1~!@#$%^&*()_+-=[]{}|;:\',./<>?",
			array = {nil,nil},
			["comment"] = "// /* <!-- --",
			["# -- --> */"] = " ",
			[" s p a c e d "] = {1,2,3

			,
			4 , 5     ,     6        ,  7     ,     },
			["luatext"] = "{123}"
		},
		['/\\"\x08\x0c\n\r\t`1~!@#$%^&*()_+-=[]{}|;:\',./<>?'] = "test",
		[1.10] = 3,
	}
}
'''

parser.load(test_str3)

dump_dict = parser.dumpDict()
r = dump_dict['root']
assert(r[1] == '-1211111111111113e+819')
assert(r["test11111111111111111111"] == 3)
assert(r["test string"] == 1)
assert(r["test table"]["1str"][0] == "array of 1 elm")
empty_table = r["test empty"]
assert(type(empty_table) == list)
assert(len(empty_table) == 0)
test_array = r["test array"]
assert(type(test_array) == list)
assert(len(test_array) == 5)
test_array_array = r["test array of array"]
assert(type(test_array_array) == list)
assert(len(test_array_array) == 1)
assert(type(test_array_array[0]) == list)
test_array_arrays = r["test array of arrays"]
assert(type(test_array_arrays) == list)
assert(len(test_array_arrays) == 2)
mixed_table = r["test mixed table"]
assert(type(mixed_table) == dict)
assert(len(mixed_table) == 3)
assert(mixed_table["1"] == 5)
assert(mixed_table[1] == 1)


print "all pass"