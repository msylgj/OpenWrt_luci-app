#!/bin/sh

sleeptime=60

dnsconf="/var/run/dnscache/dnscache.conf"
dnsprogram="/var/sbin/dnscache"
extradnsconf="/var/run/dnscache/extradns.conf"
extradnsprogram="/var/sbin/extradns"
logfile="/var/log/dnscache.file"

dns_caching="$(uci -q get turboacc.config.dns_caching)"
dns_caching_mode="$(uci -q get turboacc.config.dns_caching_mode)"
extra_dns="$(uci -q get turboacc.config.extra_dns)"
extra_dns_nov6="$(uci -q get turboacc.config.extra_dns_nov6)"

clean_log() {
	logrow="$(grep -c "" "${logfile}")"
	[ "${logrow}" -lt "500" ] || echo "${curtime} Log 条数超限，清空处理！" > "${logfile}"
}

while [ "${dns_caching}" -eq "1" ];
do
	curtime="$(date "+%H:%M:%S")"

	clean_log

	if pidof dnscache > "/dev/null"; then
		echo -e "${curtime} online!" >> "${logfile}"
	else
		if [ "${dns_caching_mode}" = "1" ]; then
			${dnsprogram} -c "${dnsconf}" > "${logfile}" 2>&1 &
		elif [ "${dns_caching_mode}" = "2" ]; then
			${dnsprogram} -f "${dnsconf}" > "${logfile}" 2>&1 &
		elif [ "${dns_caching_mode}" = "3" ]; then
			${dnsprogram} -o "${logfile}" -l "127.0.0.1" -p "5333" -b "tls://9.9.9.9" -f "tls://8.8.8.8" -u "${dnsconf}" --all-servers --cache --cache-min-ttl=3600 > "${logfile}" 2>&1 &
			if [ "${extra_dns}" = "1" ]; then
				ipv6flag = "--ipv6-disabled"
				if [ "${extra_dns_nov6}" = "0" ]; then
					ipv6flag = ""
				fi
				${extradnsprogram} -o "${logfile}" -l "127.0.0.1" -p "5335" -b "tls://9.9.9.9" -f "tls://8.8.8.8" -u "${extradnsconf}" --all-servers --cache --cache-min-ttl=3600 ${ipv6flag} > "${logfile}" 2>&1 &
			fi
		fi
		echo "${curtime} 重启服务！" >> ${logfile}
	fi

	sleep "${sleeptime}"
	continue
done
