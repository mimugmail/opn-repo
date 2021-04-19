#!/usr/local/bin/python3
# -*- coding: utf-8 -*-
"""
 * Copyright (C) 2021 M. Kralj
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
"""

import requests, json, sys
import xml.dom.minidom
import datetime
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


def getconfigelement(path):
    try:
        tree = config
        for node in path.split('/'):
            tree = tree.getElementsByTagName(node)
            if len(tree) == 0: return False
            tree = tree[0]
        return tree.firstChild.nodeValue
    except: return False

def vpnapi():
    key = getconfigelement('OPNsense/ipcheck/vpnapikey')
    apikey= "?key="+key if key else ""
    if ipv4:
        try:
            url = Request("https://vpnapi.io/api/"+ipv4+apikey)
            url.add_header('User-Agent', 'Mozilla/5.0')
            out['ipv4']['vpnapi'] = json.load(urlopen(url, timeout=4))
            if debug:
                out['ipv4']['vpnapi']['apikey'] = key
                m = out['ipv4']['vpnapi'].get('message')
                out['ipv4']['vpnapi']['status'] = m if m else "ok"
        except:
            pass
    if ipv6:
        try:
            url = Request("https://vpnapi.io/api/"+ipv6+apikey)
            url.add_header('User-Agent', 'Mozilla/5.0')

            out['ipv6']['vpnapi'] = json.load(urlopen(url, timeout=4))
            if debug:
                out['ipv6']['vpnapi']['apikey'] = key
                m = out['ipv6']['vpnapi'].get('message')
                out['ipv6']['vpnapi']['status'] = m if m else "ok"
        except:
            pass
    return

def proxycheck():
    key = getconfigelement('OPNsense/ipcheck/proxycheckkey')
    apikey= 'key='+key+'&' if key else ""
    if ipv4:
        try:
            url = Request("http://proxycheck.io/v2/"+ipv4+"?"+apikey+"vpn=1&asn=1&risk=1&port=1&seen=1")
            url.add_header('User-Agent', 'Mozilla/5.0')
            ret = json.load(urlopen(url, timeout=4))
            out['ipv4']['proxycheck']={}
            out['ipv4']['proxycheck']['status'] = ret['status']
            out['ipv4']['proxycheck'] = ret[ipv4]
            if debug: out['ipv4']['proxycheck']['apikey'] = key
        except:
            pass
    if ipv6:
        try:
            url = Request("http://proxycheck.io/v2/"+ipv6+"?"+apikey+"vpn=1&asn=1&risk=1&port=1&seen=1")
            url.add_header('User-Agent', 'Mozilla/5.0')
            ret = json.load(urlopen(url, timeout=4))
            out['ipv6']['proxycheck']={}            
            out['ipv6']['proxycheck']['status'] = ret['status']
            out['ipv6']['proxycheck'] = ret[ipv6]
            if debug: out['ipv6']['proxycheck']['apikey'] = key            
        except:
            pass
    return    

def ip2loc():
    key = getconfigelement('OPNsense/ipcheck/ip2lockey')
    apikey= key if key else "demo"
    if ipv4:
        try:
            url = Request("https://api.ip2location.com/v2/?ip="+ipv4+"&key="+apikey+"&format=json&package=WS8")

            out['ipv4']['ip2location'] = json.load(urlopen(url, timeout=4))
            out['ipv4']['ip2location']['apikey'] = key
        except:
            pass
    if ipv6:
        try:
            pass
            url = Request("https://api.ip2location.com/v2/?ip="+ipv6+"&key="+apikey+"&format=json&package=WS8")

            out['ipv6']['ip2location'] = json.load(urlopen(url, timeout=4))
            out['ipv6']['ip2location']['apikey'] = key
        except:
            pass
    return    

def ip2proxy():
    key = getconfigelement('OPNsense/ipcheck/ip2proxykey')
    apikey= key if key else "demo"
    if ipv4:
        try:
            url = Request("https://api.ip2proxy.com/?ip="+ipv4+"&key="+apikey+"&package=PX10")

            out['ipv4']['ip2proxy'] = json.load(urlopen(url, timeout=4))
            out['ipv4']['ip2proxy']['apikey'] = key            
        except:
            pass
    if ipv6:
        try:
            url = Request("https://api.ip2proxy.com/?ip="+ipv6+"&key="+apikey+"&package=PX10")

            out['ipv6']['ip2proxy']  = json.load(urlopen(url, timeout=4))
            out['ipv6']['ip2proxy']['apikey'] = key
        except:
            pass
    return  

