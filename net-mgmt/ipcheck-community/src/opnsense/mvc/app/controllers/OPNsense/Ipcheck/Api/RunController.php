<?php

/*
 * Copyright 2021 Miha Kralj
 *    All rights reserved.
 *
 *    Redistribution and use in source and binary forms, with or without
 *    modification, are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 *    THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 *    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 *    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *    AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 *    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *    POSSIBILITY OF SUCH DAMAGE.
 */
namespace OPNsense\Ipcheck\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\Core\Backend;

class RunController extends ApiControllerBase
{
    public function statusAction()
    {
        return (new Backend())->configdpRun("ipcheck status");
    }
    public function allAction()
    {
        return (new Backend())->configdpRun("ipcheck all");
    }
    public function listAction()
    {
        return (new Backend())->configdpRun("ipcheck list");
    }
    public function vpnapiAction()
    {
        return (new Backend())->configdpRun("ipcheck vpnapi");
    }
    public function proxycheckAction()
    {
        return (new Backend())->configdpRun("ipcheck proxycheck");
    }
    public function ip2proxyAction()
    {
        return (new Backend())->configdpRun("ipcheck ip2proxy");
    }    
    public function ip2locAction()
    {
        return (new Backend())->configdpRun("ipcheck ip2loc");
    }    
    public function ipqsAction()
    {
        return (new Backend())->configdpRun("ipcheck ipqs");
    }
    public function onionooAction()
    {
        return (new Backend())->configdpRun("ipcheck onionoo");
    }

}