<?php

namespace OPNsense\Nextdns\Api;

use OPNsense\Base\ApiMutableServiceControllerBase;
use OPNsense\Core\Backend;
use OPNsense\Nextdns\General;

/**
 * Class ServiceController
 * @package OPNsense\Nextdns
 */
class ServiceController extends ApiMutableServiceControllerBase
{
    protected static $internalServiceClass = '\OPNsense\Nextdns\General';
    protected static $internalServiceTemplate = 'OPNsense/Nextdns';
    protected static $internalServiceEnabled = 'enabled';
    protected static $internalServiceName = 'nextdns';
}