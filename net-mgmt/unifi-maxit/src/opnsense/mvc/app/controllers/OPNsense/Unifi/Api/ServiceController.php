<?php

/*
 * Copyright (C) 2021 Michael Muenz <michael.muenz@max-it.de>
 * All rights reserved.
 */

namespace OPNsense\Unifi\Api;

use OPNsense\Base\ApiMutableServiceControllerBase;
use OPNsense\Core\Backend;

class ServiceController extends ApiMutableServiceControllerBase
{
    protected static $internalServiceClass = '\OPNsense\Unifi\General';
    protected static $internalServiceTemplate = 'OPNsense/Unifi';
    protected static $internalServiceEnabled = 'enabled';
    protected static $internalServiceName = 'unifi';

    public function reconfigureAction()
    {
        $status = parent::reconfigureAction();
        (new Backend())->configdRun('cron restart');
        return $status;
    }

    public function truncateLogAction()
    {
        if ($this->request->isPost()) {
            $backend = new Backend();
            $response = $backend->configdRun('unifi truncate_log');
            return array('status' => 'ok', 'response' => trim($response));
        }
        return array('status' => 'failed');
    }

    public function compactDbAction()
    {
        if ($this->request->isPost()) {
            $backend = new Backend();
            $response = $backend->configdRun('unifi compact_db');
            return array('status' => 'ok', 'response' => trim($response));
        }
        return array('status' => 'failed');
    }

    public function versionAction()
    {
        $backend = new Backend();
        $version = trim($backend->configdRun('unifi version'));
        $releaseUrl = '';
        if (!empty($version) && $version !== 'unknown') {
            $releaseUrl = 'https://community.ui.com/releases?search=UniFi+Network+Application+' . urlencode($version);
        } else {
            $releaseUrl = 'https://community.ui.com/releases';
        }

        return array(
            'status' => (!empty($version) && $version !== 'unknown') ? 'ok' : 'not_found',
            'version' => (!empty($version) && $version !== 'unknown') ? $version : null,
            'release_url' => $releaseUrl
        );
    }
}
