---
layout    : post
title     : python_tips
date      : 2015-03-23
category  : CSE
tags      : [python]
---

python 基本使用中的一些小的注意的地方

<!-- more -->

# 模块函数

## os 模块

### os.walk

os.walk(top, topdown=True, onerror=None, followlinks=False) 
返回三元组(dirpath, dirnames, filenames)

- dirpath 代表目录的路径，
- dirnames 是list，dirpath下所有子目录。
- filenames 是list，包含了非目录文件的名字，如果需要得到全路径，需要使用os.path.join(dirpath, name).

有类似的函数是os.path.walk 属于即将被淘汰的

## 其他
