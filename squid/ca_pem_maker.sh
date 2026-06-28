openssl genrsa -out squidCA.key 4096

openssl req -new -x509 -days 3650 -key squidCA.key -out squidCA.crt

cat squidCA.key squidCA.crt > ca.pem

chmod 400 ca.pem
chown proxy:proxy ca.pem
