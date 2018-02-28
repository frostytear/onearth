#!/bin/sh

if [ ! -f /.dockerenv ]; then
  echo "This script is only intended to be run from within Docker" >&2
  exit 1
fi

# Change default dir to /build/test/mod_mrf_test_data
cp httpd.conf /etc/httpd/conf/

# Copy date_service config
cp date_service/oe2_test_date_service.conf /etc/httpd/conf.d
mkdir -p /build/test/mod_mrf_test_data/date_service
cp date_service/date_service.lua /build/test/mod_mrf_test_data/date_service

# Copy config stuff
mkdir -p /build/test/mod_mrf_test_data/mrf_endpoint/test_daily_png/default/EPSG4326_16km
cp -r ../src/test/mod_mrf_test_data/test_imagery /build/test/mod_mrf_test_data/
cp ../src/test/mod_mrf_test_data/mrf_test.conf /etc/httpd/conf.d
cp layer_configs/test_mod_mrf_daily_png*.config /build/test/mod_mrf_test_data/mrf_endpoint/test_daily_png/default/EPSG4326_16km/
mkdir -p /build/test/mod_mrf_test_data/mrf_endpoint/test_legacy_subdaily_jpg/default/EPSG4326_16km
cp layer_configs/test_mod_mrf_legacy_subdaily_jpg*.config /build/test/mod_mrf_test_data/mrf_endpoint/test_legacy_subdaily_jpg/default/EPSG4326_16km/
mkdir -p /build/test/mod_mrf_test_data/mrf_endpoint/test_nonyear_jpg/default/EPSG4326_16km
cp layer_configs/test_mod_mrf_nonyear_jpg*.config /build/test/mod_mrf_test_data/mrf_endpoint/test_nonyear_jpg/default/EPSG4326_16km/
mkdir -p /build/test/mod_mrf_test_data/mrf_endpoint/test_static_jpg/default/EPSG4326_16km
cp layer_configs/test_mod_mrf_static_jpg*.config /build/test/mod_mrf_test_data/mrf_endpoint/test_static_jpg/default/EPSG4326_16km/
mkdir -p /build/test/mod_mrf_test_data/mrf_endpoint/test_weekly_jpg/default/EPSG4326_16km
cp layer_configs/test_mod_mrf_weekly_jpg*.config /build/test/mod_mrf_test_data/mrf_endpoint/test_weekly_jpg/default/EPSG4326_16km/

# GIBS sample configs


echo 'Starting Apache server'
/usr/sbin/apachectl
sleep 2

echo 'Starting Redis server'
/usr/bin/redis-server &
sleep 2

# Add some test data to redis for profiling
/usr/bin/redis-cli  -n 0 DEL layer:test_daily_png
/usr/bin/redis-cli  -n 0 SET layer:test_daily_png:default "2012-02-29"
/usr/bin/redis-cli  -n 0 SADD layer:test_daily_png:periods "2012-02-29/2012-02-29/P1D"
/usr/bin/redis-cli  -n 0 DEL layer:test_legacy_subdaily_jpg
/usr/bin/redis-cli  -n 0 SET layer:test_legacy_subdaily_jpg:default "2012-02-29T12:00:00Z"
/usr/bin/redis-cli  -n 0 SADD layer:test_legacy_subdaily_jpg:periods "2012-02-29T12:00:00Z/2012-02-29T14:00:00Z/PT2H"
/usr/bin/redis-cli  -n 0 DEL layer:test_nonyear_jpg
/usr/bin/redis-cli  -n 0 SET layer:test_nonyear_jpg:default "2012-02-29"
/usr/bin/redis-cli  -n 0 SADD layer:test_nonyear_jpg:periods "2012-02-29/2012-02-29/P1D"
/usr/bin/redis-cli  -n 0 DEL layer:test_weekly_jpg
/usr/bin/redis-cli  -n 0 SET layer:test_weekly_jpg:default "2012-02-29"
/usr/bin/redis-cli  -n 0 SADD layer:test_weekly_jpg:periods "2012-02-22/2012-02-29/P7D"
/usr/bin/redis-cli  -n 0 SAVE

# Tail the apache logs
exec tail -qF \
  /etc/httpd/logs/access.log \
  /etc/httpd/logs/error.log \
  /etc/httpd/logs/access_log \
  /etc/httpd/logs/error_log
