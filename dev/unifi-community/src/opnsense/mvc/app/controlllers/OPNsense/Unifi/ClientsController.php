<?php

namespace OPNsense\Unifi;

class ClientsController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->pick('OPNsense/Unifi/clients');
    }

}
