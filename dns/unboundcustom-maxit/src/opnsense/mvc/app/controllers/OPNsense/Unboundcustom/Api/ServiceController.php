<?php

/*
 * Copyright (C) 2021 Michael Muenz <michael.muenz@max-it.de>
 * All rights reserved.
 */

namespace OPNsense\Unboundcustom\Api;

use OPNsense\Base\ApiMutableServiceControllerBase;

class ServiceController extends ApiMutableServiceControllerBase
{
    protected static $internalServiceClass = '\OPNsense\Unboundcustom\General';
    protected static $internalServiceTemplate = 'OPNsense/Unboundcustom';
    protected static $internalServiceEnabled = 'enabled';
    protected static $internalServiceName = 'unboundcustom';
}
