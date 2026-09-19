# ha-system-alloy
This plugin's goal is to export system level metrics and logs via alloy to grafana cloud.

[The official grafana plugin](https://github.com/grafana/home-assistant-addons) does something similar, but the metrics
it provides are based on entities exposed through [homeassistant itself](https://www.home-assistant.io/integrations/prometheus/), which
is more meant for exposing actual smart home entities, rather than host metrics (of which some can be exposed via the
[System monitor integration](https://www.home-assistant.io/integrations/systemmonitor/)).

Instead, we use a similar approach as the [prometheus-node-exporter](https://github.com/loganmarchione/hassos-addons), but withouth
publishing the metrics outside of haos.

Another shortcoming of the official grafana plugin are the logs: You basically only get the alloy logs itself, and maybe
the system logs (very brittle implementation - didn't get it to work :shrug:).

Instead we use the same approach as [ha-addon-alloy](https://github.com/ecohash-co/ha-addon-alloy), which goes through journald
to get all logs.

## Testing

See [e2e/README.md](e2e/README.md) for the local VM-based end-to-end test setup.
