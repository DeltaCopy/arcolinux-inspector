#!/usr/bin/env sh
set -eo pipefail

version="0.1"
discord_link="https://discord.gg/R2amEEz"
forums_link="https://arcolinuxforum.com"
cat <<EOF
+========================================================================+
                         ARCOLINUX SYSTEM INSPECTOR
                               Version: ${version}
+========================================================================+
EOF

function show_iso {
  echo ":: [ISO]"

  test -s "/etc/dev-rel" && iso_release=$(cat /etc/dev-rel | awk -F '=' '/ISO_RELEASE/' | awk -F= '{print $2}')
  test -s "/etc/dev-rel" && iso_codename=$(cat /etc/dev-rel | awk -F '=' '/ISO_CODENAME/' | awk -F= '{print $2}')
  test -s "/etc/dev-rel" && iso_build=$(cat /etc/dev-rel | awk -F '=' '/ISO_BUILD/' | awk -F= '{print $2}')

  test ! -z "$iso_release" && echo " Release = $iso_release" || echo " Release = unknown"
  test ! -z "$iso_codename" && echo " Codename = $iso_codename" || echo " Codename = unknown"
  test ! -z "$iso_build" && echo " Build = $iso_build" || echo " Build = unknown"

  echo "--------------------------------------------------------------------------"
}

function show_lsb_release {
  echo ":: [lsb-release]"

  lsb_release="/etc/lsb-release"

  if [ -f "$lsb_release" ]; then
    distrib_id=$(cat $lsb_release | awk -F '=' '/DISTRIB_ID/' | awk -F= '{print $2}')
    distrib_release=$(cat $lsb_release | awk -F '=' '/DISTRIB_RELEASE/' | awk -F= '{print $2}')
    distrib_desc=$(cat $lsb_release | awk -F '=' '/DISTRIB_DESCRIPTION/' | awk -F= '{print $2}')

    test ! -z "$distrib_id" && echo " Distrib-ID = $distrib_id"
    test ! -z "$distrib_release" && echo " Distrib-Release = $distrib_release"
    test ! -z "$distrib_desc" && echo " Distrib-Description = $distrib_desc"

  fi

  echo "--------------------------------------------------------------------------"
}

function show_desktop_session {
  echo ":: [Desktop Evironment]"

  desktop_session=$(env | grep -w DESKTOP_SESSION | awk -F= '{print $2}')

  test -z "$desktop_session" && desktop_session=$(env | grep -w XDG_CURRENT_DESKTOP | awk -F= '{print $2}')

  test -z "$desktop_session" && desktop_session=$(env | grep -w XDG_SESSION_DESKTOP | awk -F= '{print $2}')

  test ! -z "$desktop_session" && echo " Desktop Evironment = $desktop_session"

  echo "--------------------------------------------------------------------------"

}

function show_display_server {
  display_session=$(loginctl show-session $(loginctl|grep $(whoami) | awk '{print $1}') -p Type | awk -F= '{print $2}' | grep "x11\|wayland\|tty")

  echo ":: [Display Server]"

  test ! -z "$display_session" && echo " $display_session" || echo " Display Server is unknown"

  echo "--------------------------------------------------------------------------"
}

function show_display {
  x11_display=$(env | grep -w DISPLAY | awk -F= '{print $2}')
  wayland_display=$(env | grep -w WAYLAND_DISPLAY | awk -F= '{print $2}')

  echo ":: [Display]"

  test ! -z "$x11_display" && echo " X11 Display = $x11_display"
  test ! -z "$wayland_display" && echo " Wayland Display = $wayland_display"

  echo "--------------------------------------------------------------------------"
}

