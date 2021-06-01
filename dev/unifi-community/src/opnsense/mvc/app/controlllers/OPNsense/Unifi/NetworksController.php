<?php

namespace OPNsense\Unifi;

class NetworksController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->pick('OPNsense/Unifi/networks');
    }

}
