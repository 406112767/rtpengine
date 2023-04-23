FROM debian:buster

RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak \
&& echo "deb http://mirrors.163.com/debian/ buster main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb http://mirrors.163.com/debian/ buster-updates main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb http://mirrors.163.com/debian/ buster-backports main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb-src http://mirrors.163.com/debian/ buster main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb-src http://mirrors.163.com/debian/ buster-updates main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb-src http://mirrors.163.com/debian/ buster-backports main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb http://mirrors.163.com/debian-security/ buster/updates main non-free contrib" >> /etc/apt/sources.list \
&& echo "deb-src http://mirrors.163.com/debian-security/ buster/updates main non-free contrib" >> /etc/apt/sources.list

RUN apt-get update \
  && apt-get -y --quiet --force-yes upgrade curl iproute2 \
  && apt-get install -y --no-install-recommends ca-certificates gcc g++ make build-essential git iptables-dev libavfilter-dev \
  libevent-dev libpcap-dev libxmlrpc-core-c3-dev markdown \
  libjson-glib-dev default-libmysqlclient-dev libhiredis-dev libssl-dev \
  libcurl4-openssl-dev libavcodec-extra gperf libspandsp-dev libwebsockets-dev libopus-dev

# RUN  mkdir /usr/local/share/ca-certificates/cacert.org \ 
#  && wget -P /usr/local/share/ca-certificates/cacert.org http://www.cacert.org/certs/root.crt http://www.cacert.org/certs/class3.crt \
#  && update-ca-certificates \

# RUN git config --global http.sslCAinfo /etc/ssl/certs/ca-certificates.crt
# RUN apt-get install -y --no-install-recommends libcurl4-gnutls-dev

COPY rtpengine /usr/local/src/rtpengine
COPY netdiscover.linux.amd64 /usr/bin/netdiscover

RUN cd /usr/local/src \
  # && git clone https://github.com/sipwise/rtpengine.git \
  && cd rtpengine/daemon \
  && make && make install \
  # 执行make debug时,会开启 ./lib/common.Makefile 下的DBG标志，开启更多日志日志
  # && make debug && make install \
  && cp /usr/local/src/rtpengine/daemon/rtpengine /usr/local/bin/rtpengine \
  # && curl -qL -o /usr/bin/netdiscover https://github.com/CyCoreSystems/netdiscover/releases/download/v1.2.5/netdiscover.linux.amd64 \
  && chmod +x /usr/bin/netdiscover \  
  && rm -Rf /usr/local/src/rtpengine \
  && apt-get purge -y --quiet --force-yes --auto-remove \
  ca-certificates gcc g++ make build-essential git markdown \
  && rm -rf /var/lib/apt/* \
  && rm -rf /var/lib/dpkg/* \
  && rm -rf /var/lib/cache/* \
  && rm -Rf /var/log/* \
  && rm -Rf /usr/local/src/* \
  && rm -Rf /var/lib/apt/lists/* 

VOLUME ["/tmp"]
COPY ./entrypoint.sh /entrypoint.sh
COPY ./rtpengine.conf /etc
ENTRYPOINT ["/entrypoint.sh"]
CMD ["rtpengine"]

HEALTHCHECK CMD curl --fail http://localhost:8080/ping || exit 1
