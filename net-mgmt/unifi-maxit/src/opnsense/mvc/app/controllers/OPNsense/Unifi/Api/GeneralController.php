<?php

/*
 * Copyright (C) 2021 Michael Muenz <michael.muenz@max-it.de>
 * All rights reserved.
 */

namespace OPNsense\Unifi\Api;

use OPNsense\Base\ApiMutableModelControllerBase;

class GeneralController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\Unifi\General';
    protected static $internalModelName = 'general';
}
