#!/usr/bin/env bash

function displayLog() {
  echo -e "\n"
  awk '{ gsub(/^[[:space:]]+/, ""); print "  [LOG] " $0 }' "${LOG_TMP_FILE}"
}

function logLast() {
  echo -e "$1" | tee -a "${LOG_TMP_FILE}"
}
