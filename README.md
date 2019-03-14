# fluentd-secure-forwarder - Fluentd secure forwarder for Splunk HEC

The OpenShift template and supporting files in this directory create a
fluentd service that listens on port 24284 for secure forwarder
connections, and sends the received log messages to an external Splunk
HEC listener.

To deploy, run

```oc process -f ~/fluentd-secure-forwarder.yml -p NAMESPACE=YOUR_NAMESPACE | oc create -f-```

Edit the ConfigMap fluentd-secure-forwarder and the secret
fluentd-secure-forwarder to set the Splunk HEC connection parameters,
and the shared secret that secures the connection between the sending
and receiving Fluentd instances.

To encode the Splunk HEC token, run `echo -n TOKEN | base64`.

Depending on the OpenShift network plugin being used, additional
configuration is necessary to allow the openshift-logging fluentd
instances to connect to the fluentd-secure-forwarder instance. The
template has a NetworkPolicy object that allows openshift-logging pods
to connect. This requires the "name" label to be set on the
openshift-logging namespace:

```oc  label --overwrite namespace openshift-logging name=openshift-logging```

In the openshift-logging/logging-fluentd ConfigMap,
secure-forward.conf has to modified to send data to the
fluentd-secure-forwarder instance:

```
<store>
  @type secure_forward
  self_hostname pod-${HOSTNAME}
  shared_key CHANGEME

  secure yes
  enable_strict_verification yes
  ca_cert_path /etc/fluent/keys/service-signing-ca

  <server>
    host fluentd-secure-forwarder.YOUR_NAMESPACE.svc
  </server>
</store>
```

The service signing CA certificate that fluentd-secure-forwarder uses
(second certificate in tls.crt in secret secure-forwarder-cert) has to
be added as "service-signing-ca" in secret
openshift-logging/logging-fluentd.

To restart fluentd pods in the openshift-logging project and activate
configuration changes, run

```oc delete pod -n openshift-logging -l component=fluentd```