function show_xauth_info {
  xauth_file=$(xauth info | awk -F'Authority file:' {'print $2'} | cut -d ' ' -f 8)
  xauth_entries=$(xauth info | awk -F'Number of entries:' {'print $2'}| tr -d '\n' | tr -d ' '  )


  echo ":: [XAuthority Info]"
  test ! -z "$xauth_file" && echo " XAuthority file = $xauth_file"
  test ! -z "$xauth_entries" && echo " Entries = $xauth_entries"

  echo "--------------------------------------------------------------------------"
}

function show_shell {
  shell=$(getent passwd `whoami` | awk -F: '{print $NF}')

  echo ":: [Default Shell]"
  test ! -z "$shell" && echo " $shell" || echo " Default Shell is unknown"

  echo "--------------------------------------------------------------------------"
}

function check_att {
  echo ":: [Arch Linux Tweak Tool]"
  test -f "/usr/bin/att" && test -f "/usr/share/archlinux-tweak-tool/archlinux-tweak-tool.py" && echo " Arch Linux Tweak Tool is installed" || echo " Arch Linux Tweak Tool is not installed"

  att_version=$(pacman -Q archlinux-tweak-tool-git | awk {'print $2'})
  test ! -z "$att_version" && echo " Version = $att_version"

  echo "--------------------------------------------------------------------------"
}

function check_adt {
  echo ":: [ArcoLinux Desktop Trasher]"
  test -f "/usr/local/bin/arcolinux-desktop-trasher" && test -f "/usr/share/arcolinux-desktop-trasher/arcolinux-desktop-trasher.py" && echo " ArcoLinux Desktop Trasher is installed" || echo " ArcoLinux Desktop Trasher is not installed"

  adt_version=$(pacman -Q arcolinux-desktop-trasher-git | awk {'print $2'})
  test ! -z "$adt_version" && echo " Version = $adt_version"

  echo "--------------------------------------------------------------------------"
}

function check_probe {
  echo ":: [Probe]"
  test -f "/usr/bin/hw-probe" && echo " Probe is installed" || echo " Probe is not installed"

  probe_version=$(pacman -Q hw-probe | awk {'print $2'})
  test ! -z "$probe_version" && echo " Version = $probe_version"

  echo "--------------------------------------------------------------------------"
}

function check_system_config {
  echo ":: [System Config]"

}

function footer {
  echo "+========================================================================+"
  echo " For technical support run \"probe\" then send the Arco Linux team the link"
  echo " Support is available on:"
  echo "    - Discord: $discord_link"
  echo "    - Forums: $forums_link"
  echo "+========================================================================+"
}

# help
function show_usage {
  cat <<EOF
Usage:
  $0 --all              shows all the information
Options
  --iso                 iso information
  --lsb                 lsb_release information
  --desktop             desktop environment information
  --session             display server information
  --display             display information
  --xauth               XAuthority information
  --shell               shell information
  --att                 Arch Linux Tweak Tool information
  --adt                 ArcoLinux Desktop Trasher information
  --probe               probe information
  --help                this help message and exit
EOF

}

# if there is no flag print all

function run_all {
  show_iso
  show_lsb_release
  show_desktop_session
  show_display_server
  show_display
  show_xauth_info
  show_shell
  check_att
  check_adt
  check_probe
  footer
}

# if there is a flag set print only the one selected
case "$1" in
  "--iso")
      show_iso && footer && exit
  ;;
  "--lsb")
      show_lsb_release && footer && exit
  ;;
  "--desktop")
      show_desktop_session && footer && exit
  ;;
  "--session")
      show_display_server && footer && exit
  ;;
  "--display")
      show_display && footer && exit
  ;;
  "--xauth")
      show_xauth_info && footer && exit
  ;;
  "--shell")
      show_shell && footer && exit
  ;;
  "--att")
      check_att && footer && exit
  ;;
  "--adt")
      check_adt && footer && exit
  ;;
  "--probe")
      check_probe && footer && exit
  ;;
  "--help")
      show_usage && footer && exit 0
  ;;
  "--all")
      run_all && exit
  ;;
  *)
      show_usage
      exit 1
esac
