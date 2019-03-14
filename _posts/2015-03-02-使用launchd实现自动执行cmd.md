---
layout    : post
title     : 使用launchd实现自动执行cmd
date      : 2015-03-02
category  : 使用配置
tags      : [Mac, shell]
published : true
---

自动执行的shell script，通常分为开机时启动，和登录时启动。下面主要说明如何通过launchd实现

需要自动被调用的程序，必须包装成agent或daemon，才能提交给os使用。包装需要在一个xml格式的文件中完成，后缀为.plist。一个plist文件对应一个自动调用的程序，并且plist文件必须放在（或ln -sfv）到一些特定的目录中，最后由launchctl负责加载才算完成。

<!-- more -->

详细参考

- 官方文档[这里](https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
- blog[这里](http://www.tanhao.me/talk/1287.html/) 
- [launchcontrol](http://launchd.info/)

# plist

每一个plist文件，都是一个执行项目。类似于：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>             <string>onstartup1</string>
    <key>Disabled</key>          <false/>
    <key>RunAtLoad</key>         <true/>
    <key>KeepAlive</key>         <false/>
    <key>ProgramArguments</key>
        <array>
            <string>/path/to/*sh</string>
        </array>
</dict>
</plist>
```

另外一个，定时执行的例子

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yaccai.mailtweet</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/C/.shell/mailtweet/mymail1.py</string>
    </array>
    <key>StartInterval</key>
    <integer>60</integer>
</dict>
</plist>
```

## 含义

key                     | 含义                      
Lable                   | 相当于一个lauchd钟的ID                              
RunAtLoad               | 是否立即启动可执行文件？默认false 
KeepAlive               | 为ture时: 开启可执行文件，保持在整个系统运行周期内?
Program                 | 可执行文件路径                 
ProgramArguments        | 第一项是路径同上，后面的是参数  
StartInterval           | 每次执行的间隔秒数
StartCalendarInterval   | 这个是更为方便的执行计划
WorkingDirectory        | 设定工作目录
StandardInPath          | 重定向的三个标准IO
StandardOutPath         |
StandardErrorPath       |

### ProgramArguments Program

Program仅仅指定路径，ProgramArguments则可以指定更多的参数等，比如实际要执行一条cmd：
<center>/usr/bin/rsync --archive --compress-level=9 "/Volumes/Macintosh HD" "/Volumes/Backup"</center>

那么应该写成这个样子

```xml
<key>ProgramArguments</key>
<array>
    <string>/usr/bin/rsync</string>
    <string>--archive</string>
    <string>--compress-level=9</string>
    <string>/Volumes/Macintosh HD</string>
    <string>/Volumes/Backup</string>
</array>
```
如果两个key都指明了，那么后者ProgramArguments中的第二个及以后的item就当参数来使用了,第一个item还是要和Program指明的值相同，因为item0会被当做第0个参数使用，这通常应该是程序的名字

### StartCalendarInterval

这个很类似于contab，有五个子key Month, Day, Weekday, Hour, Minute

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>3</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

未指明的时间段都是 *

可以指定多个时间

```xml
<key>StartCalendarInterval</key>
<array>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <dict>
        <key>Minute</key>
        <integer>0</integer>
        <key>Weekday</key>
        <integer>0</integer>
    </dict>
</array>
```

比crontab 差的地方
every five minutes between 20:00 and 23:00

*/5 20-23 * * *

在plist中 必须写成一系列的dict have to list all 36 matching timestamps 

### keepAlive VS RunAtLoad

RunAtLoad 指定为true后，立即执行

KeepAlive 指定为true后，也立即执行，但是等ThrottleInterval之后，还要再执行。。。

周期执行的程序不定义它们即可

### 更多参考

- [launchd.info](http://launchd.info/)
- [wiki](https://en.wikipedia.org/wiki/Launchd)


.plist文件写好之后，可以使用  
<center>plutil -lint *.list</center>
来检测文件是否正确，只是检测xml规范

# 自动执行的目录

## 开机 - onboot

尚未测试

启动条目文件所在目录| meaning
/System/Library/LaunchDaemons/ | System-wide daemons provided by Mac OS X.
/Library/LaunchDaemons/ | System-wide daemons provided by the administrator.

## 登录 - onlogin

三个目录下的plist项目会被自动执行

启动条目文件所在目录| meaning
/System/Library/LaunchAgents    | Per-user agents provided by Mac OS X.
/Library/LaunchAgents           | 管理员设定的*，means：每个用户登录前都要执行
~/Library/LaunchAgents          | 当前用户设定的启动前执行条目


# 使用

创建好plist文件，，并且放置/链接到需要的目录后，就可以加载了

- launchctl load *.plist
- launchctl unload *.plist

不加载是没有效果的

如果中途修改了plis文件，则需要重新unload load，否则是没有效果的

**要注意的是，要保持plist中指定的可执行文件具有x属性** 
**plist中可执行文件的路径，应该是绝对路径，因为~可能并不存在**


# plist举例

```xml
<?xml version="1.0" encoding="UTF-8"?>
http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>label</key>
        <string>com.devdaily.pingwebsites</string> 
        <key>ProgramArguments</key>
            <array>
                    <string>/Users/al/bin/crontab-test.sh</string>
            </array>
        <key>OnDemand</key>          <false/>
        <key>Nice</key>              <integer>1</integer>
        <key>StartInterval</key>     <integer>60</integer>
        <key>StandardErrorPath</key> <string>/tmp/AlTest1.err</string>
        <key>StandardOutPath</key>   <string>/tmp/AlTest1.out</string>
</dict>
</plist>
```

- 运行 /Users/al/bin/crontab-test.sh
- 每60s运行一次
- 重定向了输出和错误输出
