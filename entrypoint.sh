#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o errtrace

# shellcheck disable=SC2206
cmd_args=(${INPUT_OUTPUT_FORMAT})

# shellcheck disable=SC2206
cmd_args+=(${INPUT_ARGS})

if [ "${INPUT_CONFIG_FILE}" = "disabled" ]; then
    case "$INPUT_OUTPUT_FORMAT" in
    "asciidoc" | "asciidoc table" | "asciidoc document")
        cmd_args+=(--indent "${INPUT_INDENTION}")
        ;;

    "markdown" | "markdown table" | "markdown document")
        cmd_args+=(--indent "${INPUT_INDENTION}")
        ;;
    esac

    if [ -z "${INPUT_TEMPLATE}" ]; then
        INPUT_TEMPLATE=$(printf '<!-- BEGIN_TF_DOCS -->\n{{ .Content }}\n<!-- END_TF_DOCS -->')
    fi
fi

if [ -z "${INPUT_GIT_PUSH_USER_NAME}" ]; then
    INPUT_GIT_PUSH_USER_NAME="gitlab-ci[bot]"
fi

if [ -z "${INPUT_GIT_PUSH_USER_EMAIL}" ]; then
    INPUT_GIT_PUSH_USER_EMAIL="gitlab-ci[bot]@noreply.gitlab.com"
fi

git_setup() {
    git config --global --add safe.directory $GIT_CLONE_PATH

    git config --global user.name "${INPUT_GIT_PUSH_USER_NAME}"
    git config --global user.email "${INPUT_GIT_PUSH_USER_EMAIL}"
    git fetch --depth=1 origin +refs/tags/*:refs/tags/* || true
}

git_add() {
    local file
    file="$1"
    git add "${file}"
    if [ "$(git status --porcelain | grep "$file" | grep -c -E '([MA]\W).+')" -eq 1 ]; then
        echo "::debug Added ${file} to git staging area"
    else
        echo "::debug No change in ${file} detected"
    fi
}

git_status() {
    git status --porcelain | grep -c -E '([MA]\W).+' || true
}

git_commit() {
    if [ "$(git_status)" -eq 0 ]; then
        echo "::debug No files changed, skipping commit"
        exit 0
    fi

    echo "::debug Following files will be committed"
    git status -s

    local args=(
        -m "${INPUT_GIT_COMMIT_MESSAGE}"
    )

    if [ "${INPUT_GIT_PUSH_SIGN_OFF}" = "true" ]; then
        args+=("-s")
    fi

    git commit "${args[@]}"
}

update_doc() {
    local working_dir
    working_dir="$1"
    echo "::debug working_dir=${working_dir}"

    local exec_args
    exec_args=( "${cmd_args[@]}" )

    if [ -n "${INPUT_CONFIG_FILE}" ] && [ "${INPUT_CONFIG_FILE}" != "disabled" ]; then
        local config_file

        if [ -f "${INPUT_CONFIG_FILE}" ]; then
            config_file="${INPUT_CONFIG_FILE}"
        else
            config_file="${working_dir}/${INPUT_CONFIG_FILE}"
        fi

        echo "::debug config_file=${config_file}"
        exec_args+=(--config "${config_file}")
    fi

    if [ "${INPUT_OUTPUT_METHOD}" == "inject" ] || [ "${INPUT_OUTPUT_METHOD}" == "replace" ]; then
        echo "::debug output_mode=${INPUT_OUTPUT_METHOD}"
        exec_args+=(--output-mode "${INPUT_OUTPUT_METHOD}")

        echo "::debug output_file=${INPUT_OUTPUT_FILE}"
        exec_args+=(--output-file "${INPUT_OUTPUT_FILE}")
    fi

    if [ -n "${INPUT_TEMPLATE}" ]; then
        exec_args+=(--output-template "${INPUT_TEMPLATE}")
    fi

    if [ "${INPUT_RECURSIVE}" = "true" ]; then
        if [ -n "${INPUT_RECURSIVE_PATH}" ]; then
            exec_args+=(--recursive)
            exec_args+=(--recursive-path "${INPUT_RECURSIVE_PATH}")
        fi
    fi

    exec_args+=("${working_dir}")

    local success

    echo "::debug terraform-docs" "${exec_args[@]}"
    terraform-docs "${exec_args[@]}"
    success=$?

    if [ $success -ne 0 ]; then
        exit $success
    fi

    if [ "${INPUT_OUTPUT_METHOD}" == "inject" ] || [ "${INPUT_OUTPUT_METHOD}" == "replace" ]; then
        git_add "${working_dir}/${OUTPUT_FILE}"
    fi
}

# go to github repo
cd "${}"

git_setup

if [ -f "${GIT_CLONE_PATH}/${INPUT_ATLANTIS_FILE}" ]; then
    # Parse an atlantis yaml file
    for line in $(yq e '.projects[].dir' "${GIT_CLONE_PATH}/${INPUT_ATLANTIS_FILE}"); do
        update_doc "${line//- /}"
    done
elif [ -n "${INPUT_FIND_DIR}" ] && [ "${INPUT_FIND_DIR}" != "disabled" ]; then
    # Find all tf
    for project_dir in $(find "${INPUT_FIND_DIR}" -name '*.tf' -exec dirname {} \; | uniq); do
        update_doc "${GIT_CLONE_PATH}"
    done
else
    # Split INPUT_WORKING_DIR by commas
    for project_dir in ${INPUT_WORKING_DIR//,/ }; do
        update_doc "${GIT_CLONE_PATH}"
    done
fi

# always set num_changed output
set +e
num_changed=$(git_status)
set -e

if [ "${INPUT_GIT_PUSH}" = "true" ]; then
    git_commit
    git push
else
    if [ "${INPUT_FAIL_ON_DIFF}" = "true" ] && [ "${num_changed}" -ne 0 ]; then
        echo "::error ::Uncommitted change(s) has been found!"
        exit 1
    fi
fi

exit 0