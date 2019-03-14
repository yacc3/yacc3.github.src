---
layout    : post  
title     : awk-sed-grep简介  
date      : 2016-03-04  
category  : CSE  
tags      : [awk,sed,grep]  
published : true  
---

about AWK - sed - grep

<!-- more -->

# 语法

[gawk](http://www.gnu.org/software/gawk/manual/gawk.html)
[sed](https://www.gnu.org/software/sed/manual/sed.html)
[grep](https://www.gnu.org/software/grep/manual/grep.html)


awk 是对输入进行逐行分析的，模式一旦匹配成功，就执行后面相应的action. awk 是文本分析程序，虽然也有技巧可以使它做各种黑活，但是太tricky了，还不如来个python明白。

sed is a stream editor. A stream editor is used to perform basic text transformations on an input stream (a file or input from a pipeline). While in some ways similar to an editor which permits scripted edits (such as ed), sed works by making only one pass over the input(s), and is consequently more efficient. But it is sed’s ability to filter text in a pipeline which particularly distinguishes it from other types of editors.

## 简单的

awk [-F] 'pattern {action}' file

```bash
awk '$3 >0 { print $1, $2 * $3 }' emp.data
cat /etc/passwd \| awk  -F ':'  '{print $1"\t"$7}'
awk '$3==0 && $6=="ESTABLE" \|\| NR==1 {printf "%02s %-20s %-20s\n",NR, $4,$5}' n.txt
awk '$3==0 && $6=="LISTEN" || NR==1 ' netstat.txt # 这个相当于过滤一条条记录
```

- -F 指定分割符，默认是空格，还可以指明多个比如 -F '[;:]''
- print 也可以改成完全C风格的printf
- 其中的“==”为比较运算符。其他比较运算符：!=, >, <, >=, <=

## 复杂的

awk ' BEGIN {...} {...}; END{...} '

```bash
awk -F ':' 'BEGIN {count=0;} {name[count] = $1;count++;}; END{for (i = 0; i < NR; i++) print i, name[i]}' /etc/passwd
awk  'BEGIN{FS=":"} {print $1,$3,$6}' /etc/passwd
```
```bash
#!/bin/awk -f
#运行前
BEGIN {
    math = 0
    english = 0
    computer = 0
 
    printf "NAME    NO.   MATH  ENGLISH  COMPUTER   TOTAL\n"
    printf "---------------------------------------------\n"
}
#运行中
{
    math+=$3
    english+=$4
    computer+=$5
    printf "%-6s %-6s %4d %8d %8d %8d\n", $1, $2, $3,$4,$5, $3+$4+$5
}
#运行后
END {
    printf "---------------------------------------------\n"
    printf "  TOTAL:%10d %8d %8d \n", math, english, computer
    printf "AVERAGE:%10.2f %8.2f %8.2f\n", math/NR, english/NR, computer/NR
}
```

- 可以将awk写成一个文件执行，调用时使用-f来指定：awk -f cal.awk score.txt

## 其他

还有条件控制等，实际上这几乎是一门编程语言。这里主要关注简单一些的状况


## 内建变量

$0      |   当前记录（这个变量中存放着整个行的内容）
$1~$n   |   当前记录的第n个字段，字段间由FS分隔
FS      |   输入字段分隔符 默认是空格或Tab
NF      |   当前记录中的字段个数，就是有多少列
NR      |   已经读出的记录数，就是行号，从1开始，如果有多个文件话，这个值也是不断累加中。
FNR     |   当前记录数，与NR不同的是，这个值会是各个文件自己的行号
RS      |   输入的记录分隔符， 默认为换行符
OFS     |   输出字段分隔符， 默认也是空格
ORS     |   输出的记录分隔符，默认为换行符
FILENAME|   当前输入文件的名字

## 匹配

可以在匹配部分使用grep类似的语法。模式以~开头，写在两个斜杠中间

```bash
awk '$6 ~ /FIN|TIME/ {print NR,$4,$5,$6}' 
```

表示第六个分量，如果是FIN或TIME就算做匹配成功

## 举例

主要来自leetcode

## 输出文件第十行

```bash
gawk 'NR==10 {print $0}' file.txt
gawk 'NR==10' file.txt
```

## [文件转置](https://leetcode.com/problems/transpose-file/)

```bash
awk ' { 
    for (i = 1; i <= NF; i++)  {
        a[NR, i] = $i
    }
}
NF > p { p = NF }
END {    
    for (j = 1; j <= p; j++) {
        str = a[1, j]
        for (i = 2; i <= NR; i++){
            str = str " " a[i, j]
        }
        print str
    }
}' file.txt
```

## [有效电话号码](https://leetcode.com/problems/valid-phone-numbers/)

```bash
awk  '$0 ~ /^\([0-9]{3}\) [0-9]{3}-[0-9]{4}$/ || /^[0-9]{3}-[0-9]{3}-[0-9]{4}$/ {print  $0}' file.txt
```

## [单词频率统计](https://leetcode.com/problems/word-frequency/)

```bash
awk '
BEGIN{
    while(getline < "words.txt") {
        for(i = 1; i <= NF; i += 1)  map_wf[$i]++; 
    }
    n = asort(map_wf, arr_f); 
    for(word in map_wf) {
        map_fw[map_wf[word]] = word; 
    }
    for(j = n; j >= 1; j -= 1) {
        f = arr_f[j];
        printf("%s %d\n", map_fw[f], f);
    }
}'
```

# sed 

sed是一个基于文本行的，“流”处理工具

1. 读取一行到 pattern space
2. 将sed script中的command到pattern space（sed 大概有25种command）
3. 每处理完一行，通常pattern space输出。
4. 接着处理一些end型command 比如d、q、N
5. 重复1

- 其中的sed script可以来自command line 也可以是 -f选项来自sed文件
- 一个command 可以接受行号或reg作为address，也就是command执行的条件
- hold space是另一个缓存空间，sed中只含以上两个空间

每一个sed指令，都可以看做 pattern-action对，满足条件/pattern后，再action

在sed script文件中首行：#!/bin/sed -f 可以直接执行sed

## Sed Commands

- ```a text```, Append text after a line
- ```c text```, replace lines with text 
- ```d```, delete PS
- ```D```, if PS contains \n, delete PS to 1st \n,restart cycle without < newline
- ```e cmd```, PS <= (exceute cmd-output)
- ```F```, print input file name
- ```g```, PS <= HS
- ```G```, PS += \n + HS
- ```h```, HS <= PS
- ```H```, HS += \n + PS
- ```i text```, insert text before a line
- ```n```, if auto-print: print PS,replace PS with next line of input
- ```N```, PS += \n + nextline 
- ```P```, print PS
- ```p```, Print the PS, up to the 1st \n
- ```q ecode```, exit
- ```Q ecode```, exit without print PS
- ```s/regexp/replacement/[flags]```, replacement
- ```w filename```, write PS to filename
- ```x```, exchange PS and HS
- ```y/src/dst/```, translate any c in src to coresponding char in dst
- ```z```, empty PS
- ```=```, print input line number


## Sed Pattern Flags

- ```/g - Global```
- ```/I - Ignore Case```
- ```/p - Print```
- ```/w - filename - Write Filename```

## sed reg

```^  ```| caret表示一行的开头。如：/^#/ 以#开头的匹配。
```$  ```| dollarsign表示一行的结尾。如：/}$/ 以}结尾的匹配。
```\< ```| 表示词首。 如 \<abc 表示以 abc 为首的詞。
```\> ```| 表示词尾。 如 abc\> 表示以 abc 结尾的詞。
```.  ```| 表示任何单个字符。
``` * ```| asterisk表示重复0次或多次。
```[ ]```| 字符集合。如：[abc]表示匹配a或b或c, [^a]表示非a的字符

## 举例

### 1

```zsh
$ sed 's/<.*>//g' html.txt                       # 错误
$ sed 's/<[^>]*>//g' html.txt                    # 正确
$ sed "3,6s/my/your/g" pets.txt                  # 只替换第3到第6行的文本。
$ sed 's/s/S/2' my.txt                           # 只替换每一行的第二个s 
$ sed 's/s/S/3g' my.txt                          # 只替换第一行的第3个以后的s
$ sed '1,3s/my/your/g; 3,$s/This/That/g' my.txt  # 多个模式匹配
$ sed -e '1,3s/my/your/g' -e '3,$s/This/That/g' my.txt
```

### 2

```$ sed '1!G;h;$!d' t.txt```

- 1!G 只有第一行不执行G命令，将换行符和hold space追加到pattern space
- h   （每一行都）执行h命令，将pattern space中的内容拷贝到hold space中
- $!d 除了最后一行不执行d命令，其它行都执行d命令，删除当前行

### 3
```zsh
N        # add the next line to the pattern space; 
s/\n / / # find a new line followed by a space, replace with one space;
P        # print the top line of the pattern space;
D        # delete the top line from the pattern space and run the script again.
```

### 4

[这里](http://sed.sourceforge.net/grabbag/scripts/turing.sed)是一个sed script

[这里](http://www.techsakh.com/2016/05/12/20160512use-sed-command-linux-unix/#How to run multiple sed commands)是大量的sed举例

### 5

```bash
cat ~/passwd | sed -n '/nobody/p'
```

# grep

## 零宽断言

先行断言，表示匹配表达式前面的位置 (?=exp)

后发断言，表示匹配表达式后面的位置 (?<=exp) 
 

## 参考

- [Introduction and Tutorial](http://www.grymoire.com/Unix/Sed.html)
- [sed @ wiki](https://en.wikipedia.org/wiki/Sed)
- [sed, a stream editor](https://www.gnu.org/software/sed/manual/sed.html#sed-commands-list)
