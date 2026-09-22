#!/usr/bin/env bash

# Electric Shell palette: blue timestamps, purple labels, green success,
# orange warnings, and red errors. Saved logs contain no ANSI escapes.
log() {
  local level="$1" message="$2" color timestamp
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  case "$level" in
    OK) color='0;255;0' ;;
    WARN) color='255;165;0' ;;
    ERROR) color='255;0;0' ;;
    *) color='186;125;255' ;;
  esac
  printf '\033[38;2;0;191;255m%s\033[0m \033[38;2;%sm[%s]\033[0m %s\n' \
    "$timestamp" "$color" "$level" "$message"
  printf '%s [%s] %s\n' "$timestamp" "$level" "$message" >> "$SAFARI_LOG_DIR/events.log"
}

# Keep HTTP error bodies: curl --fail would hide Safari's actual error message.
webdriver_request() {
  local method="$1" path="$2" label="$3" data="${4:-}"
  local http_code curl_code=0
  local -a args=(--silent --show-error --connect-timeout 5 --max-time 60
    --request "$method" --output "$SAFARI_LOG_DIR/$label.json" --write-out '%{http_code}')
  if [[ -n "$data" ]]; then
    args+=(--header 'Content-Type: application/json' --data "$data")
  fi
  log INFO "$method $path"
  http_code=$(curl "${args[@]}" "http://127.0.0.1:4444$path" 2> "$SAFARI_LOG_DIR/$label.stderr") || curl_code=$?
  log INFO "HTTP $http_code; curl exit $curl_code"
  cat "$SAFARI_LOG_DIR/$label.stderr"
  if [[ -s "$SAFARI_LOG_DIR/$label.json" ]]; then
    cat "$SAFARI_LOG_DIR/$label.json"
    printf '\n'
  fi
  if [[ "$curl_code" -ne 0 || "$http_code" != 2?? ]]; then
    log ERROR "$method $path failed; response saved as $label.json"
    return 1
  fi
}
