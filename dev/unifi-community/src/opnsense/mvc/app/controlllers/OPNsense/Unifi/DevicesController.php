<?php

namespace OPNsense\Unifi;

class DevicesController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->pick('OPNsense/Unifi/devices');
    }

}
