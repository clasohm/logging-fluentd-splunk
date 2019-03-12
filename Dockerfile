# Based on
# https://github.com/openshift/origin-aggregated-logging/blob/release-3.11/fluentd/Dockerfile

FROM registry.access.redhat.com/rhscl/ruby-25-rhel7

ENV DATA_VERSION=1.6.0 \
    FLUENTD_VERSION=0.12.43 \
    FLUENTD_ES=1.13.0-1 \
    FLUENTD_KUBE_METADATA=1.0.1-1 \
    FLUENTD_REWRITE_TAG=1.5.6-1 \
    FLUENTD_SECURE_FWD=0.4.5-2 \
    FLUENTD_SYSTEMD=0.0.9-1 \
    FLUENTD_VIAQ_DATA_MODEL=0.0.13 \
    FLUENTD_AUDIT_LOG_PARSER_VERSION=0.0.5 \
    FLUENTD_RECORD_MODIFIER=0.6.1 \
    GEM_HOME=/usr/share/gems \
    HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:/usr/libexec/fluentd/bin:$PATH \
    RUBY_VERSION=2.0 \
    SERVERENGINE_VERSION=1.6.0 \
    LOGGING_FILE_PATH=/var/log/fluentd/fluentd.log \
    LOGGING_FILE_AGE=10 \
    LOGGING_FILE_SIZE=1024000 \
    container=oci

USER 0
RUN yum-config-manager --enable rhel-7-server-ose-3.11-rpms && \
    yum-config-manager --enable rhel-7-server-optional-rpms && \
    INSTALL_PKGS="fluentd-${FLUENTD_VERSION} \
                  hostname \
                  bc \
                  iproute \
                  ruby-devel \
                  rubygem-fluent-plugin-secure-forward" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all

RUN gem install fluent-plugin-splunk-hec

LABEL \
        io.k8s.description="Fluentd container for sending logs to Splunk" \
        name="logging-fluentd-splunk" \
        License="GPLv2+" \
        io.k8s.display-name="Fluentd Splunk" \
        version="v0.1" \
        architecture="x86_64" \
        release="0.1.0.0" \
        io.openshift.tags="logging,elk,fluentd,splunk"