def onionoo():
    if ipv4:
        try:
            out['ipv4']['onionoo']={}
            url = Request("https://onionoo.torproject.org/details?limit=4&search="+ipv4)
            ret = json.load(urlopen(url, timeout=4))
            if len(ret['relays']): out['ipv4']['onionoo']['relay'] = (ret['relays'][0])
            if len(ret['bridges']): out['ipv4']['onionoo']['bridge'] = (ret['relays'][0])
        except:
            pass
    if ipv6:
        try:
            out['ipv6']['onionoo']={}
            url = Request("https://onionoo.torproject.org/details?limit=4&search="+ipv6)
            ret = json.load(urlopen(url, timeout=4))
            if len(ret['relays']): out['ipv6']['onionoo']['relay'] = (ret['relays'][0])
            if len(ret['bridges']): out['ipv6']['onionoo']['bridge'] = (ret['relays'][0])
        except:
            pass
    return

def ipqs():
    key = getconfigelement('OPNsense/ipcheck/ipqskey')
    apikey= key if key else "false"
    if ipv4:
        try:
            url = Request("https://ipqualityscore.com/api/json/ip/"+apikey+"/"+ipv4+"?strictness=0")
            url.add_header('User-Agent', 'Mozilla/5.0')
            out['ipv4']['ipqs'] = json.load(urlopen(url, timeout=4))
            if debug: out['ipv4']['ipqs']['apikey'] = key
        except:
            pass
    if ipv6:
        try:
            url = Request("https://ipqualityscore.com/api/json/ip/"+apikey+"/"+ipv6+"?strictness=0")
            url.add_header('User-Agent', 'Mozilla/5.0')
            out['ipv6']['ipqs'] = json.load(urlopen(url, timeout=4))
            if debug: out['ipv6']['ipqs']['apikey'] = key
        except:
            pass
    return

