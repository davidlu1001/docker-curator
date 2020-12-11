FROM python:3.8-alpine

ENV GOSU_VERSION 1.12
RUN set -eux; \
	\
	apk --no-cache add bash && \
	pip install elasticsearch-curator==5.8.3 && \
	pip install boto3==1.16.30 && \
	pip install requests-aws4auth==1.0.1 && \
	apk add --no-cache --virtual .gosu-deps \
	ca-certificates \
	dpkg \
	gnupg \
	; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
	# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
	# clean up fetch dependencies
	apk del --no-network .gosu-deps; \
	\
	chmod +x /usr/local/bin/gosu; \
	# verify that the binary works
	gosu --version; \
	gosu nobody true

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN addgroup -S curator && adduser -S curator -G curator

RUN mkdir -p /etc/curator/

COPY docker-entrypoint.sh /

COPY config/* /etc/curator/

ENV UNIT=days
ENV UNIT_COUNT=14
ENV ELASTICSEARCH_HOST=elasticsearch
ENV TYPE=snapshot
ENV INDEX_PREFIX=.kibana
ENV REPO_NAME=snapshot-repo
ENV DRY_RUN=True

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["snapshot", ".kibana", "snapshot-repo", "True"]