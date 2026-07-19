
/*
 * Copyright (C) 2025 Miha Kralj
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

export default class Ipcheck extends BaseTableWidget {
    constructor(config) {
        super(config);
        this.configurable = true;
    }

    getGridOptions() {
        return {
            // trigger overflow-y:scroll after 500px height
            sizeToContent: 500,
        };
    }

    getMarkup() {
        let $container = $('<div></div>');
        $container.append($('<div id="ipcheck-timestamp"><small>&nbsp;</small></div>'));
        $container.append(this.createTable('ipcheck-table', {
            headerPosition: 'top',
            headers: ['', 'IPv4', 'IPv6'],
        }));
        return $container;
    }

    async getWidgetOptions() {
        return {
            rows: {
                title: this.translations.rows,
                type: 'select_multiple',
                options: [
                    {value: 'address', label: this.translations.address},
                    {value: 'isp', label: this.translations.isp},
                    {value: 'vpn', label: this.translations.vpn},
                    {value: 'risk', label: this.translations.risk},
                ],
                default: ['address', 'isp', 'vpn', 'risk'],
            },
        };
    }

    _s(value) {
        return (value === false || value === null || value === undefined) ? '' : value;
    }

    _flag(value) {
        return value === true
            ? '<span class="label label-danger">True</span>'
            : '<span class="label label-success">False</span>';
    }

    _addressCell(rec) {
        if (!rec || !rec.ip) {
            return '';
        }
        return `${rec.ip}<small><br/>${this._s(rec.network)}<br/>${this._s(rec.network_type)}</small>`;
    }

    _ispCell(rec) {
        if (!rec || !rec.ip) {
            return '';
        }
        return `${this._s(rec.isp)}<small><br/>${this._s(rec.asn)}<br/>${this._s(rec.city)}<br/>${this._s(rec.region)}<br/>${this._s(rec.country)}</small>`;
    }

    _vpnCell(rec) {
        if (!rec || !rec.ip) {
            return '';
        }
        return `${this._flag(rec.proxy)}<br/>${this._flag(rec.vpn)}<br/>${this._flag(rec.tor)}`;
    }

    _riskCell(rec) {
        if (!rec || !rec.ip) {
            return '';
        }
        return `<small>${this._s(rec.ipqs_fraud_score)}<br/>${this._s(rec.proxycheck_risk)}</small>`;
    }

    async onWidgetTick() {
        const config = await this.getWidgetConfig();
        const data = await this.ajaxCall('/api/ipcheck/run/status');

        $('#ipcheck-timestamp small').text(data.timestamp ? data.timestamp : ' ');

        let rows = [];
        if (config.rows.includes('address')) {
            rows.push([this.translations.address, this._addressCell(data.ipv4), this._addressCell(data.ipv6)]);
        }
        if (config.rows.includes('isp')) {
            rows.push([this.translations.isp, this._ispCell(data.ipv4), this._ispCell(data.ipv6)]);
        }
        if (config.rows.includes('vpn')) {
            rows.push([this.translations.vpn, this._vpnCell(data.ipv4), this._vpnCell(data.ipv6)]);
        }
        if (config.rows.includes('risk')) {
            rows.push([this.translations.risk, this._riskCell(data.ipv4), this._riskCell(data.ipv6)]);
        }

        this.updateTable('ipcheck-table', rows);
    }

    async onMarkupRendered() {
        $(`#${this.id}-title`).html(`<b><a href="/ui/ipcheck/">${this.translations.title}</a></b>`);
    }
}
