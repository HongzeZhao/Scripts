# -* - coding: UTF-8 -* -
#! /usr/bin/env python

import PyLuaTblParser

test_dict = {
     "array": [65, 23, 5],
     "dict": {
          "mixed": {
               1: 43,
               2: 54.33,
               3: False,
               4: 9,
               "string": "value"
          },
          "array": [3, 6, 4],
          "string": "value"
     }
}

test_str = '{array = {65,23,5,},dict = {mixed = {43,54.33,false,9,string = "value",},array = {3,6,4,},string = "value",},}'

# 创建解析器对象
parser = PyLuaTblParser.PyLuaTblParser()

# 加载解析lua table构造字符串
parser.load(test_str)

# 获取字典
dump_dict = parser.dumpDict()

# 测试断言们