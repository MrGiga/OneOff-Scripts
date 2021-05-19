#!/bin/sh

if [ ! -f "servers.list" ]; then
  echo "No Server List Found .. Exiting"
  exit
fi

SERVERS=$(cat servers.list)
PORT=$(cat port.list)

for server in "$SERVERS"; do
  result=$(openssl s_client -servername $server -connect $server:$PORT </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p')
  echo "$result"
  if echo "$result" | grep -q "BEGIN CERTIFICATE"; then
    if echo "$result" | openssl verify | grep -q "OK"; then
       echo "Certificate Found"
    else
       echo "Certificate Not Found: Installing Certificate For $server"
       echo "$result" >> /etc/ssl/certs/ca-certificates.crt
    fi
  else
     echo "OpenSSL command failed for $server"
  fi
done
