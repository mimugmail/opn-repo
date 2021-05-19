#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

import json, requests, time
import xml.dom.minidom
from getpass import getpass

def getconfigelement(path):
    try:
        tree = config
        for node in path.split('/'):
            tree = tree.getElementsByTagName(node)
            if len(tree) == 0: return False
            tree = tree[0]
        return tree.firstChild.nodeValue
    except: return False

config = xml.dom.minidom.parse('/conf/config.xml')
email = getconfigelement('OPNsense/nextdns/general/email')
password = getconfigelement('OPNsense/nextdns/general/password')
id = getconfigelement('OPNsense/nextdns/general/config')

payload = {"email":email,"password":password}

header = {
  'accept': 'application/json, text/plain, */*',
  'user-agent': 'Curl',
  'content-type': 'application/json;charset=UTF-8',
  'origin': 'https://my.nextdns.io',
  }

s=requests.Session()
s.headers.update(header)
out2 = s.post('https://api.nextdns.io/accounts/@login', json=payload)

while 1:
    t = int(time.time())-1
    out3 = s.get('https://api.nextdns.io/configurations/'+id+'/logs?after='+str(t)+'000')
    dd=json.loads(out3.text)['logs']
    for i in dd:
        print(i['status'], i['name'], i['clientIp'])


