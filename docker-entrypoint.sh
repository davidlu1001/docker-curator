#!/usr/bin/env bash

set -euxo pipefail

curr_date=$(date "+%Y%m%d%H%M")

if [[ $# -ne 0 ]] && [[ $# -ne 4 ]]
then
	echo "Illegal number of parameters"
	exit 1
fi

TYPE=$1
INDEX_PREFIX=$2
REPO_NAME=$3
DRY_RUN=$4

if [[ "${TYPE}" != "snapshot" ]] && [[ "${TYPE}" != "restore" ]]
then
	echo "Illegal value for TYPE, should be [snapshot|restore]"
	exit 1
fi

case "${DRY_RUN}" in
     True)
          DRY_RUN="--dry-run"
          ;;
     False)
          DRY_RUN=""
          ;;
     *)
		  echo "Invalid value for ENV variable 'DRY_RUN' should be: [True|False]"
		  exit 1
          ;;
esac

case "${WAIT}" in
     True)
          WAIT_CLI="--wait_for_completion"
          ;;
     False)
          WAIT_CLI="--no-wait_for_completion"
          ;;
     *)
		  echo "Invalid value for ENV variable 'WAIT' should be: [True|False]"
		  exit 1
          ;;
esac

if [[ "${LOGLEVEL}" == "DEBUG" ]]
then
	# enable logging for elasticsearch and urllib3 - which hide by default as in blacklist
	sed -i -e "/blacklist/s/[[][^]]*[]]/[]/g" /etc/curator/config.yml 
fi

# Add curator as command if needed
if [[ "${1:0:1}" == '-' ]]; then
	set -- curator "$@"
fi

# snapshot creation / removal
if [[ "$TYPE" == 'snapshot' ]]; then
	# for all indexes for ES
	if [[ "${INDEX_PREFIX}" == 'ALL' ]]; then
		/usr/local/bin/curator --config /etc/curator/config.yml ${DRY_RUN} /etc/curator/actions_snapshot.yml
	else
    	# create snapshot for index(es) in the same repo
		/usr/local/bin/curator_cli \
			${DRY_RUN} \
			--host "${ELASTICSEARCH_HOST}" \
			--port 9200 \
			snapshot \
			--repository "${REPO_NAME}" \
			--name "${INDEX_PREFIX}-${curr_date}" \
			${WAIT_CLI} \
			--skip_repo_fs_check \
			--filter_list "{\"filtertype\":\"pattern\",\"kind\":\"prefix\",\"value\":\"${INDEX_PREFIX}\"}"

    	# remove old snapshots for index(es) in the same repo
		/usr/local/bin/curator_cli \
			${DRY_RUN} \
			--host "${ELASTICSEARCH_HOST}" \
			--port 9200 \
			delete_snapshots \
			--repository "${REPO_NAME}" \
			--ignore_empty_list \
			--retry_interval 120 \
			--retry_count 100 \
			--filter_list "[{\"filtertype\":\"age\",\"source\":\"creation_date\",\"direction\":\"older\",\"unit\":\"${UNIT}\",\"unit_count\":\"${UNIT_COUNT}\"},{\"filtertype\":\"pattern\",\"kind\":\"prefix\",\"value\":\"${INDEX_PREFIX}\"}]"
	fi
fi

# index restore
if [[ "$TYPE" == 'restore' ]]; then
	# for all indexes for ES
	if [[ "${INDEX_PREFIX}" == 'ALL' ]]; then
		/usr/local/bin/curator --config /etc/curator/config.yml ${DRY_RUN} /etc/curator/actions_restore.yml
	else
		# close first
		/usr/local/bin/curator_cli \
			${DRY_RUN} \
			--host "${ELASTICSEARCH_HOST}" \
			--port 9200 \
			close \
			--ignore_empty_list \
			--filter_list "{\"filtertype\":\"pattern\",\"kind\":\"prefix\",\"value\":\"${INDEX_PREFIX}\"}"
    	# restore
		/usr/local/bin/curator_cli \
			${DRY_RUN} \
			--host "${ELASTICSEARCH_HOST}" \
			--port 9200 \
			restore \
			--repository "${REPO_NAME}" \
			${WAIT_CLI} \
			--skip_repo_fs_check \
			--ignore_empty_list \
			--filter_list "[{\"filtertype\":\"state\"},{\"filtertype\":\"pattern\",\"kind\":\"prefix\",\"value\":\"${INDEX_PREFIX}\"}]"
	fi
fi
