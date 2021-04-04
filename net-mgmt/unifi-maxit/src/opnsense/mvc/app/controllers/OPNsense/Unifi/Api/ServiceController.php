<?php

/*
 * Copyright (C) 2021 Michael Muenz <michael.muenz@max-it.de>
 * All rights reserved.
 */

namespace OPNsense\Unifi\Api;

use OPNsense\Base\ApiMutableServiceControllerBase;

class ServiceController extends ApiMutableServiceControllerBase
{
    protected static $internalServiceClass = '\OPNsense\Unifi\General';
    protected static $internalServiceTemplate = 'OPNsense/Unifi';
    protected static $internalServiceEnabled = 'enabled';
    protected static $internalServiceName = 'unifi';
}
