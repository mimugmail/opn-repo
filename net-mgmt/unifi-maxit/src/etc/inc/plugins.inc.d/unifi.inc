<?php

/*
 * Copyright (C) 2021 Michael Muenz <michael.muenz@max-it.de>
 * All rights reserved.
 *
 */

function unifi_services()
{
    global $config;

    $services = array();

    if (isset($config['OPNsense']['unifi']['general']['enabled']) && $config['OPNsense']['unifi']['general']['enabled'] == 1) {
        $services[] = array(
            'description' => gettext('Unifi Controller'),
            'configd' => array(
                'restart' => array('unifi restart'),
                'start' => array('unifi start'),
                'stop' => array('unifi stop'),
            ),
            'name' => 'unifi',
            'pidfile' => '/var/run/unifi/unifi.pid',
        );
    }

    return $services;
}
