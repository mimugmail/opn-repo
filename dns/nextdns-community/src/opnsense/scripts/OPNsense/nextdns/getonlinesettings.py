#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

import json, requests, time, sys
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
s.post('https://api.nextdns.io/accounts/@login', json=payload)
conf = json.loads(s.get('https://api.nextdns.io/accounts/@me?withConfigurations=true').text)
out={}
out["email"]=conf["email"]
for i in range(len(conf["configurations"])):
  id=conf["configurations"][i]["id"]
  out[id]={}
  out[id]["name"]=conf["configurations"][i]["name"]
  out[id]["settings"] = json.loads(s.get('https://api.nextdns.io/configurations/'+id+'/settings').text)
  out[id]["security"] = json.loads(s.get('https://api.nextdns.io/configurations/'+id+'/security').text)
  out[id]["privacy"] = json.loads(s.get('https://api.nextdns.io/configurations/'+id+'/privacy').text)
  out[id]["parentalcontrol"] = json.loads(s.get('https://api.nextdns.io/configurations/'+id+'/parentalcontrol').text)
  out[id]["denylist"] = json.loads(s.get('https://api.nextdns.io/configurations/'+id+'/denylist').text)
  out[id]["allowlist"] = json.loads(s.get('https://api.nextdns.io/configurations/'+id+'/allowlist').text)
  
print(json.dumps(out, indent=3))

