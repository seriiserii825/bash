#!/bin/sh

URL='http://www.accuweather.com/en/de/berlin/10178/weather-forecast/178087'

wget -q -O- "$URL" | awk -F\' '/acm_RecentLocationsCarousel\.push/{print $2": "$16", "$12"°" }'| head -1
