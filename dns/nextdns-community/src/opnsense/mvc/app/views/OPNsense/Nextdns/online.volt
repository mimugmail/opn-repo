<?php
require_once("config.inc");
$email = $config['OPNsense']['nextdns']['general']['email'];
$password = $config['OPNsense']['nextdns']['general']['password'];
?>

<pre id="debug">fetching...</pre>

<script>
    var email = '<?= $email; ?>';
    var password = '<?= $password; ?>';

    $(document).ready(function() {
        ajaxCall(url = "/api/nextdns/online/settings", {}, function(data, status) {
            $('#debug').text(JSON.stringify(data, undefined, 2))

        });
    });
</script>

