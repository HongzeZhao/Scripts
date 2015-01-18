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

import string
import os

class PyLuaTblParser:

	def __init__(self):
		self.tableBegin = "{"
		self.tableEnd = "}"
		self.valueSplit = "=,};"
		self.transTable = {
			"n"  : "\n",
			"t"  : "\t",
			"b"  : "\b",
			"r"  : "\r",
			"f"  : "\f",
			"\\" : "\\",
			"\"" : "\"",
			"\'" : "\'",
			"a"  : "\a"
		}
		self.inverseTransTable = {
			"\n" : "\\n" ,
			"\t" : "\\t" ,
			"\b" : "\\b" ,
			"\r" : "\\r" ,
			"\f" : "\\f" ,
			"\\" : "\\\\",
			"\"" : "\\\"",
			"\'" : "\\\'",
			"\a" : "\\a"
		}
		self.dataDict = dict()
		self.hexTable = "xX"
		self.floatTable = ".eE"
		self.intTable = "01234567890+-"

	# 读取Lua table数据，输入s为一个符合Lua table定义的字符串，
	# 无返回值；若遇到Lua table格式错误的应该抛出异常
	def load(self, s):
		list_stack, index_stack, name_stack, type_stack = [{}], [], ["result"], [True] # 列表栈，缓存尚未解析完成的列表（dict或array）
		strlen = len(s) # 字符串长度
		i = 0

		def parse_bracket_quote(k):
			if s[k] != '[':
				return (False, None)
			k += 1
			eqcount = 0
			while s[k] == '=':
				eqcount += 1
				k += 1
			if s[k] != '[':
				return (False, None)
			k += 1
			begin, end = k, -1
			while k < strlen:
				if s[k] == ']':
					ec = eqcount
					eq = True
					j = k + 1
					while ec > 0 and j < strlen:
						if s[j] != '=':
							eq = False
							break
						j += 1
						ec -= 1
					if eq and j < strlen and s[j] == ']':
						end = k
						break
				k += 1
			return (True, s[begin: end], end + eqcount + 1)

		def skip(k):
			prevk = -1
			while prevk < k:
				prevk = k
				while k < strlen and s[k] in string.whitespace: k += 1
				if k < strlen and s[k] == '-' and k + 1 < strlen and s[k + 1] == '-':
					k += 2
					qval = parse_bracket_quote(k)
					if qval[0]: # multiline
						k = qval[2] + 1
					else: # single line
						while k < strlen and s[k] != '\n': k += 1
			return k

		def to_val(valstr):
			if valstr[0] == '"' or valstr[0] == '\'':
				return valstr[1:-1]
			elif valstr == "nil":
				return None
			elif valstr == "true":
				return True
			elif valstr == "false":
				return False
			else:
				if all([x in self.intTable for x in valstr]):
					return string.atol(valstr)
				if any([x in self.hexTable for x in valstr]):
					return string.atol(valstr, 16)
				elif any([x in self.floatTable for x in valstr]):
					return string.atof(valstr)
				else:
					raise Exception("%s cannot convert to number" % valstr) #1

		# 从s的第j个字符开始解析，遇到,或}时停止
		# 解析的结果是一个元组(key, value)
		# 对于数组，key为正整数索引；对于字典key为实际解析到的内容
		# return 使得解析结尾的字符
		def parse_value(k):
			qval = parse_bracket_quote(k)
			if qval[0]:
				k = qval[2] + 1
				k = skip(k)
				return (k, qval[1], (s[k] == '='), False)

			strbuf = list()
			in_quote, in_trans = False, False
			quote_symbol = '"'

			while k < strlen:
				ch = s[k]
				if not in_quote and ch in self.valueSplit:
					break
				elif not in_trans:
					if ch == "\\":
						in_trans = True
					else:
						if in_quote and ch == quote_symbol:
							in_quote = False
						elif not in_quote and (ch == "\"" or ch == "'"):
							in_quote = True
							quote_symbol = ch
						strbuf.append(ch)
				elif in_trans:
					in_trans = False
					if ch == 'x':
						hexstr = '0x%s' % s[k + 1 : k + 3]
						trans_ch = chr(int(hexstr, 16))
					else:
						trans_ch = self.transTable[ch]
					assert(trans_ch)
					strbuf.append(trans_ch)
				k += 1

			val = "".join(strbuf).strip()

			is_key, is_empty = (s[k] == "="), len(val) == 0

			if not is_empty:
				if is_key:
					if val[0] == "[":
						val = val[1:-1].strip()
						if len(val) == 0:
							raise Exception("Empty Key")
						val = to_val(val)
				else:
					val = to_val(val) #2
			else:
				val = None

			return (k, val, is_key, is_empty)

		def parse_key(j):
			k = j
			if s[k] != '[':
				return parse_value(j)
			if s[k + 1] in string.whitespace: # [ xxx ], a key
				k += 1
				k = skip(k)
				qval = parse_bracket_quote(k)
				if qval[0]:
					k = qval[2] + 1
					k = skip(k)
					if s[k] != ']':
						raise Exception("Cannot match key index symbol []")
					k += 1
					k = skip(k)
					return (k, qval[1], (s[k] == '='), False)
			return parse_value(j)


		# 解析主迭代逻辑
		while i < strlen:
			i = skip(i)
			if i >= strlen: break
			ch = s[i]
			if ch == "{" or ch == "," or ch == ";":
				if ch == "{":
					list_stack.append({}) # 压栈一个新的字典，初始默认都为字典
					index_stack.append(1) # 下标从1开始
					type_stack.append(False) # 默认是list
				t = list_stack[-1] # 栈顶元素
				i += 1
				i = skip(i)

				if s[i] == "{":
					name_stack.append(index_stack[-1])
					index_stack[-1] += 1
					continue

				item = parse_key(i)
				i = item[0]
				if item[2]: # is_key : s[i] == '='
					if item[3]: raise Exception("Invalid Key")
					if not type_stack[-1]: # 如果是list
						type_stack[-1] = True # 变成dict
						old_len = len(t)
						for k, v in t.items():
							if v == None:
								del t[k]
						tlen = len(t)
						if tlen != old_len:
							squeezedt = dict()
							index = 1
							for k, v in t.items():
								squeezedt[index] = v
								index += 1
							t = list_stack[-1] = squeezedt

					key = item[1]
					i += 1
					i = skip(i)
					if s[i] == "{":
						name_stack.append(key)
					else:
						item = parse_value(i)  #3
						i = item[0]
						if item[1] != None:
							t[key] = item[1]
				else:
					if item[3]: continue
					if type_stack[-1] and item[1] == None: continue
					
					t[index_stack[-1]] = item[1]
					index_stack[-1] += 1

			elif ch == "}":
				t = list_stack.pop()
				is_dict = type_stack.pop()
				if not is_dict:
					t = [x for _, x in t.items()]
				name = name_stack.pop()
				list_stack[-1][name] = t
				index_stack.pop()
				i += 1
			else:
				raise "Parse Error"

		self.dataDict = list_stack[-1]["result"]
		assert(self.dataDict)


	# 根据类中数据返回Lua table字符串
	def dump(self):
		strbuf = list()

		def to_str(val):
			if type(val) == str:
				def get_trans_char(x):
					if x in self.inverseTransTable:
						return self.inverseTransTable[x]
					else:
						return x
				buf = [get_trans_char(x) for x in val]
				return "\"%s\"" % "".join(buf)
			elif type(val) == bool:
				if val: return "true"
				else: return "false"
			elif val == None:
				return "nil"
			else:
				return str(val)


		def dump_internal(t, depth):
			if t == None: return ""
			indent = "\t" * depth
			strbuf.append("{\n")
			if type(t) == list:
				for x in t:
					strbuf.append(indent)
					if type(x) == dict or type(x) == list:
						dump_internal(x, depth + 1)
					else:
						strbuf.append(to_str(x))
					strbuf.append(",\n")
			else:
				for k, v in t.items():
					strbuf.append(indent)
					strbuf.append("[%s]=" % to_str(k))
					if type(v) == dict or type(v) == list:
						dump_internal(v, depth + 1)
					else:
						strbuf.append(to_str(v))
					strbuf.append(",\n")
			if len(t) > 0: strbuf[-1] = "\n"
			strbuf.append(indent)
			strbuf.append("}")
			return "".join(strbuf)

		return dump_internal(self.dataDict, 0)



	# 从文件中读取Lua table字符串，f为文件路径，异常处理同1，
	# 文件操作失败抛出异常
	def loadLuaTable(self, f):
		if not os.path.exists(f):
			raise Exception("file %s not exists" % f)
		lua_file = open(f, "r")
		content = ""
		try:
			content = lua_file.readlines()
		finally:
			lua_file.close()
		content = "".join(content)
		self.load(content)

	# 将类中的内容以Lua table格式存入文件，f为文件路径，文件若
	# 存在则覆盖，文件操作失败抛出异常
	def dumpLuaTable(self, f):
		lua_file = open(f, "w")
		lua_file.write(self.dump())
		lua_file.close()

	# 读取dict中的数据，存入类中，只处理数字和字符串两种类型的key，
	# 其他类型的key直接忽略
	def loadDict(self, d):
		del self.dataDict
		self.dataDict = dict()

		# d为输入的dict/list, t为内部对应的dict/list
		def load_internal(d_input, data):
			if type(d_input) == dict:
				for k, v in d_input.items():
					if type(k) != str and type(k) != int and type(k) != long and type(k) != float:
						continue
					elif type(v) == list:
						data[k] = list()
						load_internal(v, data[k])
					elif type(v) == dict:
						data[k] = dict()
						load_internal(v, data[k])
					else:
						data[k] = v
			else:
				for v in d_input:
					if type(v) == list:
						data.append(list())
						load_internal(v, data[-1])
					elif type(v) == dict:
						data.append(dict())
						load_internal(v, data[-1])
					else:
						data.append(v)
		
		load_internal(d, self.dataDict)


	# 返回一个dict，包含类中的数据
	def dumpDict(self):
		return self.dataDict

	# 用字典d更新类中的数据，类似于字典的update
	def update(self, d):
		self.dataDict.update(d)

	# 支持用[]进行赋值、读写数据的操作，类似字典
	def __getitem__(self, key):
		if key in self.dataDict:
			return self.dataDict[key]
		else:
			return None