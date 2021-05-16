<?php

namespace OPNsense\Unifi;

class AlertsController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->pick('OPNsense/Unifi/alerts');
    }

}
