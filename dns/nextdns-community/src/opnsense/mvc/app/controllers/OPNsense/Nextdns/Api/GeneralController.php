<?php

/*
 * Copyright (C) 2021 Miha Kralj <mihak09@gmail.com>
 * All rights reserved.
 */

namespace OPNsense\Nextdns\Api;

use OPNsense\Base\ApiMutableModelControllerBase;

class GeneralController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\Nextdns\General';
    protected static $internalModelName = 'general';
}