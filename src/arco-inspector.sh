#!/usr/bin/env sh
set -eo pipefail

version="0.1"
discord_link="https://discord.gg/stBhS4taje"
forums_link="https://arcolinuxforum.com"

echo -e "+========================================================================+"
echo -e "                       \e[1mARCOLINUX SYSTEM INSPECTOR\e[0m"
echo    "                             Version: ${version}"
echo   "+========================================================================+"

function show_iso {
  echo -e "\e[1m:: [ISO]\e[0m"

  test -s "/etc/dev-rel" && iso_release=$(cat /etc/dev-rel | awk -F '=' '/ISO_RELEASE/' | awk -F= '{print $2}')
  test -s "/etc/dev-rel" && iso_codename=$(cat /etc/dev-rel | awk -F '=' '/ISO_CODENAME/' | awk -F= '{print $2}')
  test -s "/etc/dev-rel" && iso_build=$(cat /etc/dev-rel | awk -F '=' '/ISO_BUILD/' | awk -F= '{print $2}')

  test ! -z "$iso_release" && echo " Release = $iso_release" || echo " Release = unknown"
  test ! -z "$iso_codename" && echo " Codename = $iso_codename" || echo " Codename = unknown"
  test ! -z "$iso_build" && echo " Build = $iso_build" || echo " Build = unknown"

  echo "--------------------------------------------------------------------------"
}

function show_lsb_release {
  echo -e "\e[1m:: [lsb-release]\e[0m"

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
  echo -e "\e[1m:: [Desktop Evironment]\e[0m"

  desktop_session=$(env | grep -w DESKTOP_SESSION | awk -F= '{print $2}')

  test -z "$desktop_session" && desktop_session=$(env | grep -w XDG_CURRENT_DESKTOP | awk -F= '{print $2}')
  test -z "$desktop_session" && desktop_session=$(env | grep -w XDG_SESSION_DESKTOP | awk -F= '{print $2}')
  test ! -z "$desktop_session" && echo " Desktop Evironment = $desktop_session"

  echo "--------------------------------------------------------------------------"

}

function show_display_session {
  echo -e "\e[1m:: [Display Session]\e[0m"

  display_session=$(loginctl show-session $(loginctl|grep $(whoami) | awk '{print $1}') -p Type | awk -F= '{print $2}' | grep "x11\|wayland\|tty")
  test ! -z "$display_session" && echo " $display_session" || echo " Display Session is unknown"

  echo "--------------------------------------------------------------------------"
}

function show_display {
  echo -e "\e[1m:: [Display]\e[0m"

  x11_display=$(env | grep -w DISPLAY | awk -F= '{print $2}')
  wayland_display=$(env | grep -w WAYLAND_DISPLAY | awk -F= '{print $2}')

  test ! -z "$x11_display" && echo " X11 Display = $x11_display"
  test ! -z "$wayland_display" && echo " Wayland Display = $wayland_display"

  echo "--------------------------------------------------------------------------"
}

function show_xauth_info {
  echo -e "\e[1m:: [XAuthority Info]\e[0m"
  xauth_file=$(xauth info | awk -F'Authority file:' {'print $2'} | cut -d ' ' -f 8)
  xauth_entries=$(xauth info | awk -F'Number of entries:' {'print $2'}| tr -d '\n' | tr -d ' '  )

  test ! -z "$xauth_file" && echo " XAuthority file = $xauth_file"
  test ! -z "$xauth_entries" && echo " Entries = $xauth_entries"

  echo "--------------------------------------------------------------------------"
}

function show_shell {
  echo -e "\e[1m:: [Default Shell]\e[0m"

  shell=$(getent passwd `whoami` | awk -F: '{print $NF}')
  test ! -z "$shell" && echo " $shell" || echo " Default Shell is unknown"

  echo "--------------------------------------------------------------------------"
}

function show_probe {
  echo -e "\e[1m:: [Probe]\e[0m"

  test -f "/usr/bin/hw-probe" && echo " Probe is installed" || echo " Probe is not installed"

  probe_version=$(pacman -Q hw-probe | awk {'print $2'})
  test ! -z "$probe_version" && echo -e " Version = \e[1m$probe_version\e[0m"

  echo "--------------------------------------------------------------------------"
}