def transform(out):
    o={}
    
    if ipv4: 
        o['ipv4']={}
        o['ipv4']['ip'] = ipv4
        net = out['ipv4'].get('vpnapi', {}).get('network', {}).get('network')
        o['ipv4']['network'] = net if net else False

        ntype =[out['ipv4'].get('proxycheck', {}).get('type'),
            out['ipv4'].get('ip2proxy', {}).get('usageType'),
        False]
        if debug: o['ipv4']['network_type_list']=ntype
        o['ipv4']['network_type']=next(i for i in ntype if i not in [None, ""])

        isp=[out['ipv4'].get('ip2location', {}).get('isp'),
            out['ipv4'].get('ip2proxy', {}).get('isp'),
            out['ipv4'].get('ipqs', {}).get('ISP'),
            out['ipv4'].get('proxycheck', {}).get('provider'),
            out['ipv4'].get('vpnapi', {}).get('network', {}).get('autonomous_system_organization'),
        False]
        if debug: o['ipv4']['isp_list']=isp
        o['ipv4']['isp']=next(i for i in isp if i not in [None, ""])

        asn=[out['ipv4'].get('vpnapi', {}).get('network', {}).get('autonomous_system_number'),
            out['ipv4'].get('proxycheck', {}).get('asn'),
            out['ipv4'].get('ipqs', {}).get('ASN'),
            out['ipv4'].get('ip2proxy', {}).get('asn'),
        False]
        if debug: o['ipv4']['asn_list']=asn
        o['ipv4']['asn']=str(next(i for i in asn if i not in [None, "","0"]))

        city=[out['ipv4'].get('ipqs', {}).get('city'),
            out['ipv4'].get('proxycheck', {}).get('city'),
            out['ipv4'].get('vpnapi', {}).get('location', {}).get('city'),
            out['ipv4'].get('ip2location', {}).get('city_name'),
            out['ipv4'].get('ip2proxy', {}).get('cityName'),
        False]
        if debug: o['ipv4']['city_list']=city
        o['ipv4']['city']=next(i for i in city if i not in [None, ""])

        region=[out['ipv4'].get('ipqs', {}).get('region'),
            out['ipv4'].get('proxycheck', {}).get('region'),
            out['ipv4'].get('ip2proxy', {}).get('regionName'),
            out['ipv4'].get('ip2proxy', {}).get('regionName'),
            out['ipv4'].get('vpnapi', {}).get('location', {}).get('region_code'),
        False]
        if debug: o['ipv4']['region_list']=region
        o['ipv4']['region']=next(i for i in region if i not in [None, ""])

        country=[out['ipv4'].get('ip2location', {}).get('country_name'),
            out['ipv4'].get('ip2proxy', {}).get('countryName'),
            out['ipv4'].get('vpnapi', {}).get('country'),
            out['ipv4'].get('proxycheck', {}).get('country'),
            out['ipv4'].get('vpnapi', {}).get('location', {}).get('country_code'),
            out['ipv4'].get('ipqs', {}).get('country_code'),
        False]
        if debug: o['ipv4']['country_list']=country
        o['ipv4']['country']=next(i for i in country if i not in [None, ""])

        tor=['vpnapi' if out['ipv4'].get('vpnapi', {}).get('security', {}).get('tor') else False,
            'ipqualityscore' if out['ipv4'].get('ipqs', {}).get('tor') else False,
            'ip2proxy' if out['ipv4'].get('ip2proxy', {}).get('proxyType')=="TOR" else False,
            'proxycheck' if out['ipv4'].get('proxycheck', {}).get('type')=="TOR" else False,
            'onionoo' if not len(out['ipv4'].get('onionoo', {}))==0 else False,
            False]
        if debug: o['ipv4']['tor_list']=tor
        o['ipv4']['tor']=any(tor)
        tor = [i for i in tor if i != False]
        o['ipv4']['tor_detected_by']=tor

        vpn=['vpnapi' if out['ipv4'].get('vpnapi', {}).get('security', {}).get('vpn') else False,
            'ipqs' if out['ipv4'].get('ipqs', {}).get('vpn') else False,
            'ip2proxy' if out['ipv4'].get('ip2proxy', {}).get('proxyType')=="VPN" else False,
            'proxycheck' if out['ipv4'].get('proxycheck', {}).get('type')=="VPN" else False,
            'proxycheck' if out['ipv4'].get('proxycheck', {}).get('type')=="OPENVPN" else False,
            'proxycheck' if out['ipv4'].get('proxycheck', {}).get('type')=="SOCKS" else False,
            False]
        if debug: o['ipv4']['vpn_list']=vpn
        o['ipv4']['vpn']=any(vpn)
        vpn = [i for i in vpn if i != False]
        o['ipv4']['vpn_detected_by']=vpn

        proxy=['vpnapi' if out['ipv4'].get('vpnapi', {}).get('security', {}).get('proxy') else False,
            'ipqualityscore' if out['ipv4'].get('ipqs', {}).get('proxy') else False,
            'ip2proxy' if out['ipv4'].get('ip2proxy', {}).get('proxyType')=="PUB" else False,
            'ip2proxy' if out['ipv4'].get('ip2proxy', {}).get('proxyType')=="WEB" else False,
            'ip2proxy' if out['ipv4'].get('ip2proxy', {}).get('proxyType')=="RES" else False,
            False]
        if debug: o['ipv4']['proxy_list']=proxy
        o['ipv4']['proxy']=any(proxy)
        proxy = [i for i in proxy if i != False]
        o['ipv4']['proxy_detected_by']=proxy

        o['ipv4']['ipqs_fraud_score'] = out['ipv4'].get('ipqs', {}).get('fraud_score')
        o['ipv4']['proxycheck_risk'] = out['ipv4'].get('proxycheck', {}).get('risk')

    # IPv6 section
    if ipv6: 
        o['ipv6']={}
        o['ipv6']['ip'] = ipv6
        net = out['ipv6'].get('vpnapi', {}).get('network', {}).get('network')
        o['ipv6']['network'] = net if net else False

        ntype =[out['ipv6'].get('proxycheck', {}).get('type'),
            out['ipv6'].get('ip2proxy', {}).get('usageType'),
        False]
        if debug: o['ipv6']['network_type_list']=ntype
        o['ipv6']['network_type']=next(i for i in ntype if i not in [None, ""])

        isp=[out['ipv6'].get('ip2location', {}).get('isp'),
            out['ipv6'].get('ip2proxy', {}).get('isp'),
            out['ipv6'].get('ipqs', {}).get('ISP'),
            out['ipv6'].get('proxycheck', {}).get('provider'),
            out['ipv6'].get('vpnapi', {}).get('network', {}).get('autonomous_system_organization'),
        False]
        if debug: o['ipv6']['isp_list']=isp
        o['ipv6']['isp']=next(i for i in isp if i not in [None, ""])

        asn=[out['ipv6'].get('vpnapi', {}).get('network', {}).get('autonomous_system_number'),
            out['ipv6'].get('ip2proxy', {}).get('asn'),
            out['ipv6'].get('ipqs', {}).get('ASN'),
            out['ipv6'].get('proxycheck', {}).get('asn'),
        False]
        if debug: o['ipv6']['asn_list']=asn
        o['ipv6']['asn']= str(next(i for i in asn if i not in [None, ""]))
        

        city=[out['ipv6'].get('ipqs', {}).get('city'),
            out['ipv6'].get('proxycheck', {}).get('city'),
            out['ipv6'].get('vpnapi', {}).get('location', {}).get('city'),
            out['ipv6'].get('ip2location', {}).get('city_name'),
            out['ipv6'].get('ip2proxy', {}).get('cityName'),
        False]
        if debug: o['ipv6']['city_list']=city
        o['ipv6']['city']=next(i for i in city if i not in [None, ""])

        region=[out['ipv6'].get('ipqs', {}).get('region'),
            out['ipv6'].get('proxycheck', {}).get('region'),
            out['ipv6'].get('ip2proxy', {}).get('regionName'),
            out['ipv6'].get('ip2location', {}).get('region_name'),
            out['ipv6'].get('vpnapi', {}).get('location', {}).get('region_code'),
        False]
        if debug: o['ipv6']['region_list']=region
        o['ipv6']['region']=next(i for i in region if i not in [None, ""])

        country=[out['ipv6'].get('ip2location', {}).get('country_name'),
            out['ipv6'].get('ip2proxy', {}).get('countryName'),
            out['ipv6'].get('vpnapi', {}).get('location', {}).get('country'),
            out['ipv6'].get('proxycheck', {}).get('country'),
            out['ipv6'].get('vpnapi', {}).get('location', {}).get('country_code'),
            out['ipv6'].get('ipqs', {}).get('country_code'),
        False]
        if debug: o['ipv6']['country_list']=country
        o['ipv6']['country']=next(i for i in country if i not in [None, ""])

        tor=['vpnapi' if out['ipv6'].get('vpnapi', {}).get('security', {}).get('tor') else False,
            'ipqualityscore' if out['ipv6'].get('ipqs', {}).get('tor') else False,
            'ip2proxy' if out['ipv6'].get('ip2proxy', {}).get('proxyType')=="TOR" else False,
            'proxycheck' if out['ipv6'].get('proxycheck', {}).get('type')=="TOR" else False,
            'onionoo' if not len(out['ipv6'].get('onionoo', {}))==0 else False,
            False]
        if debug: o['ipv6']['tor_list']=tor
        o['ipv6']['tor']=next(i for i in tor if i not in [None, ""])
        tor = [i for i in tor if i != False]
        o['ipv6']['tor_detected_by']=tor

        vpn=['vpnapi' if out['ipv6'].get('vpnapi', {}).get('security', {}).get('vpn') else False,
            'ipqualityscore' if out['ipv6'].get('ipqs', {}).get('vpn') else False,
            'ip2proxy' if out['ipv6'].get('ip2proxy', {}).get('proxyType')=="VPN" else False,
            'proxycheck' if out['ipv6'].get('proxycheck', {}).get('type')=="VPN" else False,
            'proxycheck' if out['ipv6'].get('proxycheck', {}).get('type')=="OPENVPN" else False,
            False]
        if debug: o['ipv6']['vpn_list']=vpn
        o['ipv6']['vpn']=any(vpn)
        vpn = [i for i in vpn if i != False]
        o['ipv6']['vpn_detected_by']=vpn

        proxy=['vpnapi' if out['ipv6'].get('vpnapi', {}).get('security', {}).get('proxy') else False,
            'ipqualityscore' if out['ipv6'].get('ipqs', {}).get('proxy') else False,
            'ip2proxy' if out['ipv6'].get('ip2proxy', {}).get('proxyType')=="PUB" else False,
            'ip2proxy' if out['ipv6'].get('ip2proxy', {}).get('proxyType')=="WEB" else False,
            'ip2proxy' if out['ipv6'].get('ip2proxy', {}).get('proxyType')=="RES" else False,
            'proxycheck' if out['ipv6'].get('proxycheck', {}).get('type')=="SOCKS" else False,
            False]
        if debug: o['ipv6']['proxy_list']=proxy
        o['ipv6']['proxy']=any(proxy)
        proxy = [i for i in proxy if i != False]
        o['ipv6']['proxy_detected_by']=proxy

        o['ipv6']['ipqs_fraud_score'] = out['ipv6'].get('ipqs', {}).get('fraud_score')
        o['ipv6']['proxycheck_risk'] = out['ipv6'].get('proxycheck', {}).get('risk')
    return o

