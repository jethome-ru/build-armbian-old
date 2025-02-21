#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

print_title() {
  if [ -n "$1" ] ; then
    echo "###### ${1} ######"
  else
    echo "${FUNCNAME[0]}(): Null parameter passed to this function"
  fi
}


create_deb_packages() {
  print_title "Creating deb packages iterating *.conf files"
  for package_script in /tmp/overlay/packages/*.conf; do
    source "$package_script"
  done
}

customization_install_prebuilt_packages() {
  print_title "Installing customization prebuilt packages"
  local customization_prebuilt_debs
  customization_prebuilt_debs=$(</tmp/overlay/JETHOME_CUSTOMIZATION_NAME)
  local customization_prebuilt_debs_dir_path="/tmp/overlay/packages/customization/$customization_prebuilt_debs"
  if [[ -n "$customization_prebuilt_debs" ]]; then
    if [[ -d "$customization_prebuilt_debs_dir_path" && -n "$(ls "$customization_prebuilt_debs_dir_path")" ]]; then
      for package_deb_file in "$customization_prebuilt_debs_dir_path"/*.deb; do
        if DEBIAN_FRONTEND=noninteractive apt -yqq --no-install-recommends install "$package_deb_file"; then
          cp -fv "$package_deb_file" /tmp/overlay/debs/
        else
          exit 1
        fi
      done
    else
      echo "----> skipping customization prebuilt packages from $customization_prebuilt_debs_dir_path"
    fi
  fi
}

customization_install_rootfs_patches() {
  print_title "Installing customization rootfs patches"
  local customization_rootfs_patches
  customization_rootfs_patches=$(</tmp/overlay/JETHOME_CUSTOMIZATION_NAME)
  if [[ -n "$customization_rootfs_patches" ]]; then
    local patch_dir="/tmp/overlay/rootfs_patches/$customization_rootfs_patches"
    if [[ -d "${patch_dir}" && -n "$(ls "${patch_dir}")" ]]; then
      echo "----> copying patches from ${patch_dir}"
      if ! cp -rvf "${patch_dir}"/* ./; then
        exit 1
      fi
    else
      echo "----> skipping patches from ${patch_dir}"
    fi
  fi
}

install_version_jethome() {
  local name=VERSION_JETHOME
  local src_path=/tmp/overlay/$name
  local dst_path=/etc/$name
  print_title "Installing $dst_path"
  if [[ -f $src_path ]]; then
    cp -fv $src_path $dst_path
  else
    exit 1
  fi
}

install_pip3_packages() {
  local pip_packages=("pyserial" "intelhex" "python-magic")

  print_title "Installing pip3 packages: ${pip_packages[*]}"

  for i in "${pip_packages[@]}"; do
    if ! pip3 install "$i"; then
      echo "$i installation failed"
      exit 1
    fi
  done
}

Main() {
  case $RELEASE in
    focal)
      if [[ "$LINUXFAMILY" = "arm-64" ]]; then
        if [[ "$BOARD" = "arm-64" ]]; then
          create_deb_packages
          customization_install_prebuilt_packages
          customization_install_rootfs_patches
          install_version_jethome
          install_pip3_packages
        fi
      fi
      ;;
  esac
} # Main

Main "$@"
