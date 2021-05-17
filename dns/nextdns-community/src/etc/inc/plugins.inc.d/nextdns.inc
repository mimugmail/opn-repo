<?php


function nextdns_enabled()
{
    $model = new \OPNsense\Nextdns\General();
    return (string)$model->enabled == '1';
}

function nextdns_services()
{
    $services = array();

    if (!nextdns_enabled()) {
        return $services;
    }

    $services[] = array(
        'description' => gettext('nextdns'),
        'configd' => array(
            'restart' => array('nextdns restart'),
            'start' => array('nextdns start'),
            'stop' => array('nextdns stop'),
        ),
        'name' => 'nextdns',
        'pid' => '/var/run/nextdns.pid'
    );

    return $services;
}
