# GCP-OCI-Prod-Admin-Setup
Terraform templates to setup up projects, networks, etc for Next Gen OCI Signing and CI

## Fulcio and Rekor

Fulcio URL: http://35.224.78.102

Rekor URL: http://34.134.220.168


**Signing with Cosign**


Each piece generates keys and certificates that are needed for signing and verifying.

Cosign: Requires the fulcio root cert, the ct log public key, and the rekor public key

Rekor: Rekor key pair is in [GCP oci-signer-service-dev KMS](https://console.cloud.google.com/security/kms/keyring/manage/global/rekor-keyring/key?project=oci-signer-service-dev)

Chains: Requires fulcio and rekor URL endpoint

CTLog: CT Log public and private keys are in [GCP secrets manager](https://console.cloud.google.com/security/secret-manager/secret/ctlog-public-key/versions?project=oci-signer-service-dev)

Fulcio Cert: Available in Fulcio endpoint $FULCIO_ENDPOINT/api/v1/rootCert or in the [GCP Secrets Manager](https://console.cloud.google.com/security/secret-manager/secret/fulcio-root-ca/versions?project=oci-signer-service-dev)


We need to do some initial set up, and store the CT Log public key, Rekor public key and Fulcio Root CA on disk as files:

```
cat <<EOF > fulcio.crt.pem
-----BEGIN CERTIFICATE-----
MIIB9TCCAXygAwIBAgIUAPZMASHe36cox0zX6kJA9c/j6vUwCgYIKoZIzj0EAwMw
KjEVMBMGA1UEChMMc2lnc3RvcmUuZGV2MREwDwYDVQQDEwhzaWdzdG9yZTAeFw0y
MjA0MTkxOTA3NTZaFw0zMjA0MTYxOTA3NTVaMCoxFTATBgNVBAoTDHNpZ3N0b3Jl
LmRldjERMA8GA1UEAxMIc2lnc3RvcmUwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAAR+
LkzqeXhe0LDKGM4N40Dj5x/qDsPPJ1sHd4TUgzQnAh0SPiHZimYZwg+oDiV1iVAV
ySoTgnc+M3LQ3DvF7ZaP8zoGWXe/TxIs1SFNn7sjelMSbAhhAbr94/rd8FV8bJGj
YzBhMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTO
gi85M7PvyKumMWIMAuSTuSZGZDAfBgNVHSMEGDAWgBTOgi85M7PvyKumMWIMAuST
uSZGZDAKBggqhkjOPQQDAwNnADBkAjBrYlhsh55Cw2Yfyp+0dn1SyUwvv+k7uSsK
dAj0UjMYKa2/0awiHkB5fhs+qhyyQfgCMFSVP5GqFct7Tu4vJ6GeCBHqEG/b0wBB
0jIAd8OCHWlNZhhXWs8wbpHHd4W9NThIdw==
-----END CERTIFICATE-----
EOF
```

```
cat <<EOF > ctlog.pub
-----BEGIN RSA PUBLIC KEY-----
MIICCgKCAgEApPMWGQvinGvBnbnCpQYxasxzqVWzJp3G3RE12wy/GSvZB6fzIL6Y
sdLvITvsIuMT0QMsSsNvmgXUsR+dOhOJPOKwsM+d/FOkeLfHRqqo/gOrc0Kv6iBN
5LDFalBwA9Chy3Wv7bETLpDEkFh/sPqCJxLkC8YRJCcMwgr4hXp6K5HrcD3lQ3NB
hJGzUcqvEfZPbLpX2Op0bYwF9qDjotQKsG0QzeVtOGEU0OCRpyKE7VdNCta42NkV
lCW688klcAJdb2zHGcfjw0xH37zTSCpaxAGkRpiXY5eo9nlEZxdaqE4pVC7MSPpL
5PSMkP83ZsyFdR4EuViSOKNcngD11+ypAoFZB7y9dZW0j4NbHvGfvfFFBYWl0Zc6
TC9r/CZGWJaWnBpG+hBIYlbi+IW/iBNB+xYTJHq3jbTCuGMQY1evhq0jmeokVMbC
dsGAQMYlXB5nvsb//gDerpMGsdgf2FmQjg+zW7OjoNE8mfTghe/GeT+Bd1BK5lUG
SvRaQ2YRGxHwdKjkldxg5D8bdgmksIr1j6TIYmhF2ID3WWu01/UBLTOxCR6I9nvR
Wvzp6CY2CrrIj6mvgg3aFqzHgCbhegoBQ/BGfGBEQJ5la8VGeSjamSU56wf+u/N1
5aUdk3V1zdsOyayUlSeYXIWTjmsNs3/puqX055eEQfAD3bZIu9vzmTcCAwEAAQ==
-----END RSA PUBLIC KEY-----
EOF
```

```
cat <<EOF > rekor.pub
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEeaitqbd1eWtvyMOKt5ai+GyCLtJj
zEOokp7xwTGgbdnLrUOcArYtnrS5iTnjVHiP/QzN1ztgCrA28+dbyKf2RQ==
-----END PUBLIC KEY-----
EOF
```

Now, sign an image with cosign:

```
export COSIGN_EXPERIMENTAL=1
export SIGSTORE_CT_LOG_PUBLIC_KEY_FILE=$(pwd)/ctlog.pub
export FULCIO_URL=http://35.224.78.102
export REKOR_URL=http://34.134.220.168

export IMAGE= [ your image]

cosign sign --fulcio-url $FULCIO_URL --rekor-url $REKOR_URL $IMAGE
```

**Verifying with Cosign**

```
export COSIGN_EXPERIMENTAL=1
export SIGSTORE_ROOT_FILE=$(pwd)/fulcio.crt.pem
export SIGSTORE_REKOR_PUBLIC_KEY=$(pwd)/rekor.pub 

cosign verify --rekor-url $REKOR_URL $IMAGE
```
