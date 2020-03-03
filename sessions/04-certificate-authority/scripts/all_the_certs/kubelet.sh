create_kubelet_certs() {
  for instance in worker-0 worker-1 worker-2; do
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

EXTERNAL_IP=$(GOOGLE_APPLICATION_CREDENTIALS=$KTH_GOOGLE_APPLICATION_CREDENTIALS \
  gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)' \
  --zone "${KTH_GCP_REGION}-b")

INTERNAL_IP=$(GOOGLE_APPLICATION_CREDENTIALS=$KTH_GOOGLE_APPLICATION_CREDENTIALS \
  gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].networkIP)' \
  --zone "${KTH_GCP_REGION}-b")

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
done
}