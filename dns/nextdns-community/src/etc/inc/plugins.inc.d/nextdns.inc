<?php

function nextdns_services()
{
    global $config;
    $services = array();

    if (isset($config['OPNsense']['nextdns']['general']['enabled']) && $config['OPNsense']['nextdns']['general']['enabled'] == 1) {
        $services[] = array(
            'description' => gettext('nextdns'),
            'configd' => array(
                'restart' => array('nextdns restart'),
                'start' => array('nextdns start'),
                'stop' => array('nextdns stop'),
            ),
            'name' => 'nextdns',
            'pidfile' => '/var/run/nextdns.pid',
        );
    }

    return $services;
}