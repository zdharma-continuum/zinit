# Fix permissions on /data
if [[ -z "$QUIET" ]]
then
  echo "Setting owner of /data to ${PUID}:${PGID}" >&2
fi

sudo chown "${PUID}:${PGID}" /data
sudo chown -R "${PUID}:${PGID}" /data

# sync files between /data-static and /data
if [[ -z "$NOTHING_FANCY" ]]
then
  if [[ -z "$QUIET" ]]
  then
    echo "Copying files from /data-static to /data" >&2
  fi
  rsync -raq /data-static/ /data
fi

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: ft=zsh sw=2 ts=2 et