function show_all_arco {
  echo -e "\e[1m:: [Installed ArcoLinux Packages]\e[0m"
  i=0

  # query pacman search for any arco packages installed
  pacman_local_query=$(pacman -Qq | grep "arcolinux\|archlinux")

  for pkg in $pacman_local_query; do

    url=$(pacman -Qi $pkg | grep -w URL)
    # note the xargs used to trim whitespaces
    local_version=$(pacman -Qi $pkg | grep -w Version | awk -F'Version         :' {'print $2'} | xargs)
    remote_version=$(pacman -Si $pkg | grep -w Version | awk -F'Version         :' {'print $2'} | xargs)

    case "$url" in
      *"arcolinux"*)
        i=$((i + 1))
        echo -e " $i. $pkg :: installed ==> \e[1m $local_version\e[0m :: latest ==> \e[1;34m $remote_version\e[0m"
      ;;
    esac
  done

  echo "--------------------------------------------------------------------------"
}

function show_polkit {
  echo -e "\e[1m:: [Polkit]\e[0m"
  if [[ ! -z $(systemctl status polkit) ]]; then
    polkit_status=$(systemctl status polkit | grep -w "active (running)" | xargs)

    test ! -z "$polkit_status" &&  echo -e " Polkit service :\e[1m active (running)\e[0m" || echo -e " Polkit service :\e[1m not installed/running\e[0m"
  fi

  # check pid
  if [[ ! -z $(ps -ef | grep polkitd | grep -v color | xargs) ]]; then
    echo -e " Polkitd process with pid: $(pidof -s polkitd) =\e[1m running\e[0m"
  else
    echo -e " Polkitd process: \e[1m not running\e[0m"
  fi

  echo "--------------------------------------------------------------------------"
}

function show_display_mgr {
  echo -e "\e[1m:: [Display Manager]\e[0m"

  displays=("sddm" "lightdm" "ly cdm tdm loginx nodm tbsm emptty lemurs gdm lxdm xdm")
  for disp_mgr in ${displays[@]}; do
    proc=$(ps -ef | grep -w $disp_mgr | grep -v color | xargs)
    if [ ! -z "$proc" ]; then
      test $(pidof -s $disp_mgr) && echo -e "\e[1m $disp_mgr\e[0m : running"
      break
    fi
  done
  echo "--------------------------------------------------------------------------"
}


function show_hardware {
  echo -e "\e[1m:: [Hardware]\e[0m"
  test $(type inxi &> /dev/null) && echo -e "\e[1m inxi not found\e[0m"

  audio=$(inxi -A | sed 's/Audio://')
  cpu=$(inxi -C | sed 's/CPU://')
  network=$(inxi -N | sed 's/Network://')
  graphics=$(inxi -G | sed 's/Graphics://')

  test ! -z "$cpu" && echo && echo -e " \e[1m CPU: \e[0m  $cpu"
  test ! -z "$graphics" && echo && echo -e " \e[1m Graphics: \e[0m  $graphics"
  test ! -z "$audio" && echo && echo -e " \e[1m Audio: \e[0m  $audio"
  test ! -z "$network" && echo && echo -e " \e[1m Network: \e[0m  $network"

  echo "--------------------------------------------------------------------------"
}

function show_system {
  echo -e "\e[1m:: [System]\e[0m"
  test $(type inxi &> /dev/null) && echo -e "\e[1m inxi not found\e[0m"

  system=$(inxi -S | sed 's/System://')

  test ! -z "$system" && echo -e " Details: $system"

  echo "--------------------------------------------------------------------------"
}


function footer {
  echo "+========================================================================+"
  echo " For technical support run \"probe\" then send the ArcoLinux team the link"
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
  --displaymgr          display-manager information
  --xauth               XAuthority information
  --shell               shell information
  --probe               probe information
  --polkit              Polkit information
  --hardware            hardware information
  --arco                ArcoLinux package information
  --help                this help message and exit
EOF

}

# if there is no flag print all

function run_all {
  show_iso
  show_lsb_release
  show_desktop_session
  show_display_session
  show_display
  show_display_mgr
  show_xauth_info
  show_shell
  show_probe
  show_polkit
  show_hardware
  show_system
  show_all_arco
  footer
}

# if there is a flag set print only the one selected
case "$1" in
  "--iso")
      show_iso && footer
  ;;
  "--lsb")
      show_lsb_release && footer
  ;;
  "--desktop")
      show_desktop_session && footer
  ;;
  "--session")
      show_display_session && footer
  ;;
  "--display")
      show_display && footer
  ;;
  "--displaymgr")
      show_display_mgr && footer
  ;;
  "--xauth")
      show_xauth_info && footer
  ;;
  "--shell")
      show_shell && footer
  ;;
  "--probe")
      show_probe && footer
  ;;
  "--arco")
      show_all_arco && footer
  ;;
  "--polkit")
      show_polkit
  ;;
  "--hardware")
    show_hardware
  ;;
  "--system")
    show_system
  ;;
  "--help")
      show_usage && footer
  ;;
  "--all")
      run_all
  ;;
  *)
      show_usage
      exit 1
esac
