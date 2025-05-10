#!/data/data/com.termux/files/usr/bin/bash -e
# Copyright ©2018 by Hax4Us. All rights reserved.  🌎 🌍 🌏 🌐 🗺
#
# https://hax4us.com
################################################################################
# Updated By: Marcio Wesley Borges https://marciowb.dev
# Modified Date: 2025-05-09
################################################################################
set +e

# colors
red='\033[1;31m'
yellow='\033[1;33m'
blue='\033[1;34m'
reset='\033[0m'

# Clean up
pre_cleanup() {
	scriptfile="$(which startkali.sh 2>/dev/null)"
 	if [[ $scriptfile != "" ]]; then
		mv ${scriptfile} startkali.sh.old
	fi
}

post_cleanup() {
	echo "Try to run Kali using startkali.sh and after all, maybe you would like to update and upgrade your packages."
} 

# Utility function for Unknown Arch
#####################
#    Decide Chroot  #
#####################

setchroot() {
	chroot=full
}

#####################
#    SETARCH        #
#####################
unknownarch() {
	printf "${red} [*] Unknown Architecture :("
	printf "\n${reset}"
	exit
}

# Utility function for detect system
checksysinfo() {
	printf "$blue [*] Checking host architecture ..."
	case $(getprop ro.product.cpu.abi) in
		arm64-v8a)
			SETARCH=arm64;;
		armeabi|armeabi-v7a)
			SETARCH=armhf;;
		*)
			unknownarch;;
	esac
        printf "\n [*] SETARCH = ${SETARCH}"
}

# Check if required packages are present
checkdeps() {
	printf "\n${blue} [*] Updating apt cache..."
	apt update -y &> /dev/null
	echo "\n [*] Checking for all required tools..."

	for i in proot tar axel wget sed; do
		if [ -e $PREFIX/bin/$i ]; then
			echo "\n  • ${i} is OK"
		else
			echo "\nInstalling ${i}..."
			apt install -y $i || 
                        {
				printf "\n${red} ERROR: check your internet connection or apt"
				printf "\n Exiting...${reset}\n"
				exit
			}
		fi
	done
	apt upgrade -y
}

# URLs of all possibls architectures
seturl() {
	URL="https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-${chroot}-${SETARCH}.tar.xz"
}

# Utility function to get tar file
gettarfile() {
    seturl
    printf "\n$blue} [*] Fetching tar file"
    printf "\n from ${URL}"
    cd $HOME
    rootfs="kali-nethunter-rootfs-${chroot}-${SETARCH}.tar.xz"
    printf "\n [*] Placing ${rootfs}"
    DESTINATION=$HOME/chroot/kali-$SETARCH
    printf "\n into {$DESTINATION}"
    printf "${reset}\n"
    if [ ! -f "$rootfs" ]; then
        axel ${EXTRAARGS} --alternate "$URL"
    else
        printf "${red} [!] continuing with already downloaded image,"
        printf "\n if this image is corrupted or half downloaded then "
        printf "\n delete it manually to download a fresh image."
        printf "${reset}\n"
    fi
}

# Utility function to get SHA
getsha() {
	printf "\n${blue} [*] Getting SHA ... $reset\n"
	if [ -f "$rootfs.sha512sum" ]; then
		rm "$rootfs.sha512sum"
	fi
	axel ${EXTRAARGS} --alternate "${URL}.sha512sum" -o $rootfs.sha512sum || echo "Failed to download file signature"
}

# Utility function to check integrity
checkintegrity() {
	printf "\n${blue} [*] Checking integrity of file..."
	printf "\n [*] The script will immediately terminate in case of integrity failure"
	printf "${reset}\n"
 	if [ -f "$rootfs.sha512sum" ]; then
		sha512sum -c "$rootfs.sha512sum" || \
	        {
			printf "${red} Sorry :( to say your downloaded linux file was corrupted"
	                printf "\n or half downloaded, but don'''t worry, just rerun this script"
	                printf "${reset}\n"
			exit 1
		}
  	fi
}

# Utility function to extract tar file
extract() {
	printf "\n${blue} [*] Extracting ${rootfs}"
        printf "\n into ${DESTINATION}"
        printf "${reset}\n"
	proot --link2symlink \
              tar -xf $rootfs \
              -C $HOME 2> /dev/null || :

        # fallback to most recent package structure
	KALI=`basename ${DESTINATION}`
	if [ -d "${HOME}/${KALI}" ]; then
 		CHROOTDIR=`dirname ${DESTINATION}`
 		mkdir -p $CHROOTDIR
		ln -s "${HOME}/${KALI}" "${CHROOTDIR}/${KALI}"
  	fi
}

