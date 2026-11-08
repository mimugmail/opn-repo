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
}
