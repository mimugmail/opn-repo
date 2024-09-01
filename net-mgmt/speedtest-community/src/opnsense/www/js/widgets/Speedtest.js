
/*
 * Copyright (C) 2024 Deciso B.V.
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
/*
 * Copyright (C) 2024 Deciso B.V.
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

export default class Speedtest extends BaseTableWidget {
    constructor() {
        super();
        this.tickTimeout = 3600;
    }
    getGridOptions() { 
        return {
        };
    }
    getMarkup() {
        let $container = $('<div></div>');
        let $Speedtesttable = this.createTable('speedtest-table', {
            headerPosition: 'left',
        });
        $container.append($Speedtesttable);
        return $container;
    }

    async onWidgetTick() {
        const status_data = await this.ajaxCall('/api/speedtest/service/showstat');
        const recent_data = await this.ajaxCall('/api/speedtest/service/showrecent');
        $('#speedtest_most_recent').html(`<a href="${recent_data['url']}" target="_blank">${recent_data['date']}</a> <strong>Down: ${recent_data['download']} Mbps</strong><br/>(up: ${recent_data['upload']} Mbps, latency: ${recent_data['latency']} ms)`);
        $('#speedtest_avg_latency').html(`<strong>${status_data['latency']['avg']} ms</strong> (min: ${status_data['latency']['min']}, max: ${status_data['latency']['max']})`);
        $('#speedtest_avg_download').html(`<strong>${status_data['download']['avg']} Mbps</strong> (min: ${status_data['download']['min']}, max: ${status_data['download']['max']})`);
        $('#speedtest_avg_upload').html(`<strong>${status_data['upload']['avg']} Mbps</strong> (min: ${status_data['upload']['min']}, max: ${status_data['upload']['max']})`);
 }

    async onMarkupRendered() {
        $(`#${this.id}-title`).html(`<b><a href="/ui/speedtest/">${this.translations['title']}</a></b>`);
        let rows = [];
        rows.push([[this.translations['most_recent']], $('<span id="speedtest_most_recent">').prop('outerHTML')]);
        rows.push([[this.translations['avg_latency']], $('<span id="speedtest_avg_latency">').prop('outerHTML')]);
        rows.push([[this.translations['avg_download']], $('<span id="speedtest_avg_download">').prop('outerHTML')]);
        rows.push([[this.translations['avg_upload']], $('<span id="speedtest_avg_upload">').prop('outerHTML')]);

        super.updateTable('speedtest-table', rows);
    }
}

