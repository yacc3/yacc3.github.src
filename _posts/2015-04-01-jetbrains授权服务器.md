---
layout    : post
title     : jetbrains授权服务器
date      : 2015-04-01
category  : [使用配置]
tags      : [jetbrains]
---

安装jetbrains授权服务器，参考[这里](http://blog.lanyus.com/archives/174.html)


<!-- more -->

- server文件，在[这里](http://blog.lanyus.com/archives/174.html)有下载链接
- 低版本需要upx去壳
    - ```brew install upx; upx -d IntelliJIDEALicenseServer_darwin_amd64```
- 参数设置
    - l 指定绑定监听IP
    - u 用户名参数
    - p 监听的端口
    - prolongationPeriod 过期时间参数

可以直接裸参数运行，通常可以借助supervisor做成demon

```sh
[program:jetbrain-server]
command = /Users/C/iconfig/jetbrains/IntelliJIDEALicenseServer_darwin_amd64 -p 8282 -u yaccai -prolongationPeriod 999999999 -l 127.0.0.1
autostart=true
autorestart=true
startsecs=3
```

以后在License Activation  License server 中填http://127.0.0.1:8282即可 

也可以进一步设置nginx

```sh
server
{
    listen 80;
    server_name idea.imsxm.com;
    root /home/wwwroot/;
     
    location / {
        proxy_pass http://127.0.0.1:1017;
        proxy_redirect off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    access_log off; #access_log end
    error_log /dev/null; #error_log end
}
```
