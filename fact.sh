#!/usr/bin/env bash
#SFICT: Fresh Arch Configuration Tool
#
# You can run this script (from your ArchLinux installation):
#
# curl -L https://tbd.tld/salift.sh | bash
# Make sure `curl` is installed.
#
# Piping to bash is controversial (https://pi-hole.net/2016/07/25/curling-and-piping-to-bash)
# So if you're interested the full source for this script can be found on Github at <Github URL>
#
# This script draws inspiration from lots of sources, to many to list here, a full list can be found on Github.


######## Variables ######## 
declare -a MirrorCountryCodes=("all - All Mirrors", "AU - Australia", "AT - Austria", "BD - Bangladesh", "BY - Belarus", "BE - Belgium", "BA - Bosnia and Herzegovina", "BR - Brazil", "BG - Bulgaria", "CA - Canada", "CL - Chile", "CN - China", "CO - Colombia", "HR - Croatia", "CZ - Czechia", "DK - Denmark", "EC - Ecuador", "FI - Finland", "FR - France", "GE - Georgia", "DE - Germany", "GR - Greece", "HK - Hong Kong", "HU - Hungary", "IS - Iceland", "IN - India", "ID - Indonesia", "IR - Iran", "IE - Ireland", "IL - Israel", "IT - Italy", "JP - Japan", "KZ - Kazakhstan", "KE - Kenya", "LV - Latvia", "LT - Lithuania", "LU - Luxembourg", "MD - Moldova", "NL - Netherlands", "NC - New Caledonia", "NZ - New Zealand", "MK - North Macedonia", "NO - Norway", "PK - Pakistan", "PY - Paraguay", "PH - Philippines", "PL - Poland", "PT - Portugal", "RO - Romania", "RU - Russia", "RS - Serbia", "SG - Singapore", "SK - Slovakia", "SI - Slovenia", "ZA - South Africa", "KR - South Korea", "ES - Spain", "SE - Sweden", "CH - Switzerland", "TW - Taiwan", "TH - Thailand", "TR - Turkey", "UA - Ukraine", "GB - United Kingdom", "US - United States", "VN - Vietnam")
######## Flags ########
CreateUserAccount=true
GenerateSshKeys=true
ChangeHostname=true
ChangeTimezone=true
BuildMirrorlist=true


######## SCRIPT STARTS HERE ########
main(){

    echo "::: this script relies on two things"
    echo "::: 1) An active internet connection"
    echo "::: 2) Some software that will be installed while this script runs."
    echo ""
    echo "::: To prevent extra issues in Github please type \"IM READY\" and hit enter"
    while read -p "Your answer: " var_userawake do
        if [[ "${var_userawake}" != "IM READY"]]; then
            echo "Want to try again?"
        else
            break
    done

    if [[ "${var_userawake}" == "IM READY" ]]; then
        # Verify user is root before we try anything else.
        echo "::: validating if user is root (or using sudo)..."
        if [[ $EUID -eq 0 ]]; then
            echo "::: script is running as root."
        else
            echo "::: trying to enter sudo environment..."
            # Is sudo installed?
            if [[ $(dpkg-query -s sudo) ]]; then
                export SUDO="sudo"
                export SUDOE="sudo -E"
            else
                echo "::: run this script as root or install sudo."
                exit 1
            fi 
        fi

        # Change the hostname
        if [[ "${ChangeHostname}" == true]]; then
            echo "::: what should we set the hostname of this device to?"
            while read -p 'Hostname: ' var_hostname do
                if [[ -z "${var_hostname}" ]]; then
                    echo "::: you must provide a hostname!"
                else
                    echo "::: changing hostname to ${var_hostname}"
                    $SUDO hostnamectl set-hostname $var_hostname
                    break # Out of the loop we go!
                fi
            done
        fi

        # Build a faster mirrorlist
        if [[ "${BuildMirrorlist}" == true]]; then
            echo "::: generating a better mirrorlist"
            echo "::: this script can use reflector or the pacman mirrorlist generator, please choose"
            while read -p "(r)eflector or (g)enerator: " var_mirrortool do
                if [[ -z "${var_mirrortool}" ]]; then
                    echo "::: please make a choice!"
                else
                    if [[ "${var_mirrortool}" == "r"]]; then
                        echo "::: installing reflector"
                        $SUDO pacman --noconfirm -S reflector
                        echo "::: building mirrorlist (this might take a while)"
                        $SUDO reflector --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
                        echo "::: removing reflector"
                        $SUDO pacman --noconfirm -R reflector
                    elif [[ "${var_mirrortool}" == "g"]]; then
                        echo "::: building new mirrorlist using pacman mirrorlist generator"
                        echo "::: please enter the closest countrycode from the following list:"
                        echo -n "::: "
                        for mirror in "${MirrorCountryCodes[@]}"; do
                            echo -n "${mirror}, "
                        echo ""
                        read -p "Choose a mirror: " var_chosenmirror
                        read -p "IPv(4) or IPv(6): " var_ipversion
                        $SUDO curl \"https://archlinux.org/mirrorlist/?country=${var_chosenmirror}&protocol=http&protocol=https&ip_version=${var_ipversion}\" -o /etc/pacman.d/mirrorlist
                    fi
                    echo "::: updating pacman database"
                    $SUDO pacman -Syy
                    echo "::: finished generating mirrorlist"
                    break # Leave the loop (should work right?)
                fi 
            done        
        else
            echo "::: not building a new mirrorlist"
        fi

        # Creating a user account
        if [[ "${CreateUserAccount}" == true]]; then
            echo "::: creating a new user"
            while read -p "Username: " var_username do
                if [[ -z "${var_username}"]]; then
                    echo "::: provide a username!"
                else 
                    useradd -m ${var_username}
                    passwd ${var_username}
                    break
                fi
            done
            echo "::: checking if sudo is installed"
            if [["${SUDO}" != ""]]
                echo "::: sudo is installed"
                echo "::: adding ${var_username} to wheel group (you should allow this group sudo access due to Polkit)"
                usermod -aG wheel ${var_username}
            else
                echo "::: sudo is not installed, moving on"
            fi
            echo "::: finished creating user"

}