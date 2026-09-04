#!/usr/bin/with-contenv bashio

bashio::config.require 'stack_name'
bashio::config.require 'access_token'

CONTENV="/var/run/s6/container_environment"

set_env() {
    printf '%s' "${2}" > "${CONTENV}/${1}"
}

set_env STACK_NAME "$(bashio::config 'stack_name')"
set_env ACCESS_TOKEN "$(bashio::config 'access_token')"
set_env INSTANCE_NAME "$(bashio::config 'instance_name' 'homeassistant')"
set_env SCRAPE_INTERVAL "$(bashio::config 'scrape_interval' '60s')"

if bashio::config.has_value 'alloy_log_level'; then
    set_env ALLOY_LOG_LEVEL "$(bashio::config 'alloy_log_level')"
elif bashio::config.has_value 'log_level'; then
    set_env ALLOY_LOG_LEVEL "$(bashio::config 'log_level')"
else
    set_env ALLOY_LOG_LEVEL "info"
fi

MIN_LOG_LEVEL=$(bashio::config 'min_log_level' 'info')

level_to_drop_regex() {
    case "${1:-}" in
        critical) echo 'debug|info|notice|warning|warn|error|err' ;;
        error)    echo 'debug|info|notice|warning|warn' ;;
        warning)  echo 'debug|info|notice' ;;
        notice)   echo 'debug|info' ;;
        info)     echo 'debug' ;;
        debug)    echo '' ;;
        *)        echo 'debug' ;;
    esac
}

GLOBAL_DROP_REGEX=$(level_to_drop_regex "${MIN_LOG_LEVEL}")
if [ -n "${GLOBAL_DROP_REGEX}" ]; then
    set_env GLOBAL_DROP_SELECTOR "{level=~\"${GLOBAL_DROP_REGEX}\"}"
else
    set_env GLOBAL_DROP_SELECTOR '{level="__drop_none__"}'
fi

JOURNAL_PATH="/var/log/journal"
if ! bashio::fs.directory_exists "${JOURNAL_PATH}" || [ -z "$(ls -A "${JOURNAL_PATH}" 2>/dev/null)" ]; then
    JOURNAL_PATH="/run/log/journal"
fi
set_env JOURNAL_PATH "${JOURNAL_PATH}"

CUSTOM_DIR="/config/alloy"
mkdir -p "${CUSTOM_DIR}" /data/alloy/conf.d
rm -f /data/alloy/conf.d/*.alloy

cp /etc/alloy/00-common.alloy /etc/alloy/01-metrics.alloy /etc/alloy/02-logs.alloy /data/alloy/conf.d/

if [ ! -s "${CUSTOM_DIR}/custom.alloy" ]; then
    cp /etc/alloy/custom.alloy.default "${CUSTOM_DIR}/custom.alloy"
fi
cp "${CUSTOM_DIR}"/*.alloy /data/alloy/conf.d/ 2>/dev/null || true

bashio::log.info "Alloy configuration prepared."
