<?php

/*
 * Copyright (C) 2021 Miha Kralj <mihak09@gmail.com>
 * All rights reserved.
 */

namespace OPNsense\Nextdns;

class GeneralController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->generalForm = $this->getForm('general');
        $this->view->pick('OPNsense/Nextdns/general');
    }
}
