#!/usr/bin/env bash

exit $(curl https://api.github.com/repos/muldjord/skyscraper/releases/latest | jq -r '((now - (.published_at | fromdateiso8601) ) / (60 * 60 * 24) | trunc)')
