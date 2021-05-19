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

out3 = s.get('https://api.nextdns.io/accounts/@me?withConfigurations=true')
dd=json.loads(out3.text)
print(json.dumps(dd, indent=3))


