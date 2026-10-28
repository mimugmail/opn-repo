<?php

/*
 * Copyright (C) 2026 Blip9575
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

namespace OPNsense\Speedtest\Api;

use OPNsense\Base\ApiMutableModelControllerBase;
use OPNsense\Core\Backend;
use OPNsense\Core\Config;
use OPNsense\Cron\Cron;

/**
 * shaper settings (get/set) and actions; kept apart from the service
 * controller so changing the traffic shaper needs its own privilege
 */
class ShaperController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\Speedtest\Speedtest';
    protected static $internalModelName = 'speedtest';

    /**
     * cron tasks owned by the shaper settings: command => [setting, description]
     */
    private const CRON_JOBS = [
        'speedtest scheduled' => ['schedule', 'Run scheduled speedtest'],
        'speedtest setshaper' => ['enabled', 'Set shaper bandwidth from speedtest results'],
    ];

    /**
     * commands the tasks had before: command => current command
     */
    private const CRON_RENAMED = [
        'speedtest run' => 'speedtest scheduled',
    ];

    /**
     * minutes after the last speedtest that the shaper is set
     */
    private const SHAPER_DELAY = 15;

    /**
     * cron times from frequency and offset: the speedtests spread over 00:00 - 06:00
     * at "offset" minutes past the hour, the shaper SHAPER_DELAY minutes after the last
     * @return array command => [minutes, hours]
     */
    private function cronTimes($settings)
    {
        $frequency = max(1, min(6, (int)(string)$settings->frequency));
        $offset = max(0, min(59, (int)(string)$settings->offset));
        $hours = [];
        for ($i = 0; $i < $frequency; $i++) {
            $hours[] = intdiv($i * 6, $frequency);
        }
        $shaper = end($hours) * 60 + $offset + self::SHAPER_DELAY;
        return [
            'speedtest scheduled' => [(string)$offset, implode(',', $hours)],
            'speedtest setshaper' => [(string)($shaper % 60), (string)intdiv($shaper, 60)],
        ];
    }

    /**
     * save the settings; a save of the shaper form ("enabled" posted) also updates the
     * shaper's cron task, the speedtest schedule is only applied by scheduleAction
     */
    public function setAction()
    {
        $result = parent::setAction();
        $posted = $this->request->getPost(static::$internalModelName);
        if (($result['result'] ?? '') == 'saved' && isset($posted['shaper']['enabled'])) {
            $this->syncCron(['speedtest setshaper']);
        }
        return $result;
    }

    /**
     * MSS clamping status of the shaper interface
     */
    public function mssAction()
    {
        return json_decode((new Backend())->configdRun("speedtest mssshaper"), true) ??
            ['status' => 'error', 'message' => gettext('No response from configd')];
    }

    /**
     * set MSS clamping on the shaper interface (its MSS setting to its MTU)
     */
    public function setmssAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'error', 'message' => gettext('Use POST')];
        }
        return json_decode((new Backend())->configdRun("speedtest setmss"), true) ??
            ['status' => 'error', 'message' => gettext('No response from configd')];
    }

    /**
     * apply the saved speedtest schedule (and the shaper time that follows it) to cron
     */
    public function scheduleAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'error', 'message' => gettext('Use POST')];
        }
        if (!$this->syncCron(array_keys(self::CRON_JOBS))) {
            return ['status' => 'error', 'message' => gettext('The cron tasks could not be saved')];
        }
        $settings = $this->getModel()->shaper;
        $times = [];
        foreach ($this->cronTimes($settings) as $command => [$minutes, $hours]) {
            $times[$command] = implode(', ', array_map(function ($hour) use ($minutes) {
                return sprintf('%02d:%02d', $hour, $minutes);
            }, explode(',', $hours)));
        }
        return ['status' => 'ok', 'message' => sprintf(
            gettext('Speedtests at %s (%s); shaper set at %s (%s)'),
            $times['speedtest scheduled'],
            (string)$settings->schedule == '1' ? gettext('enabled') : gettext('disabled'),
            $times['speedtest setshaper'],
            (string)$settings->enabled == '1' ? gettext('enabled') : gettext('disabled')
        )];
    }

    /**
     * a task is created the first time its setting is enabled; afterwards its enabled
     * flag follows the setting and its time follows frequency and offset
     */
    private function syncCron($commands)
    {
        $settings = $this->getModel()->shaper;
        $times = $this->cronTimes($settings);
        $cron = new Cron();
        $changed = false;
        foreach (array_intersect_key(self::CRON_JOBS, array_flip($commands)) as $command => [$setting, $description]) {
            $enabled = (string)$settings->$setting == '1' ? '1' : '0';
            [$minutes, $hours] = $times[$command];
            $job = null;
            foreach ($cron->jobs->job->iterateItems() as $item) {
                if ((string)$item->origin == 'Speedtest' && (string)$item->command == $command) {
                    $job = $item;
                    break;
                }
            }
            // a task of an older version takes the new command instead of being left running beside it
            foreach ($job === null ? $cron->jobs->job->iterateItems() : [] as $item) {
                if ((string)$item->origin == 'Speedtest' && (self::CRON_RENAMED[(string)$item->command] ?? '') == $command) {
                    $job = $item;
                    $job->command = $command;
                    $job->description = $description;
                    $changed = true;
                    break;
                }
            }
            if ($job === null) {
                if ($enabled == '0') {
                    continue;
                }
                $job = $cron->getNodeByReference('jobs.job.' . $cron->newDailyJob('Speedtest', $command, $description));
            }
            foreach (['enabled' => $enabled, 'minutes' => $minutes, 'hours' => $hours] as $field => $value) {
                if ((string)$job->$field != $value) {
                    $job->$field = $value;
                    $changed = true;
                }
            }
        }
        if (!$changed) {
            return true;
        }
        if ($cron->performValidation()->count() > 0) {
            return false;
        }
        $cron->serializeToConfig();
        Config::getInstance()->save();
        (new Backend())->configdRun('cron restart');
        return true;
    }

    /**
     * set the shaper pipes from the best speedtest results now (a raise is not held)
     */
    public function applyAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'error', 'message' => gettext('Use POST')];
        }
        return json_decode((new Backend())->configdRun("speedtest setshaper now"), true) ??
            ['status' => 'error', 'message' => gettext('No response from configd')];
    }

    /**
     * updates of the pipes, newest first
     */
    public function historyAction()
    {
        return json_decode((new Backend())->configdRun("speedtest shaperhistory"), true) ?? [];
    }

    /**
     * the updates of the pipes as csv
     */
    public function exportAction()
    {
        $this->response->setContentType('text/csv', 'UTF-8');
        $this->response->setHeader('Content-Disposition', 'attachment; filename="shaper.csv"');
        return (new Backend())->configdRun("speedtest shaperhistory csv");
    }

    public function clearhistoryAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'error', 'message' => gettext('Use POST')];
        }
        return json_decode((new Backend())->configdRun("speedtest clearshaperhistory"), true) ??
            ['status' => 'error', 'message' => gettext('No response from configd')];
    }

    /**
     * create pipes, queues and rules on the interface when none are found
     */
    public function createAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'error', 'message' => gettext('Use POST')];
        }
        return json_decode((new Backend())->configdRun("speedtest createshaper"), true) ??
            ['status' => 'error', 'message' => gettext('No response from configd')];
    }
}