# Utility function for login file
createloginfile() {
	bin=$PREFIX/bin/startkali.sh
        printf "\n${blue} [*] Creating ${bin}"
        printf "${reset}\n"
cat <<EOM > $bin
#!/data/data/com.termux/files/usr/bin/bash -e
unset LD_PRELOAD

# colors
red='\033[1;31m'
yellow='\033[1;33m'
blue='\033[1;34m'
reset='\033[0m'

KALIDIR="${DESTINATION}"

#####################
#    SETARCH        #
#####################
unknownarch() {
	printf "\n${red} [*] Unknown Architecture :("
	printf "${reset}\n"
	exit
}

# Utility function for detect system
checksysinfo() {
	printf "\n$blue [*] Checking host architecture ..."
	case $(getprop ro.product.cpu.abi) in
		arm64-v8a)
			SETARCH=arm64;;
		armeabi|armeabi-v7a)
			SETARCH=armhf;;
		*)
			unknownarch;;
	esac
        printf "\n [*] SETARCH = ${SETARCH}"
}
if [ ! -f \${KALIDIR}/root/.version ]; then
    touch \${KALIDIR}/root/.version
fi

user=kali
home="/home/\${user}"
LOGIN="sudo -u kali /bin/bash"
if [[ ("\$#" != "0" && ("\$1" == "-r")) ]]; then
	user=root
	home="/\${user}"
	LOGIN="/bin/bash --login"
	shift
fi

cmd_proot() {
	if [[ \$# != 0 ]]; then
		proot \
		    --link2symlink \
		    -0 \
		    -r \${KALIDIR} \
		    -b /dev \
		    -b /proc \
		    -b \${KALIDIR}/dev:/dev/shm \
		    -b /sdcard \
		    -b "${HOME}:/opt/host" \
		    -w \${home} \
		    /bin/env -i \
		    HOME=\${home} \
		    TERM=${TERM} \
		    LANG=${LANG} \
		    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\${home}/bin \
		    \${LOGIN} -c "\$*"
	  else
		proot \
		    --link2symlink \
		    -0 \
		    -r \${KALIDIR} \
		    -b /dev \
		    -b /proc \
		    -b \${KALIDIR}/dev:/dev/shm \
		    -b /sdcard \
		    -b "${HOME}:/opt/host" \
		    -w \${home} \
		    /bin/env -i \
		    HOME=\${home} \
		    TERM=${TERM} \
		    LANG=${LANG} \
		    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\${home}/bin \
		    \${LOGIN}
	fi   
}
cmd_proot  "\$@"

EOM
	chmod 700 $bin
 	ln -s $bin $PREFIX/bin/startkali || true
}

printline() {
	printf "\n${blue}"
	echo " #---------------------------------#"
}

# Start
clear
EXTRAARGS=""
if [[ ! -z $1 ]]; then
    EXTRAARGS=$1
    if [[ $EXTRAARGS != "--insecure" ]]; then
		EXTRAARGS=""
    fi
fi

printf "\n${yellow} You are going to install Kali Nethunter"
printf "\n In Termux Without Root ;) Cool"

pre_cleanup
checksysinfo
checkdeps
setchroot
gettarfile
getsha
checkintegrity
extract
createloginfile
post_cleanup

printf "\n${blue} [*] Configuring Kali For You ..."

# Update Kali sign key to allow packages upgrade and allow fetches from http
fix_package_updates() {
	wget https://archive.kali.org/archive-keyring.gpg -O $DESTINATION/usr/share/keyrings/kali-archive-keyring.gpg
	sed 's/^deb http:/ deb [trusted=yes] http:/' -i $DESTINATION/etc/apt/sources.list
}
fix_package_updates

# Utility function for resolv.conf
resolvconf() {
	#create resolv.conf file 
	printf "\nnameserver 8.8.8.8\nnameserver 1.1.1.1" > $DESTINATION/etc/resolv.conf
} 
resolvconf

################
# finaltouchup #
################

finalwork() {
	echo "DESTINATION=$DESTINATION, SETARCH=$SETARCH"

	[ -e $HOME/finaltouchup.sh ] && rm $HOME/finaltouchup.sh
	echo
	wget https://raw.githubusercontent.com/marciowb/Nethunter-In-Termux/refs/heads/master/finaltouchup.sh
 	
	if [ ! -f $HOME/finaltouchup.sh ]; then
		sleep 2
		wget https://raw.githubusercontent.com/marciowb/Nethunter-In-Termux/refs/heads/master/finaltouchup.sh
	fi
   
	DESTINATION=$DESTINATION SETARCH=$SETARCH bash $HOME/finaltouchup.sh
} 
finalwork

printline
printf "\n${yellow} Now you can enjoy Kali Nethuter in your Termux :)"
printf "\n Don't forget to like my hard work for termux and many other things"
printline
printline
printf "\n${blue} [*] My official email:${yellow} lkpandey950@gmail.com"
printf "\n${blue} [*] My website:${yellow} https://hax4us.com"
printf "\n${blue} [*] My YouTube channel:${yellow} https://youtube.com/hax4us"
printline
printf "\n${blue} [*] Fixed by:${yellow} Marcio Wesley Borges https://marciowb.dev"
printline
printf "${reset}\n"
