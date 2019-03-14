---
layout    : post
title     : AppleScript简介
date      : 2015-03-13
category  : CSE
tags      : [AppleScript]
---

```
tell application "Finder"
    display dialog "Hello World"
end tell
```


待学习 。。。

<!-- more -->

# 数据

## 基本类型

  类型   | 属性
--------|--------------
Boolean | True 或 False
Number  | Integer 或 Real
Text或String | 文本 字符串
Date    | 日期
Constant| 常量
List    | 列表
Record  | 字典

## 转换

使用as 进行类型转换 

## 运算符

1. +、 -、 * 、 ^、 div、 mod
2. =、 >、 <、（这三个都有几个类似的文字比较符）、start、 begin、 contain、 in 
3. and、 or、 not
4. & 合并运算符
5. every 提取运算

## 注释

- 使用 -- 来注释一行
- 使用*之间注释块

## 变量

set var_name to var_value as type 

- set myResult to the result of (make new folder at desktop)  --之前需要tell "Finder"

- Record和List类型数据引用传递，要实现深复制改set为copy
- 其他类型仅是值传递一下，后面是独立的相互不影响。

属性和变量的区别，属性在脚本退出运行后，仍然记录下它最后的值，并且下一次运行时可以被调出。因此，属性的一个用途就是记录一个脚本运行了多少次

```
property countTimes : 0
set countTimes to countTimes + 1
display dialog "这是第" & countTimes & "次运行本脚本"
```

事件处理 以“on handlerName”开始，以“end handlerName”结束  
子脚本   以“script name”开始，以“end script”结束

# AppleScipt字典

AppleScript的帮助文件

- 套装 Suite
- 命令 Command
- 对象 Class
- 属性 Property

## command

```
make v : Create a new object.
    make
        new type : The class of the new object.
        [at location specifier] : The location at which to insert the object.
        [with data any] : The initial contents of the object.
        [with properties record] : The initial values for properties of the object.
        → specifier : The new object.
```
第一行是解释：v动词命令，宗祠内容
下面是命令格式，第一要写出make，new 也是必选条目，下面括号表示可选的

```
tell application "FInder"
    make new folder at desktop with properties {name: 12 as string}
end tell
```

# 举例

## 发送邮件

```zash
--Variables
set recipientName to "mac"
set recipientAddress to "1522159413@qq.com"
set theSubject to "AppleScript Automated Email"
set theContent to "This email was created and sent using AppleScript!"


tell application "Mail"
    set theMessage to make new outgoing message with properties {subject:theSubject, content:theContent, visible:true}
    tell theMessage --"outgoing message" 响应 save close send命令 包含 to recipient 属性
        make new to recipient with properties {name:recipientName, address:recipientAddress}
        send
    end tell
end tell
```

make new outgoing message with properties ... 创建了一个outgoing message类型的对象，并赋值给theMessage。

outgoing message 对象包含有一个to recipient对象 可在字典中查看

make new to recipient with properties 。。。创建了一个 to recipient 类型对象
send 是outgoing message类型的对象可以接受的命令，还有close

## 批量旋转照片

```zsh
–- Rotates JPEG and TIFF images that are placed in the folder
on adding folder items to theFolder after receiving fileList
    display dialog “Rotating Files…” buttons {“OK”} default button 1 giving up after 2

    repeat with theFile in fileList
        set infoRec to info for theFile
        
        if (name extension of infoRec) is in {“JPG”, “JPEG”, “TIF”, “TIFF”} then
            tell application “Image Events”
                launch
                set thePic to open file (POSIX path of theFile)
                rotate thePic to angle 90
                close thePic saving yes
            end tell
        else
            display dialog “false”
        end if
    end repeat
end adding folder items to
```
