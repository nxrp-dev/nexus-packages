#!/usr/bin/env bash
# Copyright (c) 2026 Kevin Collins.
# SPDX-License-Identifier: MPL-2.0-no-copyleft-exception
set -euo pipefail
fixtures=${1:?Usage: Generate-NXOpenSSLFixtures.sh output-directory}
mkdir -p "$fixtures"
cat > "$fixtures/openssl.cnf" <<'EOF'
[req]
distinguished_name=dn
[dn]
EOF
cat > "$fixtures/ca.ext" <<'EOF'
basicConstraints=critical,CA:TRUE,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
EOF
openssl req -new -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -noenc -sha256 \
  -days 3650 -config "$fixtures/openssl.cnf" -subj '/CN=Nexus OpenSSL Test Root' \
  -addext 'basicConstraints=critical,CA:TRUE,pathlen:1' -addext 'keyUsage=critical,keyCertSign,cRLSign' \
  -keyout "$fixtures/root.key" -out "$fixtures/root.pem"
openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -noenc \
  -config "$fixtures/openssl.cnf" -subj '/CN=Nexus OpenSSL Test Intermediate' \
  -keyout "$fixtures/intermediate.key" -out "$fixtures/intermediate.csr"
openssl x509 -req -in "$fixtures/intermediate.csr" -CA "$fixtures/root.pem" \
  -CAkey "$fixtures/root.key" -set_serial 2 -sha256 -days 3650 \
  -extfile "$fixtures/ca.ext" -out "$fixtures/intermediate.pem"
serial=10
for hostname in first second third; do
  cat > "$fixtures/$hostname.ext" <<EOF
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
subjectAltName=DNS:$hostname.test,DNS:localhost,IP:127.0.0.1
EOF
  openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -noenc \
    -config "$fixtures/openssl.cnf" -subj "/CN=$hostname.test" \
    -keyout "$fixtures/$hostname.key" -out "$fixtures/$hostname.csr"
  openssl x509 -req -in "$fixtures/$hostname.csr" -CA "$fixtures/intermediate.pem" \
    -CAkey "$fixtures/intermediate.key" -set_serial "$serial" -sha256 -days 3650 \
    -extfile "$fixtures/$hostname.ext" -out "$fixtures/$hostname.pem"
  cat "$fixtures/$hostname.pem" "$fixtures/intermediate.pem" > "$fixtures/$hostname-chain.pem"
  openssl pkey -in "$fixtures/$hostname.key" -outform DER -out "$fixtures/$hostname.der"
  serial=$((serial + 1))
done
openssl pkcs12 -export -in "$fixtures/first.pem" -inkey "$fixtures/first.key" \
  -certfile "$fixtures/intermediate.pem" -passout pass:nexus-test -out "$fixtures/first.pfx"
