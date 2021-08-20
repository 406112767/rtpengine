#!/bin/bash
set -e

PATH=/usr/local/bin:$PATH

case $CLOUD in 
  gcp)
    LOCAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
    PUBLIC_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    ;;
  aws)
    LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    ;;
  digitalocean)
    LOCAL_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
    PUBLIC_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
    ;;
  azure)
    LOCAL_IP=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text")
    PUBLIC_IP=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2017-08-01&format=text")
    ;;
  *)
    LOCAL_IP=`netdiscover -field privatev4`
    ;;
esac

[ -z "$BIND_NG_IP" ] && { export BIND_NG_IP='0.0.0.0'; }
[ -z "$BIND_NG_PORT" ] && { export BIND_NG_PORT=22222; }
[ -z "$BIND_HTTP_IP" ] && { export BIND_HTTP_IP='0.0.0.0'; }
[ -z "$BIND_HTTP_PORT" ] && { export BIND_HTTP_PORT=8080; }
[ -z "$PORT_MIN" ] && { export PORT_MIN=23000; }
[ -z "$PORT_MAX" ] && { export PORT_MAX=32768; }
[ -z "$LOG_LEVEL" ] && { export LOG_LEVEL=0; }

if [ -n "$PUBLIC_IP" ]; then
  MY_IP="127.0.0.1"!"$PUBLIC_IP"
else
  MY_IP=$LOCAL_IP
fi

sed -i -e "s/MY_IP/$MY_IP/g" /etc/rtpengine.conf
sed -i -e "s/BIND_NG_IP/$BIND_NG_IP/g" /etc/rtpengine.conf
sed -i -e "s/BIND_NG_PORT/$BIND_NG_PORT/g" /etc/rtpengine.conf
sed -i -e "s/BIND_HTTP_IP/$BIND_HTTP_IP/g" /etc/rtpengine.conf
sed -i -e "s/BIND_HTTP_PORT/$BIND_HTTP_PORT/g" /etc/rtpengine.conf
sed -i -e "s/PORT_MIN/$PORT_MIN/g" /etc/rtpengine.conf
sed -i -e "s/PORT_MAX/$PORT_MAX/g" /etc/rtpengine.conf
sed -i -e "s/LOG_LEVEL/$LOG_LEVEL/g" /etc/rtpengine.conf

if [ "$1" = 'rtpengine' ]; then
  shift
  exec rtpengine --config-file /etc/rtpengine.conf  "$@"
fi

exec "$@"
