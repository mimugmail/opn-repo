## Model
- Includes username, password, sitename, server and port
- Planned menu structure: 
    - Networks (wireless + wired)
    - Devices (APs + switches)
    - Clients (users + guests)
    - Alerts (alerts + insights)
    - Settings (username, password, siteid, site:port)
    
## Controller
- all 5 controllers listed above are created
    - /ui/unifi/networks
    - /ui/unifi/devices
    - /ui/unifi/clients
    - /ui/unifi/alerts
    - /ui/unifi/settings
- form for Settings is functional
- (I think) ControlController doesn't belong here - it is /u/mimugmail's code
**- APIs require work:**
    - ListController - includes the whole Unifi API client class (from line 200+)
    - ListController some APIs are created - all data-gathering, no modifying/changing APIs yet
    - **to-do:** refactor API calls to minimize repeating code (gather params, authenticate, call API)
    - **to-do:** add all relevant APIs from https://github.com/Art-of-WiFi/UniFi-API-client
    - **to-do:** exception handling - currently the code borks if Unifi controller doesn't respond
    
## View
    - devices.volt code is completely unfinished superset of possibilities - includes networks, devices and clients
    - networks.volt generates QR code for each wifi network it gets from APIs
    - qifi code is from https://github.com/jeromeetienne/jquery-qrcode (**needs attribution**)
    