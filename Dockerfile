# Based on
# https://github.com/openshift/origin-aggregated-logging/blob/release-3.11/fluentd/Dockerfile

FROM registry.access.redhat.com/rhscl/ruby-25-rhel7

ENV LOGGING_FILE_PATH=/var/log/fluentd/fluentd.log \
    LOGGING_FILE_AGE=10 \
    LOGGING_FILE_SIZE=1024000 \
    container=oci

RUN scl enable rh-ruby25 'gem install fluent-plugin-splunk-enterprise fluent-plugin-secure-forward'

ADD configs.d/ /etc/fluent/configs.d/
ADD fluent.conf /etc/fluent/
ADD run.sh ${HOME}/

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
