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

function unifi_cron()
{
    global $config;

    $jobs = array();

    if (isset($config['OPNsense']['unifi']['general']['enabled']) &&
        $config['OPNsense']['unifi']['general']['enabled'] == 1 &&
        isset($config['OPNsense']['unifi']['general']['scheduler_enabled']) &&
        $config['OPNsense']['unifi']['general']['scheduler_enabled'] == 1) {

        $general = $config['OPNsense']['unifi']['general'];
        $startStr = !empty($general['schedule_start_hour']) ? trim($general['schedule_start_hour']) : '02:00';
        $stopStr = !empty($general['schedule_stop_hour']) ? trim($general['schedule_stop_hour']) : '04:00';
        $start = explode(':', $startStr);
        $stop = explode(':', $stopStr);

        $startMin = isset($start[1]) && $start[1] !== '' ? $start[1] : '00';
        $startHour = isset($start[0]) && $start[0] !== '' ? $start[0] : '02';
        $stopMin = isset($stop[1]) && $stop[1] !== '' ? $stop[1] : '00';
        $stopHour = isset($stop[0]) && $stop[0] !== '' ? $stop[0] : '04';

        $daysMap = array(
            'days_mon' => '1',
            'days_tue' => '2',
            'days_wed' => '3',
            'days_thu' => '4',
            'days_fri' => '5',
            'days_sat' => '6',
            'days_sun' => '0',
        );

        $selectedDays = array();
        foreach ($daysMap as $field => $dayNum) {
            if (!empty($general[$field]) && $general[$field] == '1') {
                $selectedDays[] = $dayNum;
            }
        }

        $days = (count($selectedDays) == 7 || empty($selectedDays)) ? '*' : implode(',', $selectedDays);

        $jobs[]['autocron'] = array(
            '/usr/local/etc/rc.d/unifi start',
            $startMin,
            $startHour,
            '*',
            '*',
            $days
        );

        $jobs[]['autocron'] = array(
            '/usr/local/etc/rc.d/unifi stop',
            $stopMin,
            $stopHour,
            '*',
            '*',
            $days
        );
    }

    return $jobs;
}
