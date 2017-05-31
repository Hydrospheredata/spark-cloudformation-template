FROM hydrosphere/mist:0.11.0-2.1.0

ENV MIST_CONFIG=/usr/share/mist/configs/docker.conf
ENV RUN_OPTIONS=
ENV NAMESPACE=

COPY docker-entrypoint.sh /
COPY mist-worker-start.sh /usr/share/mist/bin/
COPY mist-worker-stop.sh /usr/share/mist/bin/
ADD template /usr/share/mist/bin/template

RUN chmod +x /docker-entrypoint.sh && \
    chmod +x /usr/share/mist/bin/*.sh && \
    apk -v --update add \
        py-pip \
        groff \
        less \
        mailcap \
        && \
    pip install --upgrade awscli s3cmd python-magic && \
    apk -v --purge del py-pip && \
    rm /var/cache/apk/*