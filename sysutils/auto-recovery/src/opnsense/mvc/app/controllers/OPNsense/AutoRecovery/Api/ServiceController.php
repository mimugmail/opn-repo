<?php

/**
 *    Copyright (C) 2023 Frank Wall
 *    Copyright (C) 2015 Deciso B.V.
 *
 *    All rights reserved.
 *
 *    Redistribution and use in source and binary forms, with or without
 *    modification, are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 *    THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 *    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 *    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *    AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 *    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *    POSSIBILITY OF SUCH DAMAGE.
 *
 */

namespace OPNsense\AutoRecovery\Api;

use OPNsense\Base\ApiMutableServiceControllerBase;
use OPNsense\Core\Backend;
use OPNsense\AutoRecovery\AutoRecovery;

/**
 * Class ServiceController
 * @package OPNsense\AutoRecovery
 */
class ServiceController extends ApiMutableServiceControllerBase
{
    protected static $internalServiceClass = '\OPNsense\AutoRecovery\AutoRecovery';
    protected static $internalServiceTemplate = 'OPNsense/AutoRecovery';
    protected static $internalServiceEnabled = 'general.Enabled';
    protected static $internalServiceName = 'autorecovery';

    /**
     * start countdown
     * @return string
     */
    public function countdownAction()
    {
        $model = new AutoRecovery();
        $action = (string)$model->general->action;
        if (!empty((string)$model->general->configd_command)) {
          // Replace spaces with colons before passing the value to configdRun().
          $configdcmd = str_replace(' ', ':',(string)$model->general->configd_command);
        } else {
          $configdcmd = 'not_found';
        }
        // Convert minutes to seconds
        $countdown = 60 * (string)$model->general->countdown;

        $backend = new Backend();
        $response = $backend->configdRun("autorecovery countdown ${action} ${configdcmd} ${countdown}");
        return array("response" => $response);
    }

    /**
     * get remaining time for current countdown
     * @return string
     */
    public function timeAction()
    {
        $backend = new Backend();
        $response = $backend->configdRun("autorecovery status");
        return array("response" => $response);
    }

    /**
     * abort countdown
     * @return string
     */
    public function abortAction()
    {
        $backend = new Backend();
        $response = $backend->configdRun("autorecovery abort");
        return array("response" => $response);
    }
}