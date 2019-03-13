# Based on
# https://github.com/openshift/origin-aggregated-logging/blob/release-3.11/fluentd/Dockerfile

FROM registry.access.redhat.com/rhscl/ruby-25-rhel7

ENV LOGGING_FILE_PATH=/var/log/fluentd/fluentd.log \
    LOGGING_FILE_AGE=10 \
    LOGGING_FILE_SIZE=1024000 \
    container=oci

USER 0

RUN \
  INSTALL_PKGS="bc iproute" && \
  RUBY_GEMS="fluent-plugin-splunk-enterprise fluent-plugin-secure-forward" && \
  FLUENTD_LOG_DIR=/var/log/fluentd && \
  FLUENTD_LIB_DIR=/var/lib/fluentd && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
  yum clean all && \
  scl enable rh-ruby25 "gem install -N $RUBY_GEMS" && \
  mkdir -p $FLUENTD_LOG_DIR $FLUENTD_LIB_DIR && \
  chgrp 0 $FLUENTD_LOG_DIR $FLUENTD_LIB_DIR && \
  chmod g=u $FLUENTD_LOG_DIR $FLUENTD_LIB_DIR

ADD configs.d/ /etc/fluent/configs.d/
ADD fluent.conf /etc/fluent/
ADD logs /usr/local/bin/
ADD run.sh ${HOME}/

USER 1000

WORKDIR ${HOME}

CMD ["sh", "run.sh"]

LABEL \
        io.k8s.description="Fluentd container for sending logs to Splunk" \
        name="logging-fluentd-splunk" \
        License="GPLv2+" \
        io.k8s.display-name="Fluentd Splunk" \
        version="v0.1" \
        architecture="x86_64" \
        release="0.1.0.0" \
        io.openshift.tags="logging,elk,fluentd,splunk"
