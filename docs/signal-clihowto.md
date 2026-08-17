# OpnArp to watch for new ipv6 and ipv4 joins to network

This document explains how to install opnarp plugin with opnsense firewall. Its kind of nifty because it uses signal to send and receive when a new host joins the network (and works with ipv6!). The docs they make are pretty good, but I found that I wanted to use signal instead of gosend. I like using signal-cli (which is ABSOLUTE HELL to get working on freebsd!) which sends to my single thing instead of yet another thing I have to monitor.

EVIL signal CLI insall instructions for freebsd (I just run a freebsd version that matches my opnsense verison, currently 13 afaik). DO NOT use the ones included with freebsd they seem foobared (**hopefully this will change with time**)

1. follow [these directions](https://github.com/AsamK/signal-cli)

2. the "[native library](https://github.com/AsamK/signal-cli/wiki/Provide-native-lib-for-libsignal)" part is really important. I spent hours because I ignored this part, basically you have to replace a part of one of the jar's with a .so compiled for freebsd.

3. ```bash
   How to use it
   With signal-cli
   The compiled library files (.so / .dylib / .dll) can be incorporated into signal-cli according to the instructions on its wiki. For Linux, this amounts to swapping the .so files inside the .jar archives.
   
   For example, for signal-cli v0.11.6 on ARM64, download signal-cli-0.11.6-Linux.tar.gz from signal-cli's releases and libsignal_jni.so-v0.21.1-aarch64-unknown-linux-gnu.tar.gz from this repo's releases. Unpack downloaded files with tar -xzf ….tar.gz. Then replace the bundled .so object:
   
   zip -uj signal-cli-0.11.6/lib/libsignal-client-0.21.1.jar libsignal_jni.so
   ```

4. You will have to be familiar with compiling java and whatnot for opnsense. Be sure to install openjdk(xx) so you can run java apps.

5. Once you are done with that I recommend installing qrencode (or you can manually type in the secret) to register yourself with signal.

6. I just register my phone #. If you are paranoid, get an extra sim and just use that. Keep in mind that ALL your signal messages will be stored here!

7. So now you have a 'working' signal-cli binary. I like to test with:

8. ```bash
   #!/usr/bin/env bash
   source /root/.profile
   /opt/signal-cli/bin/signal-cli send -m "Hello" +CC<YOURPHONENUMBER>
   ```

9. If that works then you are ready to recieve messages with your signal.

10. Now you are ready to install OPN-Arp. Follow [these directions](https://virtualize.link/opnarp/) . If you just want to use gotify you can ignore the WHOLE previous section, but I live using signal these days.  Be sure to follow them closely, as they are not intuitively obvious as to the proper order. Also BE SURE to enable your tests! I didnt' do that and wondered why it didn't work.

11. Variations you need to change for 'signal'

12. ```bash
    if [[ $MONIT_DESCRIPTION =~ "MAC pair" ]]; then
            ip=$(echo $MONIT_DESCRIPTION | cut -d '(' -f 2  | cut -d ')' -f 1)
            mac=$(echo $MONIT_DESCRIPTION | cut -d '(' -f 2  | cut -d ')' -f 2)
            host=$(host $ip | cut -d ' ' -f 5)
            title="New device spotted"
            msg="IP: $ip - MAC: $mac - Hostname: $host"
    else
            title=$MONIT_SERVICE
            msg=$MONIT_DESCRIPTION
    fi
    
    echo "New Message from OPNSENSE $title $msg" | /opt/signal-cli/bin/signal-cli send --message-from-stdin <YOURPHONE>
    ```

13. The above script is the referenced 'gotify.sh' script in the directions above.

14. For your info, there are TONS of nice utilities [here](https://www.routerperformance.net/opnsense-repo/) . This person really knows their stuff. I have been amazed that EVEN IPV6 stuff is on. I had a "fingbox" which would squak every time there was a new computer on the net, but it WOULDN'T tell me ipv6!

## Some general thoughts on the mistakes I made

1. I didn't follow the directions very well. As a result things didn't work. 
2. the whole setup is explained below for those of you who are curios
3. use the PHYSICAL address NOT the opnsense name. In my config its `igb1` for `lan`

### High Level Explanation of how this works.

The section below explains the specific pieces of the puzzle and how they work together. It also explains how the monitoring works since I didn't understand this and the docs don't really explain how everything fits together.

#### Monit

Monit seems to be an event manager, which can either run script scripts or email alerts. It is used to monitor a file, called `/etc/log/system/latest.log`. Monit is trained to look for the following keywords "MAC Pair" in the tests.  Monit also seems to have 2 areas, Service Tests, which is the thing that does the detecting, and Service Settings, which seems to fire the test when a new file is found in the file /var/log/system/latest.log. Finally, either you create an alert (for emails), or create a a script action.

### Making everything work

Finally, you create a system hook, which enables the service 99-opnarp to be started when a new event is detected. So the service is only fired when there is a detection. The +x 'turns on' the service for a one-shot entry startup in rc.d (syshook) directory.

The delay seems to be about 3-40 seconds but once its up it works fantastically. Many thanks to the author of the program.