#############
# Main loop #
#############

debug = False
config = xml.dom.minidom.parse('/conf/config.xml')
savestate = "/usr/local/opnsense/scripts/OPNsense/ipcheck/savestate.json"
out={}
arg=''
if len(sys.argv)>1:
    arg=str(sys.argv[1])
if arg == '':
    try:
        with open(savestate, "r") as f: out = json.loads(f.read())
        out['source']='Cached record'
        print(json.dumps(out, indent=3))
    except:
        arg = 'all'
    if arg == '': sys.exit()

ivpnapi = getconfigelement('OPNsense/ipcheck/vpnapi')
iproxycheck = getconfigelement('OPNsense/ipcheck/proxycheck')
iip2proxy = getconfigelement('OPNsense/ipcheck/ip2proxy')
iip2loc = getconfigelement('OPNsense/ipcheck/ip2loc')
iipqs = getconfigelement('OPNsense/ipcheck/ipqs')
ionionoo = getconfigelement('OPNsense/ipcheck/onionoo')

if arg == 'list':
    out['vpnapi'] = ivpnapi
    out['proxycheck'] = iproxycheck
    out['ip2proxy'] = iip2proxy
    out['ip2loc'] = iip2loc
    out['ipqs'] = iipqs
    out['onionoo'] = ionionoo
    print(json.dumps(out, indent=3))
    sys.exit()

