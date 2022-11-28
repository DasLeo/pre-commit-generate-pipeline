#!/usr/bin/env bash
set -eo pipefail

# globals variables
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Store and return last failure so this can validate every directory passed before exiting
DIFF_ERROR=0

# If on macOS then use gnu-sed from brew
if [[ $OSTYPE == 'darwin'* ]]; then
	SED_BINARY="gsed"
else
	SED_BINARY="sed"
fi

# Replace dotted collections in environments.yml as Jinja2 cannot read
# variables starting with a dot
$SED_BINARY -i -r 's/\.(otc|gcp):$/\1:/g' environments.yml

for file in "$@"; do
  # skip environments.yml as it's only used for data source
  if [ "$file" == "environments.yml" ]; then continue; fi

  generated_pipeline=$(j2 "$file" "environments.yml")
  if [ $? -ne 0 ]; then
    echo "ERROR: generating pipeline YAML for '$file'. Check log output"
    DIFF_ERROR=1
    continue
  fi

  # build destination filename:
  # foo-bar.yml.j2
  # will produce
  # generated-foo-bar.yml
  DIRNAME="$(dirname "${file}")" ; FILENAME="$(basename "${file}")"
  destination_filename="$DIRNAME/generated-${FILENAME%.j2}"

  # Check if file exists already
  if [[ -f "$destination_filename" ]]; then
    # Check if there are differences between the currently commited file and
    # the on j2cli produces
    if ! echo "$generated_pipeline" | diff "$destination_filename" - >/dev/null 2>&1; then
      echo "$generated_pipeline" > $destination_filename
      echo "$destination_filename created, please commit"
      DIFF_ERROR=1
    fi
  # If file does not exist already, create it
  else
    echo "$generated_pipeline" > $destination_filename
    echo "$destination_filename created, please commit"
    DIFF_ERROR=1
  fi
done

exit ${DIFF_ERROR}
