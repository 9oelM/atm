#!/bin/bash

# example: atm-parse-target-yml.sh "targets/shopify.yml" ".domains.in_scope.wildcard[]"
# example result:
# shopifykloud.com
# shopifycloud.com
# shopify.com
TARGET_PATH="$1"
PROPERTY="$2"
DELIMITER="$3"

[ -z "${TARGET_PATH}" ] && echo "Error: TARGET_PATH is empty" exit 1
[ -z "${PROPERTY}" ] && echo "Error: PROPERTY is empty" && exit 1
[ -z "${DELIMITER}" ] && DELIMITER="\n"

[ ! -f "${TARGET_PATH}" ] && echo "${TARGET_PATH} does not exist."

result=$(cat "${TARGET_PATH}" | yq "${PROPERTY}" | xargs | sed -e "s/\s/\\${DELIMITER}/g")

echo -e -n "${result}"
