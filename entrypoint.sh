#!/bin/bash
set -euo pipefail

# Set variables
ACTIONSTATUS=0
EXITSTATUS=0

FILECOUNT=0
LOOPCOUNT=0

INPUT_EXTRA_PARAMS="${INPUT_EXTRA_PARAMS:-}"
INPUT_FIND_PATH="${INPUT_FIND_PATH:-.}"
INPUT_FIND_PATTERN="${INPUT_FIND_PATTERN:-*.d2}"
INPUT_FAIL_ON_ERROR="${INPUT_FAIL_ON_ERROR:-true}"
INPUT_VERBOSE="${INPUT_VERBOSE:-true}"
INPUT_CHECK_FORMAT="${INPUT_CHECK_FORMAT:-false}"

cd "${GITHUB_WORKSPACE}"

if [ -n "${INPUT_FILE_LIST:-}" ]; then

  if [ "${INPUT_VERBOSE}" = "true" ]; then
    echo "==> File list specified. Linting files matching this list." >&2
  fi
  # Normalise both commas and spaces as delimiters before splitting
  INPUT_FILE_LIST_NORMALIZED="${INPUT_FILE_LIST//,/ }"
  read -r -a FILELIST <<< "${INPUT_FILE_LIST_NORMALIZED}"

else

  if [ ! -d "${INPUT_FIND_PATH}" ]; then
    echo "==> ERROR: Cannot find '${INPUT_FIND_PATH}'. Please ensure find_path is a directory relative to the root of your project." >&2
    exit 1
  fi

  if [ "${INPUT_VERBOSE}" = "true" ]; then
    echo "==> Searching for '${INPUT_FIND_PATTERN}' files in '${INPUT_FIND_PATH}'." >&2
  fi

  readarray -d '' FILELIST < <(find "${INPUT_FIND_PATH}" -name "${INPUT_FIND_PATTERN}" -print0)

fi

FILECOUNT=${#FILELIST[@]}

if [ "${INPUT_VERBOSE}" = "true" ]; then
  echo "==> Found ${FILECOUNT} file(s) to lint." >&2
fi

if [ "${FILECOUNT}" -eq 0 ]; then
  echo "==> Nothing to do. Exiting." >&2
  exit 0
fi

# Determine the lint command:
#   check_format=true  -> d2 fmt --check <file>  (validates syntax AND enforces formatting)
#   check_format=false -> d2 fmt <file> >/dev/null (validates syntax only, no file modification)
if [ "${INPUT_CHECK_FORMAT}" = "true" ]; then
  LINT_ARGS="fmt --check"
else
  LINT_ARGS="fmt"
fi

for FILE in "${FILELIST[@]}"; do
  LOOPCOUNT=$((LOOPCOUNT + 1))
  if [ "${INPUT_VERBOSE}" = "true" ]; then
    echo "==> Linting ${LOOPCOUNT} of ${FILECOUNT}: ${FILE}" >&2
  fi

  EXITSTATUS=0
  if [ "${INPUT_CHECK_FORMAT}" = "true" ]; then
    # Validate syntax AND enforce canonical formatting.
    # Use || to prevent set -e from exiting early on lint failure.
    # shellcheck disable=SC2086
    /usr/local/bin/d2 ${LINT_ARGS} ${INPUT_EXTRA_PARAMS} "${FILE}" || EXITSTATUS=$?
  else
    # Validate syntax only — discard formatted output, keep only exit code.
    # shellcheck disable=SC2086
    /usr/local/bin/d2 ${LINT_ARGS} ${INPUT_EXTRA_PARAMS} "${FILE}" > /dev/null || EXITSTATUS=$?
  fi

  if [ "${EXITSTATUS}" -ne 0 ]; then
    echo "==> Linting errors found in: ${FILE}" >&2
    ACTIONSTATUS="${EXITSTATUS}"
  fi
done

# Exit with the status of the linting run and user input
if [ "${INPUT_FAIL_ON_ERROR}" = "true" ] && [ "${ACTIONSTATUS}" -ne 0 ]; then
  echo "==> Linting errors found and fail_on_error is true. Exiting with error." >&2
  exit "${ACTIONSTATUS}"
elif [ "${INPUT_FAIL_ON_ERROR}" = "false" ] && [ "${ACTIONSTATUS}" -ne 0 ]; then
  echo "==> Linting errors found and fail_on_error is false. Check logs for errors." >&2
  exit 0
else
  if [ "${INPUT_VERBOSE}" = "true" ]; then
    echo "==> No linting errors found. Exiting with success." >&2
  fi
  exit 0
fi
