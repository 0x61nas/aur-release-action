function generate_commit_message {
  local file_name=$1
  local new_version=$2

  echo "${INPUT_COMMIT_MESSAGE}" > /tmp/commit_message

  sed -i "s/%VERSION%/${new_version}/g" /tmp/commit_message

  FILENAME_REGEX="%FILENAME%"
  if [[ -z "$file_name" ]]; then
    FILENAME_REGEX="%FILENAME% "
  fi
  sed -i "s/${FILENAME_REGEX}/${file_name}/g" /tmp/commit_message

  # shellcheck disable=SC2005
  echo "$(cat /tmp/commit_message)"
}

function commit {
  git commit --allow-empty -m "$1"
}
