#!/bin/bash
set -euo pipefail

# Set variables
ACTIONSTATUS=0

FILECOUNT=0
LOOPCOUNT=0

INPUT_EXTRA_PARAMS="${INPUT_EXTRA_PARAMS:-}"
# Parse extra_params into an array once to prevent word-splitting and glob expansion
EXTRA_PARAMS=()
if [ -n "${INPUT_EXTRA_PARAMS}" ]; then
  read -r -a EXTRA_PARAMS <<< "${INPUT_EXTRA_PARAMS}"
fi
INPUT_FIND_PATH="${INPUT_FIND_PATH:-.}"
INPUT_FIND_PATTERN="${INPUT_FIND_PATTERN:-*.d2}"
INPUT_FAIL_ON_ERROR="${INPUT_FAIL_ON_ERROR:-true}"
INPUT_VERBOSE="${INPUT_VERBOSE:-true}"
INPUT_FORMAT="${INPUT_FORMAT:-true}"
INPUT_VALIDATE="${INPUT_VALIDATE:-true}"
INPUT_RENDER="${INPUT_RENDER:-true}"

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

  readarray -d '' FILELIST < <(find -- "${INPUT_FIND_PATH}" -name "${INPUT_FIND_PATTERN}" -print0)

fi

FILECOUNT=${#FILELIST[@]}

if [ "${INPUT_VERBOSE}" = "true" ]; then
  echo "==> Found ${FILECOUNT} file(s) to lint." >&2
fi

if [ "${FILECOUNT}" -eq 0 ]; then
  echo "==> Nothing to do. Exiting." >&2
  exit 0
fi

# Helper: run a check command and accumulate failure status
run_check() {
  local CHECK_NAME="$1"
  local FILE="$2"
  shift 2
  local CHECK_EXIT_CODE=0
  "$@" || CHECK_EXIT_CODE=$?
  if [ "${CHECK_EXIT_CODE}" -ne 0 ]; then
    echo "==> [${CHECK_NAME}] FAILED for: ${FILE}" >&2
    ACTIONSTATUS="${CHECK_EXIT_CODE}"
  fi
}

for FILE in "${FILELIST[@]}"; do
  LOOPCOUNT=$((LOOPCOUNT + 1))
  if [ "${INPUT_VERBOSE}" = "true" ]; then
    echo "==> Checking ${LOOPCOUNT} of ${FILECOUNT}: ${FILE}" >&2
  fi

  # 1. Format check — d2 fmt --check (never modifies the workspace)
  if [ "${INPUT_FORMAT}" = "true" ]; then
    if [ "${INPUT_VERBOSE}" = "true" ]; then
      echo "  -> format check (d2 fmt --check)" >&2
    fi
    run_check "format" "${FILE}" /usr/local/bin/d2 fmt --check "${EXTRA_PARAMS[@]}" "${FILE}"
  fi

  # 2. Syntax validation — d2 validate
  if [ "${INPUT_VALIDATE}" = "true" ]; then
    if [ "${INPUT_VERBOSE}" = "true" ]; then
      echo "  -> validate (d2 validate)" >&2
    fi
    run_check "validate" "${FILE}" /usr/local/bin/d2 validate "${EXTRA_PARAMS[@]}" "${FILE}"
  fi

  # 3. Render check — d2 <file> /dev/null (ensures the diagram renders)
  if [ "${INPUT_RENDER}" = "true" ]; then
    if [ "${INPUT_VERBOSE}" = "true" ]; then
      echo "  -> render check (d2 <file> /dev/null)" >&2
    fi
    run_check "render" "${FILE}" /usr/local/bin/d2 "${EXTRA_PARAMS[@]}" "${FILE}" /dev/null
  fi
done

# Exit with the accumulated status and user preference
if [ "${INPUT_FAIL_ON_ERROR}" = "true" ] && [ "${ACTIONSTATUS}" -ne 0 ]; then
  echo "==> Errors found and fail_on_error is true. Exiting with error." >&2
  exit "${ACTIONSTATUS}"
elif [ "${INPUT_FAIL_ON_ERROR}" = "false" ] && [ "${ACTIONSTATUS}" -ne 0 ]; then
  echo "==> Errors found and fail_on_error is false. Check logs for details." >&2
  exit 0
else
  if [ "${INPUT_VERBOSE}" = "true" ]; then
    echo "==> All checks passed. Exiting with success." >&2
  fi
  exit 0
fi
