<?php

namespace OPNsense\Unifi\Api;

use OPNsense\Base\ApiMutableModelControllerBase;
use OPNsense\Core\Config;
use OPNsense\Base\UIModelGrid;
use OPNsense\Core\Backend;

class SettingsController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\Unifi\Settings';
    protected static $internalServiceTemplate = 'OPNsense/Unifi';
    protected static $internalServiceEnabled = 'enabled';
    protected static $internalModelName = 'settings';
}
