---
layout    : post
title     : supervisor监控
date      : 2014-12-11
category  : [使用配置]
tags      : [Python, supervisor]
---

监控进程自动运行，当进程中断时，自动重新启动

通过pip或brew安装
 
<!-- more -->
 
参考：

- [http://www.cnblogs.com/gsblog/p/3730293.html](http://www.cnblogs.com/gsblog/p/3730293.html)
- [http://python.jobbole.com/86423/](http://python.jobbole.com/86423/)
- [http://supervisord.org/](http://supervisord.org/)

<!-- # XML_RPC接口 -->

# 配置文件

配置文件模板有时候存在，比如supervised.ini, 这是通过homebrew建立的情况。 有时候不存在，则需要创建，使用程序自带的可执行文件 echo_supervisord_conf 可以自动创建配置文件：```./echo_supervisord_conf```


简单使用需要修改的

- [inet_http_server]
- 最后一行的include项目，是分拆包含的 监控实例

## 监控配置

```
[program:blog]
command=/usr/local/bin/jekyll serve --source /Users/C/Code/yaccai.github.io --destination /Users/C/Code/yaccai.github.io/_site  --host 0.0.0.0 --port 4000 --watch &> /Users/C/Code/yaccai.github.io/blog.log &
directory=/Users/C/Code/yaccai.github.io
autostart=true
autorestart=true
stdout_logfile = /Users/C/Code/yaccai.github.io/blog.log

;;;;;;;;;;;;;;;;;;;;;;;;;
;command=celery worker --app=task -l info ; 启动命令
;stdout_logfile=/var/log/supervisor/celeryd_out.log ; stdout 日志输出位置
;stderr_logfile=/var/log/supervisor/celeryd_err.log ; stderr 日志输出位置
;autostart=true ; 在 supervisord 启动的时候自动启动
;autorestart=true ; 程序异常退出后自动重启
;startsecs=10 ; 启动 10 秒后没有异常退出，就当作已经正常启动
```

# supervisord 

# supervisorctl

- supervisord: 初始启动Supervisord，启动、管理配置中设置的进程;
- supervisorctl stop(start, restart) xxx，停止（启动，重启）某一个进程(xxx);
- supervisorctl reread: 只载入最新的配置文件, 并不重启任何进程;
- supervisorctl reload: 载入最新的配置文件，停止原来的所有进程并按新的配置启动管理所有进程;
- supervisorctl update: 根据最新的配置文件，启动新配置或有改动的进程，配置没有改动的进程不会受影响而重启;
