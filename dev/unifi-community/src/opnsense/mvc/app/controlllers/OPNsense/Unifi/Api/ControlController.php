<?php

/*
 * Copyright (C) 2021 Michael Muenz <michael.muenz@max-it.de>
 * All rights reserved.
 */

namespace OPNsense\Unifi\Api;

use OPNsense\Base\ApiMutableModelControllerBase;
use OPNsense\Core\Config;
use OPNsense\Base\UIModelGrid;
use OPNsense\Core\Backend;

class ControlController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\Unifi\Control';
    protected static $internalServiceTemplate = 'OPNsense/Unifi';
    protected static $internalServiceEnabled = 'enabled';
    protected static $internalModelName = 'control';
    protected static $internalServiceName = 'unifi';
}
