# -* - coding: UTF-8 -* -
#! /usr/bin/env python

######################################################################
#	Author: Hongze Zhao (honze@163.com)
#	Date: 2015-1-17
#	Module Description:
#		1. 该类能读取Lua table构造式（Lua 5.2.X）定义的数据，并以Python字典的方式读写数据
#		2. 给定一个Python字典，可以更新类中的数据，并以Lua table构造式输出
#		3. 遵循Lua table构造式定义确保相同的同构数据源彼此转换后数据仍然一致
#		4. 支持将数据分别以Lua table格式存储到文件并加载回来使用
#	Python Version: 2.7
######################################################################

import PyLuaTblParser

test_str = r'''
{ 
	{  3, nil, [ [=[x]]=] ] = [==[{4}==]]]=]]==], {[3]=5}, "nil", true, ['nil']=nil,},
    ["\\}]:.,f40x\""] = {nil, a = 'be overlap', nil, nil, [3]=0x45, a = nil ,-23e-4  ,5, [10] = 0x87},
    ["di\"\tct"] = {
    	mixed = {43,54.33e+2,false,[78e-3]=9,string = "value"},
    	array = {3,6,4,},
    	string = [===[value]]=]]===],
    },
 }'''

# 创建解析器对象
parser = PyLuaTblParser.PyLuaTblParser()

# 加载解析lua table构造字符串
parser.load(test_str)

# print parser.dump()

# 获取字典
dump_dict = parser.dumpDict()

# 测试断言们
arr = dump_dict["\\}]:.,f40x\""]
assert('a' not in arr)
assert(arr[10] == 0x87)
assert(arr[4] == -23e-4)
assert(arr[5] == 5)
assert(type(arr) == dict)
assert(len(arr) == 3)

d = dump_dict["di\"\tct"]
assert(type(d) == dict)
d1 = d["mixed"]
assert(d1[1] == 43)
assert(type(d1[1]) == int) #不能用long
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
assert(arr2[3][3] == 5)
assert(arr2[4] == "nil")
assert(arr2[5] == True)
assert(len(arr2) == 5)
assert(type(arr2) == dict)

test_str = r'''
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
		["test array of objects2"] = {{["1"]=1, ["2"]=2}, {["1"]=1, ["2"]=2}},
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
			E = 1.234567890E+34,  -- some comments
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

parser.load(test_str)

dump_dict = parser.dumpDict()
r = dump_dict['root']
assert(r[1] == '-1211111111111113e+819')
assert(r["test11111111111111111111"] == 3)
assert(r["test string"] == 1)
assert(r["test table"]["1str"][0] == "array of 1 elm")
t = r["test empty"]
assert(type(t) == dict)
assert(len(t) == 0)
t = r["test array"]
assert(type(t) == list)
assert(len(t) == 5)
t = r["test array of array"]
assert(type(t) == list)
assert(len(t) == 1)
assert(type(t[0]) == dict) #尼玛，空{}应为dict
t = r["test array of arrays"]
assert(type(t) == list)
assert(len(t) == 2)
t = r["test mixed table"]
assert(type(t) == dict)
assert(len(t) == 3)
assert(t["1"] == 5)
assert(t[1] == 1)
t = r["test array of objects2"]
assert(type(t) == list)
assert(len(t) == 2)
assert(t[0]["1"] == 1)
assert(t[0]["2"] == 2)
assert(t[1]["1"] == 1)
assert(t[1]["2"] == 2)
assert(r["99"] == -42)
assert(r['true'] == True)
assert('null' not in r)
assert(r['\a\b\n\\\'\"'] == '\"\n\t\r\\\r\n')
assert(r['abcdefg'] == 'helloworld')
assert('NULLLLLLLLLLLLLLLLLLLLLLLL' not in r)
t = r['array with nil']
assert(len(t) == 2) # nil value in dict should be ignored
assert(t['3'] == 3.14)
assert(t['key'] == 183)
t = r[7]
assert(t['integer'] == 1234567890)
assert(t['real'] == -9876.543210)
assert(t['e'] == 0.123456789e-12)
assert(t['E'] == 1.234567890E+34)
assert(t['zero'] == 0)
assert(t['one'] == 1)
assert(t['empty'] == '')
assert(t['space'] == ' ')
assert(t['quote'] == '"')
assert(t['backslash'] == '\\')
assert(t['abackslash'] == '\\\'\'\\')
assert(t['ctrls'] == '\b\f\n\r\t')
assert(t['slash'] == '/ & \\/')
assert(t['alpha'] == 'abcdefghijklmnopqrstuvwxyz')
assert(t['ALPHA'] == 'ABCD')
assert(t['digit'] == '01234\'56789')
assert(t['special'] == "1~!@#$%^&*()_+-=[]{}|;:\',./<>?")
a = t['array']
assert(len(a) == 2)
assert(type(a) == list)
assert(a[0] == None)
assert(a[1] == None)
assert(t['comment'] == '// /* <!-- --')
assert(t['# -- --> */'] == ' ')
a = t[' s p a c e d ']
assert(len(a) == 7)
assert(type(a) == list)
assert(t['luatext'] == '{123}')
assert(r['/\\"\x08\x0c\n\r\t`1~!@#$%^&*()_+-=[]{}|;:\',./<>?'] == "test")
assert(r[1.10] == 3)

#print parser.dump()

test_str = r'''
{
a = 'alo\n123"',
b = "alo\n123\"",
c = '\97lo\10\04923"',
d = [[alo
123"]],
e = [==[
alo
123"]==]
}
'''

parser.load(test_str)

d = parser.dumpDict()

assert(d['a'] == d['b'])
assert(d['b'] == d['c'])
assert(d['c'] == d['d'])
assert(d['d'] == d['e'])

test_str = r'''
{
	{1,2,3,6,[4]=5},
	{1,2,3,[4]=5, nil}
}
'''

parser.load(test_str)

d = parser.dumpDict()

assert(d[0][4] == 6)
assert(4 not in d[1])

print "all pass"