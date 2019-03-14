---
layout    : post  
title     : 使用googleDrive备份配置  
date      : 2016-05-09  
category  : 使用配置  
tags      : [备份]  
published : true  
---


使用谷歌硬盘备份某些文件  
首先要按照[这里](https://developers.google.com/api-client-library/python/samples/samples#running-samples) 创建应用访问的权限和token  
附属文件还有一个json

<!-- more -->

pip3 install --upgrade google-api-python-client

被墙 还是使用github吧

```python
# coding:utf-8

from __future__ import print_function
import os
import json

from apiclient.discovery import build
from httplib2 import Http
from oauth2client import file, client, tools
import datetime

try:
    import argparse
    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None

os.chdir(os.path.join(os.environ['HOME'], '.shell/bak'))

os.system("echo '-----------------------' >> up.log")
os.system("date >> up.log")
week = dict()
weekjsonfile = 'week.json'
bakpath = '/tmp/for_gd'
stp = '~/Library/Application\ Support/Sublime\ Text\ 2/Packages'

SCOPES = 'https://www.googleapis.com/auth/drive.file'
store = file.Storage('storage.json')
creds = store.get()
if not creds or creds.invalid:
    flow = client.flow_from_clientsecrets('client_secret.json', SCOPES)
    creds = tools.run_flow(flow, store, flags) \
        if flags else tools.run(flow, store)
DRIVE = build('drive', 'v3', http=creds.authorize(Http()))


def zipfiles():  # get files to /tmp/for_gd/
    os.system('rm -rf /tmp/for_gd')
    os.system('mkdir /tmp/for_gd')
    print('clear for_gd')

    # ~/.*rc
    os.system('zip -qr /tmp/for_gd/rc.zip  ~/.*rc*')
    print('zip *rc*')

    # ~/.gitconfig
    os.system('zip -qr /tmp/for_gd/gitconfig.zip ~/.gitconfig')
    print('zip gitconfig')

    # ~/.shell
    os.system('zip -qr /tmp/for_gd/shell.zip ~/.shell')
    print('zip ~/.shell')

    # bittorent
    os.system('mkdir /tmp/for_gd/utorrent')
    os.system('cp ~/Library/Application\ Support/uTorrent/*.torrent /tmp/for_gd/utorrent')
    os.system('zip -qr /tmp/for_gd/torrent.zip  /tmp/for_gd/utorrent')
    os.system('rm  -rf /tmp/for_gd/utorrent')
    print('zip utorrent')

    # st
    os.system('cp %s/Color\ Scheme\ -\ Default/st.tmTheme /tmp/for_gd/st.tmTheme.txt' % stp)
    os.system('cp %s/C++/C++.sublime-build /tmp/for_gd/C++.sublime-build.txt' % stp)
    os.system('cp %s/Python/Python.sublime-build /tmp/for_gd/Python.sublime-build.txt' % stp)
    print('zip st files')


    # restore
    os.system('cp ~/.shell/restore.sh /tmp/for_gd/restore.sh')
    print('zip restore')

def truncate(sn):
    folderID = week.get(sn, None)
    if folderID:
        DRIVE.files().delete(fileId=folderID).execute()
    metadata = {'name': sn,
                'mimeType': "application/vnd.google-apps.folder",
                'parents': ['0Bynd6vfYn_1DS3VYbEdyb1JrTHM']  # maintain_ID
                }
    res = DRIVE.files().create(body=metadata).execute()
    week[sn] = res['id']

    jsonfile = open(weekjsonfile, 'w')
    jsonfile.write(json.dumps(week))
    jsonfile.close()
    print('done trucate cloud folder')


def upload(sn):
    filelist = []
    for file in os.listdir(bakpath):
        if os.path.isfile(os.path.join(bakpath, file)):
            filelist.append(file)

    folderID = week[sn]
    for file in filelist:
        print('uploading ', file)
        metadata = {'name': file, 'mimeType': None, 'parents': [folderID]}
        fpath = os.path.join(bakpath, file)
        res = DRIVE.files().create(body=metadata, media_body=fpath).execute()
        if res:
            os.system('echo "    upload %s done " >> up.log' % file)
        else:
            os.system('echo "    upload %s error" >> up.log' % file)

zipfiles()
jsonfile = open(weekjsonfile, 'r')
week = json.loads(jsonfile.read())
sn = datetime.datetime.utcnow().strftime("%w")
truncate(sn)
upload(sn)
os.system('rm -rf /tmp/for_gd')
os.system('echo "All done\n\n" >> up.log')

```