try:
    out['ipv4'] = {}
    ipv4 = json.load(urlopen("https://ip4.seeip.org/json", timeout=2))['ip']
except URLError as error:
    ipv4 = False
out['ipv4']['ip'] = ipv4

try:
    out['ipv6'] = {}
    ipv6 = json.load(urlopen("https://ip6.seeip.org/json", timeout=2))['ip']
    out['ipv6']['ip'] = ipv6
except URLError as error:
    ipv6 = False

if   arg == 'vpnapi': vpnapi()
elif arg == 'proxycheck': proxycheck()
elif arg == 'ip2proxy': ip2proxy()
elif arg == 'ip2loc': ip2loc()
elif arg == 'onionoo': onionoo()
elif arg == 'ipqs': ipqs()
elif arg == 'all':
    if ivpnapi =='1': vpnapi()
    if iproxycheck =='1': proxycheck()
    if iip2proxy =='1': ip2proxy()
    if iip2loc =='1': ip2loc()
    if ionionoo == '1': onionoo()
    if iipqs == '1': ipqs()
    out = transform(out)
    out['timestamp'] = datetime.datetime.now().replace(microsecond=0).isoformat()
    try:
        f = open(savestate, 'w')
        f.write(json.dumps(out, indent=3))
        f.close
    except:
        pass
    out['source']='Direct API call'

print(json.dumps(out, indent=3))