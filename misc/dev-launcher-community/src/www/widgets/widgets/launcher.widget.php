<!-- Navigation buttons -->
<!-- the syntax below is obvious, but ideally, this plugin needs:
- a model to define structure of launching data in conf/config.xml (name, full URL, perhaps a link to an icon?)
- a view to a form where user can add/remove new launching items and store the structure in conf.xml
- the code below needs to be refactored to:
  - use php to read all launching items from config.xml
  - use an empty <div> statement as a default
  - loop through all items captured from config.xml
  - use jquery .append to add the line to the <div>
-->
<input class="btn btn-default" type="button" value="Unifi" onclick="window.open('https\:\/\/192.168.1.1:8443')"/>
<input class="btn btn-default" type="button" value="ntopng" onclick="window.open('https\:\/\/192.168.1.1:3443')"/>
<input class="btn btn-default" type="button" value="Nextdns" onclick="window.open('https\:\/\/my.nextdns.com')"/>
<input class="btn btn-default" type="button" value="Dev OPNsense" onclick="window.open('https\:\/\/10.0.0.1')"/>
