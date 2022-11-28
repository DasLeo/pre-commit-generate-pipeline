#!/usr/bin/env bash
#set -eo pipefail

# DELETE ME FOR DEBUGGING ONLY !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
set -exo pipefail


# globals variables
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Store and return last failure so this can validate every directory passed before exiting
DIFF_ERROR=0

for file in "$@"; do
  generated_pipeline=$(j2 "$file" "$SCRIPT_DIR/../environments.yml")
  if [ $? -ne 0 ]; then
    echo "ERROR: generating pipeline YAML for '$file'"
    DIFF_ERROR=1
  fi
  destination_filename=${file%.j2}
  if [[ -f "$destination_filename" ]]; then
    if ! echo "$generated_pipeline" | diff "$destination_filename" -; then
      DIFF_ERROR=1
    fi
  else
    echo "$destination_filename has not been generated yet"
    echo "$generated_pipeline" > $destination_filename
    DIFF_ERROR=1
  fi
  #terraform fmt -diff -check "$file" || DIFF_ERROR=$?
done

exit ${DIFF_ERROR}
