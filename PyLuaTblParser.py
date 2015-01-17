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

class PyLuaTblParser:

	# 读取Lua table数据，输入s为一个符合Lua table定义的字符串，
	# 无返回值；若遇到Lua table格式错误的应该抛出异常
	def load(self, s):
		list_stack = [{}] # 列表栈，缓存尚未解析完成的列表（dict或array）
		strlen = len(s) # 字符串长度
		i = 0

		# 从s的第j个字符开始解析，遇到,或}时停止
		# 解析的结果是一个元组(key, value)
		# 对于数组，key为正整数索引；对于字典key为实际解析到的内容
		def parse_item(j, index):
			assert(s[j] == "{" or s[j] == ",")
			k = j + 1
			strbuf = []
			has_key, in_content, in_quote = False, False, False
			keystr, valstr = None, None

			while k < strlen:
				# 跳过空字符
				while not in_quote and s[k] in string.whitespace: k += 1

				ch = s[k]
				# 进入[]内容解析模式
				if not in_content and ch == "[":
					in_content, has_key = True, True
				elif ch == "]":
					keystr = string(strbuf)
					strbuf.clear()
					in_content = False
				elif mode == 0 and ch == ":":
					mode = 2
				elif (mode == 1 or mode == 2) and ch == "\"":
					mode = 3
				elif mode == 3 and ch == "\"":

				elif mode == 3 and ch == "\\":
					mode = 4
				elif mode == 4:
					# handle \x
					mode = 3
				else:
					strbuf.append(ch)

				k += 1





		while i < strlen:
			ch = s[i]
			i += 1
			if ch in string.whitespace:
				continue # 跳过空白字符串
			elif ch == "{":
				list_stack.append({}) # 压栈一个新的字典，初始默认都为字典
			elif ch == "}":
				list_stack.pop()
			elif ch == ",": pass
			else: pass



	# 根据类中数据返回Lua table字符串
	def dump(self):
		pass

	# 从文件中读取Lua table字符串，f为文件路径，异常处理同1，
	# 文件操作失败抛出异常
	def loadLuaTable(self, f):
		pass

	# 将类中的内容以Lua table格式存入文件，f为文件路径，文件若
	# 存在则覆盖，文件操作失败抛出异常
	def dumpLuaTable(self, f):
		pass

	# 读取dict中的数据，存入类中，只处理数字和字符串两种类型的key，
	# 其他类型的key直接忽略
	def loadDict(self, d):
		pass

	# 返回一个dict，包含类中的数据
	def dumpDict(self):
		pass

	# 用字典d更新类中的数据，类似于字典的update
	def update(self, d):
		pass

	# 支持用[]进行赋值、读写数据的操作，类似字典
	def __getitem__(self, key):
		pass