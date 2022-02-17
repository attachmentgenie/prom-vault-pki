# prometheus vault exporters

Things like Infrastructure as Code, Service Discovery and Config Management can and have helped us to quickly build and rebuild infrastructure but we haven't nearly spend enough time to train our self to review, monitor and respond to outages. Does our platform degrade in a graceful way or what does a high cpu load really mean? What can we learn from level 1 outages to be able to run our platforms more reliably.

This talk will focus on on creating a secure prometheus exporter ecosystem using HashiCorp Vault where we can we be sure that we are not leaking any business metrics from our observability stack. After which we ll investigate how to automatically rotate the certificates we created to do so.

# TLDR

    node_exporter =>
        insecure => http://insecure.pki.vagrant:9100/metrics
        tls => https://tls.pki.vagrant:9100/metrics
    prometheus    => http://prometheus.pki.vagrant:9090/  
    vault         => http://prometheus.pki.vagrant:8200/