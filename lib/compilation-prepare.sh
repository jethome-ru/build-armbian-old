#!/bin/bash
#
# Copyright (c) 2015 Igor Pecovnik, igor.pecovnik@gma**.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

# This file is a part of the Armbian build script
# https://github.com/armbian/build/

# Functions:
# compilation_prepare

compilation_prepare()
{

	# Packaging patch for modern kernels should be one for all. 
	# Currently we have it per kernel family since we can't have one
	# Maintaining one from central location starting with 5.3+
	# Temporally set for new "default->legacy,next->current" family naming

	if linux-version compare "${version}" ge 5.6; then
		display_alert "Adjusting" "packaging" "info"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		process_patch_file "${SRC}/patch/misc/general-packaging-5.6.y.patch" "applying"
	else
		if linux-version compare "${version}" ge 5.3; then
			display_alert "Adjusting" "packaging" "info"
			cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
			process_patch_file "${SRC}/patch/misc/general-packaging-5.3.y.patch" "applying"
		fi
	fi

	if [[ "${version}" == "4.19."* ]] && [[ "$LINUXFAMILY" == sunxi* || "$LINUXFAMILY" == meson64 || \
	"$LINUXFAMILY" == mvebu64 || "$LINUXFAMILY" == mt7623 || "$LINUXFAMILY" == mvebu ]]; then
		display_alert "Adjustin" "packaging" "info"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		process_patch_file "${SRC}/patch/misc/general-packaging-4.19.y.patch" "applying"
	fi

	if [[ "${version}" == "4.14."* ]] && [[ "$LINUXFAMILY" == s5p6818 || "$LINUXFAMILY" == mvebu64 || \
	"$LINUXFAMILY" == imx7d || "$LINUXFAMILY" == odroidxu4 || "$LINUXFAMILY" == mvebu ]]; then
		display_alert "Adjustin" "packaging" "info"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		process_patch_file "${SRC}/patch/misc/general-packaging-4.14.y.patch" "applying"
	fi

	if [[ "${version}" == "4.4."* || "${version}" == "4.9."* ]] && \
	[[ "$LINUXFAMILY" == rockpis || "$LINUXFAMILY" == rk3399 ]]; then
		display_alert "Adjustin" "packaging" "info"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		process_patch_file "${SRC}/patch/misc/general-packaging-4.4.y-rk3399.patch" "applying"
	fi

	if [[ "${version}" == "4.4."* ]] && [[ "$LINUXFAMILY" == rockchip64 ]]; then
		display_alert "Adjustin" "packaging" "info"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		process_patch_file "${SRC}/patch/misc/general-packaging-4.4.y-rockchip64.patch" "applying"
	fi

	if [[ "${version}" == "4.4."* ]] && [[ "$LINUXFAMILY" == rockchip || "$LINUXFAMILY" == rk322x ]]; then
                display_alert "Adjustin" "packaging" "info"
                cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
                process_patch_file "${SRC}/patch/misc/general-packaging-4.4.y.patch" "applying"
        fi

	if [[ "${version}" == "4.9."* ]] && [[ "$LINUXFAMILY" == meson64 || "$LINUXFAMILY" == odroidc4 ]]; then
		display_alert "Adjustin" "packaging" "info"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		process_patch_file "${SRC}/patch/misc/general-packaging-4.9.y.patch" "applying"
	fi

	#
	# Linux splah file
	#

	if linux-version compare "${version}" le 5.8; then

		display_alert "Adding" "Kernel splash file" "info"
		process_patch_file "${SRC}/patch/misc/0001-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0002-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0003-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0004-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0005-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0006-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0007-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0008-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0009-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0010-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0011-bootsplash.patch" "applying"
		process_patch_file "${SRC}/patch/misc/0012-bootsplash.patch" "applying"

	fi

	#
	# mac80211 wireless driver injection features from Kali Linux
	#

	if linux-version compare "${version}" ge 5.4 && [ $EXTRAWIFI == yes ]; then

		display_alert "Adding" "Wireless package injections for mac80211 compatible chipsets" "info"
		process_patch_file "${SRC}/patch/misc/kali-wifi-injection-1.patch" "applying"
		process_patch_file "${SRC}/patch/misc/kali-wifi-injection-2.patch" "applying"

	fi

	# AUFS - advanced multi layered unification filesystem for Kernel > 5.1
	#
	# Older versions have AUFS support with a patch

	if linux-version compare "${version}" ge 5.1 && linux-version compare "${version}" le 5.8 && [ "$AUFS" == yes ]; then

		# attach to specifics tag or branch
		local aufstag
		aufstag=$(echo "${version}" | cut -f 1-2 -d ".")

		# manual overrides
		if linux-version compare "${version}" ge 5.4.3 && linux-version compare "${version}" le 5.5 ; then aufstag="5.4.3"; fi

		# check if Mr. Okajima already made a branch for this version
		git ls-remote --exit-code --heads https://github.com/sfjro/aufs5-standalone "aufs${aufstag}" >/dev/null

		if [ "$?" -ne "0" ]; then
			# then use rc branch
			aufstag="5.x-rcN"
			git ls-remote --exit-code --heads https://github.com/sfjro/aufs5-standalone "aufs${aufstag}" >/dev/null
		fi

		if [ "$?" -eq "0" ]; then

			display_alert "Adding" "AUFS ${aufstag}" "info"
			local aufsver="branch:aufs${aufstag}"
			fetch_from_repo "https://github.com/sfjro/aufs5-standalone" "aufs5" "branch:${aufsver}" "yes"
			cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
			process_patch_file "${SRC}/cache/sources/aufs5/${aufsver#*:}/aufs5-kbuild.patch" "applying"
			process_patch_file "${SRC}/cache/sources/aufs5/${aufsver#*:}/aufs5-base.patch" "applying"
			process_patch_file "${SRC}/cache/sources/aufs5/${aufsver#*:}/aufs5-mmap.patch" "applying"
			process_patch_file "${SRC}/cache/sources/aufs5/${aufsver#*:}/aufs5-standalone.patch" "applying"
			cp -R "${SRC}/cache/sources/aufs5/${aufsver#*:}"/{Documentation,fs} .
			cp "${SRC}/cache/sources/aufs5/${aufsver#*:}"/include/uapi/linux/aufs_type.h include/uapi/linux/

		fi
	fi




	# WireGuard VPN for Linux 3.10 - 5.5
	if linux-version compare "${version}" ge 3.10 && linux-version compare "${version}" le 5.5 && [ "${WIREGUARD}" == yes ]; then

		# attach to specifics tag or branch
		local wirever="branch:master"

		display_alert "Adding" "WireGuard VPN for Linux 3.10 - 5.5 ${wirever} " "info"
		fetch_from_repo "https://git.zx2c4.com/wireguard-linux-compat" "wireguard" "${wirever}" "yes"

		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/net/wireguard"
		cp -R "${SRC}/cache/sources/wireguard/${wirever#*:}/src/" "${SRC}/cache/sources/${LINUXSOURCEDIR}/net/wireguard"
		sed -i "/^obj-\\\$(CONFIG_NETFILTER).*+=/a obj-\$(CONFIG_WIREGUARD) += wireguard/" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/net/Makefile"
		sed -i "/^if INET\$/a source \"net/wireguard/Kconfig\"" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/net/Kconfig"
		# remove duplicates
		[[ $(grep -c wireguard "${SRC}/cache/sources/${LINUXSOURCEDIR}/net/Makefile") -gt 1 ]] && \
		sed -i '0,/wireguard/{/wireguard/d;}' "${SRC}/cache/sources/${LINUXSOURCEDIR}/net/Makefile"
		[[ $(grep -c wireguard "${SRC}/cache/sources/${LINUXSOURCEDIR}/net/Kconfig") -gt 1 ]] && \
		sed -i '0,/wireguard/{/wireguard/d;}' "${SRC}/cache/sources/${LINUXSOURCEDIR}/net/Kconfig"
		# headers workaround
		display_alert "Patching WireGuard" "Applying workaround for headers compilation" "info"
		sed -i '/mkdir -p "$destdir"/a mkdir -p "$destdir"/net/wireguard; \
		touch "$destdir"/net/wireguard/{Kconfig,Makefile} # workaround for Wireguard' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/scripts/package/builddeb"

	fi


	# Updated USB network drivers for RTL8152/RTL8153 based dongles that also support 2.5Gbs variants

	if linux-version compare "${version}" ge 5.4 && [ $LINUXFAMILY != mvebu64 ] && [ $LINUXFAMILY != rk322x ] && [ $LINUXFAMILY != odroidxu4 ] && [ $EXTRAWIFI == yes ]; then

		# attach to specifics tag or branch
		local rtl8152ver="branch:master"

		display_alert "Adding" "Drivers for 2.5Gb RTL8152/RTL8153 USB dongles ${rtl8152ver}" "info"
		fetch_from_repo "https://github.com/igorpecovnik/realtek-r8152-linux" "rtl8152" "${rtl8152ver}" "yes"
		cp -R "${SRC}/cache/sources/rtl8152/${rtl8152ver#*:}"/{r8152.c,compatibility.h} \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/usb/"

	fi




	# JetHome DTS files
	display_alert "Adding" "JetHome DTS files" "info"
	local jethome_j80_line='dtb-$(CONFIG_ARCH_MESON) += jethome-j80-v1.dtb'
	local jethome_j100_line='dtb-$(CONFIG_ARCH_MESON) += jethome-j100-v1.dtb'
	local boot_dts_makefile="${SRC}/cache/sources/${LINUXSOURCEDIR}/arch/arm64/boot/dts/amlogic/Makefile"
	cp -fv "${SRC}/jethome/patch/kernel/arm-64-current"/jethome-j{80,100}-v1.dts \
	"${SRC}/cache/sources/${LINUXSOURCEDIR}/arch/arm64/boot/dts/amlogic/"
	if ! grep "$jethome_j80_line" $boot_dts_makefile; then
		echo $jethome_j80_line >> $boot_dts_makefile
	fi
	if ! grep "$jethome_j100_line" $boot_dts_makefile; then
		echo $jethome_j100_line >> $boot_dts_makefile
	fi




	# Wireless drivers for Realtek 88x2CS chipsets

	if linux-version compare "${version}" ge 3.14 && [ "$EXTRAWIFI" == yes ]; then

		# attach to specifics tag or branch
		local rtl8822cver="branch:v5.9.0.2"
		local rtl8822c_gz="rtl88x2CS_WiFi_linux_v5.9.0.2_36407.20200302_COEX20200103-1717.tar.gz"
		local rtl8822c_dir="${SRC}/cache/sources/rtl8822c/${rtl8822cver#*:}"

		display_alert "Adding" "Wireless drivers for 88x2CS chipsets" "info"

		rm -rf "${SRC}/cache/sources/rtl8822c"
		mkdir -p "${SRC}/cache/sources/rtl8822c"
		tar -xf "${SRC}/jethome/overlay/drivers/rtl88x2CS/$rtl8822c_gz" -C "${SRC}/cache/sources"
		mv "${SRC}/cache/sources/${rtl8822c_gz%.tar.gz}" "$rtl8822c_dir"

		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8822c"
		mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8822c/"
		cp -R "$rtl8822c_dir"/{core,hal,include,os_dep,platform,halmac.mk,ifcfg-wlan0,rtl8822c.mk,runwpa,wlan0dhcp} \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8822c"

		# Makefile
		cp "$rtl8822c_dir/Makefile" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8822c/Makefile"
		cp "$rtl8822c_dir/Kconfig" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8822c/Kconfig"

		# Add to section Makefile
		echo "obj-\$(CONFIG_RTL8822CS) += rtl8822c/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8822c\/Kconfig"' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

		process_patch_file "${SRC}/patch/misc/wireless-rtl8822c-0001-include-types-h-from-uapi.patch"                "applying"
		process_patch_file "${SRC}/patch/misc/wireless-rtl8822c-0002-replace-file_operations-with-proc_ops.patch"    "applying"
		process_patch_file "${SRC}/patch/misc/wireless-rtl8822c-0003_kconfig_change_RTL8822BS_to_RTL8822CS.patch"     "applying"
		process_patch_file "${SRC}/patch/misc/wireless-rtl8822c-0001-Disable-powersaving.patch"     "applying"

	fi




	# Wireless drivers for Realtek 8189ES chipsets

	if linux-version compare "${version}" ge 3.14 && [ "$EXTRAWIFI" == yes ]; then

		# attach to specifics tag or branch
		local rtl8189esver="branch:master"

		display_alert "Adding" "Wireless drivers for Realtek 8189ES chipsets ${rtl8189esver}" "info"

		fetch_from_repo "https://github.com/jwrdegoede/rtl8189ES_linux" "rtl8189es" "${rtl8189esver}" "yes"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8189es"
		mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8189es/"
		cp -R "${SRC}/cache/sources/rtl8189es/${rtl8189esver#*:}"/{core,hal,include,os_dep,platform} \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8189es"

		# Makefile
		cp "${SRC}/cache/sources/rtl8189es/${rtl8189esver#*:}/Makefile" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8189es/Makefile"
		cp "${SRC}/cache/sources/rtl8189es/${rtl8189esver#*:}/Kconfig" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8189es/Kconfig"

		# Add to section Makefile
		echo "obj-\$(CONFIG_RTL8189ES) += rtl8189es/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8189es\/Kconfig"' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

	fi




	# Wireless drivers for Realtek 8189FS chipsets

	if linux-version compare "${version}" ge 3.14 && [ "$EXTRAWIFI" == yes ]; then

		# attach to specifics tag or branch
		local rtl8189fsver="branch:rtl8189fs"

		display_alert "Adding" "Wireless drivers for Realtek 8189FS chipsets ${rtl8189fsver}" "info"

		fetch_from_repo "https://github.com/jwrdegoede/rtl8189ES_linux" "rtl8189fs" "${rtl8189fsver}" "yes"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8189fs"
		mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8189fs/"
		cp -R "${SRC}/cache/sources/rtl8189fs/${rtl8189fsver#*:}"/{core,hal,include,os_dep,platform} \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8189fs"

		# Makefile
		cp "${SRC}/cache/sources/rtl8189fs/${rtl8189fsver#*:}/Makefile" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8189fs/Makefile"
		cp "${SRC}/cache/sources/rtl8189fs/${rtl8189fsver#*:}/Kconfig" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8189fs/Kconfig"

		# Add to section Makefile
		echo "obj-\$(CONFIG_RTL8189FS) += rtl8189fs/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8189fs\/Kconfig"' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

	fi




	# Wireless drivers for Realtek 8811, 8812, 8814 and 8821 chipsets

	# if linux-version compare "${version}" ge 3.14 && [ "$EXTRAWIFI" == yes ]; then

	# 	# attach to specifics tag or branch
	# 	local rtl8812auver="branch:v5.6.4.2"

	# 	display_alert "Adding" "Wireless drivers for Realtek 8811, 8812, 8814 and 8821 chipsets ${rtl8812auver}" "info"

	# 	fetch_from_repo "https://github.com/aircrack-ng/rtl8812au" "rtl8812au" "${rtl8812auver}" "yes"
	# 	cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
	# 	rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8812au"
	# 	mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8812au/"
	# 	cp -R "${SRC}/cache/sources/rtl8812au/${rtl8812auver#*:}"/{core,hal,include,os_dep,platform} \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8812au"

	# 	# Makefile
	# 	cp "${SRC}/cache/sources/rtl8812au/${rtl8812auver#*:}/Makefile" \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8812au/Makefile"
	# 	cp "${SRC}/cache/sources/rtl8812au/${rtl8812auver#*:}/Kconfig" \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8812au/Kconfig"

	# 	# Add to section Makefile
	# 	echo "obj-\$(CONFIG_88XXAU) += rtl8812au/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
	# 	sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8812au\/Kconfig"' \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

	# fi




	# Wireless drivers for Xradio XR819 chipsets
	if linux-version compare "${version}" ge 4.19 && [[ "$EXTRAWIFI" == yes ]]; then

		display_alert "Adding" "Wireless drivers for Xradio XR819 chipsets" "info"

		fetch_from_repo "https://github.com/karabek/xradio" "xradio" "branch:master" "yes"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/xradio"
		mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/xradio/"
		cp "${SRC}"/cache/sources/xradio/master/*.{h,c} \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/xradio/"

		# Makefile
		cp "${SRC}/cache/sources/xradio/master/Makefile" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/xradio/Makefile"
		cp "${SRC}/cache/sources/xradio/master/Kconfig" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/xradio/Kconfig"

		# Add to section Makefile
		echo "obj-\$(CONFIG_WLAN_VENDOR_XRADIO) += xradio/" \
		>> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/xradio\/Kconfig"' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

	fi




	# Wireless drivers for Realtek RTL8811CU and RTL8821C chipsets

	if linux-version compare "${version}" ge 3.14 && [ "$EXTRAWIFI" == yes ]; then

		# attach to specifics tag or branch
		local rtl8811cuver="commit:2bebdb9a35c1d9b6e6a928e371fa39d5fcec8a62"

		display_alert "Adding" "Wireless drivers for Realtek RTL8811CU and RTL8821C chipsets ${rtl8811cuver}" "info"

		fetch_from_repo "https://github.com/brektrou/rtl8821CU" "rtl8811cu" "${rtl8811cuver}" "yes"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8811cu"
		mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8811cu/"
		cp -R "${SRC}/cache/sources/rtl8811cu/${rtl8811cuver#*:}"/{core,hal,include,os_dep,platform,rtl8821c.mk} \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8811cu"

		# Makefile
		cp "${SRC}/cache/sources/rtl8811cu/${rtl8811cuver#*:}/Makefile" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8811cu/Makefile"
		cp "${SRC}/cache/sources/rtl8811cu/${rtl8811cuver#*:}/Kconfig" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8811cu/Kconfig"

		# Disable debug
		sed -i "s/^CONFIG_RTW_DEBUG.*/CONFIG_RTW_DEBUG = n/" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8811cu/Makefile"

		# Address ARM related bug https://github.com/aircrack-ng/rtl8812au/issues/233
		sed -i "s/^CONFIG_MP_VHT_HW_TX_MODE.*/CONFIG_MP_VHT_HW_TX_MODE = n/" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8811cu/Makefile"

		# Add to section Makefile
		echo "obj-\$(CONFIG_RTL8821CU) += rtl8811cu/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8811cu\/Kconfig"' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

	fi




	# Wireless drivers for Realtek 8188EU 8188EUS and 8188ETV chipsets

	# if linux-version compare "${version}" ge 3.14 && [ "$EXTRAWIFI" == yes ]; then

	# 	# attach to specifics tag or branch
	# 	local rtl8188euver="branch:v5.7.6.1"

	# 	display_alert "Adding" "Wireless drivers for Realtek 8188EU 8188EUS and 8188ETV chipsets ${rtl8188euver}" "info"

	# 	fetch_from_repo "https://github.com/aircrack-ng/rtl8188eus" "rtl8188eu" "${rtl8188euver}" "yes"
	# 	cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
	# 	rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8188eu"
	# 	mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8188eu/"
	# 	cp -R "${SRC}/cache/sources/rtl8188eu/${rtl8188euver#*:}"/{core,hal,include,os_dep,platform} \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8188eu"

	# 	# Makefile
	# 	cp "${SRC}/cache/sources/rtl8188eu/${rtl8188euver#*:}/Makefile" \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8188eu/Makefile"
	# 	cp "${SRC}/cache/sources/rtl8188eu/${rtl8188euver#*:}/Kconfig" \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8188eu/Kconfig"

	# 	# Disable debug
	# 	sed -i "s/^CONFIG_RTW_DEBUG.*/CONFIG_RTW_DEBUG = n/" \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8188eu/Makefile"

	# 	# Add to section Makefile
	# 	echo "obj-\$(CONFIG_RTL8188EU) += rtl8188eu/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
	# 	sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8188eu\/Kconfig"' \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

	# 	# kernel 5.6 ->
	# 	process_patch_file "${SRC}/patch/misc/wireless-rtl8188eu.patch" "applying"

	# fi




	# Wireless drivers for Realtek 88x2bu chipsets

	if linux-version compare "${version}" ge 3.14 && [ "$EXTRAWIFI" == yes ]; then

		# attach to specifics tag or branch
		local rtl88x2buver="branch:5.6.1_30362.20181109_COEX20180928-6a6a"

		display_alert "Adding" "Wireless drivers for Realtek 88x2bu chipsets ${rtl88x2buver}" "info"

		fetch_from_repo "https://github.com/cilynx/rtl88x2bu" "rtl88x2bu" "${rtl88x2buver}" "yes"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl88x2bu"
		mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl88x2bu/"
		cp -R "${SRC}/cache/sources/rtl88x2bu/${rtl88x2buver#*:}"/{core,hal,include,os_dep,platform,halmac.mk,rtl8822b.mk} \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl88x2bu"

		# Makefile
		cp "${SRC}/cache/sources/rtl88x2bu/${rtl88x2buver#*:}/Makefile" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl88x2bu/Makefile"
		cp "${SRC}/cache/sources/rtl88x2bu/${rtl88x2buver#*:}/Kconfig" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl88x2bu/Kconfig"

		# Adjust path
		sed -i 's/include $(src)\/rtl8822b.mk /include $(TopDIR)\/drivers\/net\/wireless\/rtl88x2bu\/rtl8822b.mk/' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl88x2bu/Makefile"

		# Add to section Makefile
		echo "obj-\$(CONFIG_RTL8822BU) += rtl88x2bu/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl88x2bu\/Kconfig"' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

	fi




	# Wireless drivers for Realtek 8723DS chipsets

	if linux-version compare "${version}" ge 5.0 && [ "$EXTRAWIFI" == yes ]; then

		# attach to specifics tag or branch
		local rtl8723dsver="branch:master"

		display_alert "Adding" "Wireless drivers for Realtek 8723DS chipsets ${rtl8723dsver}" "info"

		fetch_from_repo "https://github.com/lwfinger/rtl8723ds" "rtl8723ds" "${rtl8723dsver}" "yes"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723ds"
		mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723ds/"
		cp -R "${SRC}/cache/sources/rtl8723ds/${rtl8723dsver#*:}"/{core,hal,include,os_dep,platform} \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723ds"

		# Makefile
		cp "${SRC}/cache/sources/rtl8723ds/${rtl8723dsver#*:}/Makefile" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723ds/Makefile"
		cp "${SRC}/cache/sources/rtl8723ds/${rtl8723dsver#*:}/Kconfig" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723ds/Kconfig"

		# Disable debug
		sed -i "s/^CONFIG_RTW_DEBUG.*/CONFIG_RTW_DEBUG = n/" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723ds/Makefile"

		# Add to section Makefile
		echo "obj-\$(CONFIG_RTL8723DS) += rtl8723ds/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8723ds\/Kconfig"' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

	fi




	# Wireless drivers for Realtek 8723DU chipsets

	if linux-version compare $version ge 5.0 && [ "$EXTRAWIFI" == yes ]; then

		# attach to specifics tag or branch
		local rtl8723duver="branch:master"

		display_alert "Adding" "Wireless drivers for Realtek 8723DU chipsets ${rtl8723duver}" "info"

		fetch_from_repo "https://github.com/lwfinger/rtl8723du" "rtl8723du" "${rtl8723duver}" "yes"
		cd ${SRC}/cache/sources/${LINUXSOURCEDIR}
		rm -rf ${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723du
		mkdir -p ${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723du/
		cp -R ${SRC}/cache/sources/rtl8723du/${rtl8723duver#*:}/{core,hal,include,os_dep,platform} \
		${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723du

		# Makefile
		cp ${SRC}/cache/sources/rtl8723du/${rtl8723duver#*:}/Makefile \
		${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723du/Makefile

		# Disable debug
		sed -i "s/^CONFIG_RTW_DEBUG.*/CONFIG_RTW_DEBUG = n/" \
		${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8723du/Makefile

		# Add to section Makefile
		echo "obj-\$(CONFIG_RTL8723DU) += rtl8723du/" >> $SRC/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8723du\/Kconfig"' \
		$SRC/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig

		process_patch_file "${SRC}/patch/misc/wireless-rtl8723du.patch" "applying"
	fi


	# Wireless drivers for Realtek 8192EU chipsets

	if linux-version compare "${version}" ge 5.5 && [ "$EXTRAWIFI" == yes ]; then

		# attach to specifics tag or branch
		local rtl8192euver="branch:realtek-4.4.x"

		display_alert "Adding" "Wireless drivers for Realtek 8192EU chipsets ${rtl8192euver}" "info"

		fetch_from_repo "https://github.com/Mange/rtl8192eu-linux-driver" "rtl8192eu" "${rtl8192euver}" "yes"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8192eu"
		mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8192eu/"
		cp -R "${SRC}/cache/sources/rtl8192eu/${rtl8192euver#*:}"/{core,hal,include,os_dep,platform} \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8192eu"

		# Makefile
		cp "${SRC}/cache/sources/rtl8192eu/${rtl8192euver#*:}/Makefile" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8192eu/Makefile"
		cp "${SRC}/cache/sources/rtl8192eu/${rtl8192euver#*:}/Kconfig" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8192eu/Kconfig"

		# Add to section Makefile
		echo "obj-\$(CONFIG_RTL8192EU) += rtl8192eu/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8192eu\/Kconfig"' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

	fi


	# Wireless drivers for Realtek 8192CU chipsets

	if linux-version compare "${version}" ge 5.5 && [ "$EXTRAWIFI" == yes ]; then

		# attach to specifics tag or branch
		local rtl8192cuver="branch:master"

		display_alert "Adding" "Wireless drivers for Realtek 8192CU chipsets ${rtl8192cuver}" "info"

		fetch_from_repo "https://github.com/pvaret/rtl8192cu-fixes" "rtl8192cu" "${rtl8192cuver}" "yes"
		cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
		rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8192cu"
		mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8192cu/"
		cp -R "${SRC}/cache/sources/rtl8192cu/${rtl8192cuver#*:}"/{core,hal,include,os_dep} \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8192cu"

		cd ${SRC}/cache/sources/rtl8192cu/${rtl8192cuver#*:}
		process_patch_file "${SRC}/patch/misc/wireless-rtl8192cu.patch"                "applying"
		cd ${SRC}/cache/sources/${LINUXSOURCEDIR}

		# Makefile
		cp "${SRC}/cache/sources/rtl8192cu/${rtl8192cuver#*:}/Makefile" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8192cu/Makefile"
		cp "${SRC}/cache/sources/rtl8192cu/${rtl8192cuver#*:}/Kconfig" \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8192cu/Kconfig"

		# Add to section Makefile
		echo "obj-\$(CONFIG_RTL8192CU) += rtl8192cu/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8192cu\/Kconfig"' \
		"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"


	fi

	# Wireless drivers for Realtek 8822BS chipsets

	# if linux-version compare "${version}" ge 5.5 && [ "$EXTRAWIFI" == yes ]; then

	# 	# attach to specifics tag or branch
	# 	local rtl8822bsver="branch:master"

	# 	display_alert "Adding" "Wireless drivers for Realtek 8822BS chipsets ${rtl8822bsver}" "info"

	# 	fetch_from_repo "https://github.com/ChalesYu/rtl8822bs-aml" "rtl8822bs" "${rtl8822bsver}" "yes"
	# 	cd "${SRC}/cache/sources/${LINUXSOURCEDIR}" || exit
	# 	rm -rf "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8822bs"
	# 	mkdir -p "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8822bs/"
	# 	cp -R "${SRC}/cache/sources/rtl8822bs/${rtl8822bsver#*:}"/{core,hal,include,os_dep,platform,bluetooth,getAP,rtl8822b.mk} \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8822bs"

	# 	# Makefile
	# 	cp "${SRC}/cache/sources/rtl8822bs/${rtl8822bsver#*:}/Makefile" \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8822bs/Makefile"
	# 	cp "${SRC}/cache/sources/rtl8822bs/${rtl8822bsver#*:}/Kconfig" \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/rtl8822bs/Kconfig"

	# 	# Add to section Makefile
	# 	echo "obj-\$(CONFIG_RTL8822BS) += rtl8822bs/" >> "${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Makefile"
	# 	sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/rtl8822bs\/Kconfig"' \
	# 	"${SRC}/cache/sources/${LINUXSOURCEDIR}/drivers/net/wireless/Kconfig"

	# 	# Patch
	# 	process_patch_file "${SRC}/patch/misc/wireless-rtl8822bs.patch"                "applying"
	# 	process_patch_file "${SRC}/patch/misc/wireless-rtl8822bs-1.patch"                "applying"

	# fi


	if linux-version compare $version ge 4.4 && linux-version compare $version lt 5.8; then
		display_alert "Adjustin" "Framebuffer driver for ST7789 IPS display" "info"
		process_patch_file "${SRC}/patch/misc/fbtft-st7789v-invert-color.patch" "applying"
	fi

}
