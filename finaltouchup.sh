#!/data/data/com.termux/files/usr/bin/bash
set +e

if [ -z $DESTINATION -o -z $SETARCH ]; then
    echo "DESTINATION and SETARCH environment variables is required." >&2
    exit 1
fi
echo "DESTINATION=$DESTINATION, SETARCH=$SETARCH"

fix_profile() {
    if [ -f ${DESTINATION}/root/.bash_profile ]; then
        sed -i '/if/,/fi/d' "${DESTINATION}/root/.bash_profile"
    fi
}

fix_sudo() {
    chmod +s $DESTINATION/usr/bin/sudo
    chmod +s $DESTINATION/usr/bin/su
    echo "kali    ALL=(ALL:ALL) ALL" > $DESTINATION/etc/sudoers.d/kali
    echo "Set disable_coredump false" >> $DESTINATION/etc/sudo.conf
}

fix_uid() {
    AUID=$(id -u)
    AGID=$(id -g)
    sed "/^kali:/ s/\(.*\):\([0-9]\+\):\([0-9]\+\):\(.*\)$/\1:${AUID}:${AGID}:\4/" -i "${DESTINATION}/etc/passwd"
    sed "/^kali:/ s/\(.*\):[0-9]\+:\(.*\)$/\1:${AGID}:\2/" -i "${DESTINATION}/etc/group"
    startkali.sh cat /etc/passwd | tail -n5
    startkali.sh cat /etc/group | tail -n5
}

create_xsession_handler() {
    if [ $SETARCH = "arm64" ]; then
        LIBGCCPATH=/usr/lib/aarch64-linux-gnu
    else
        LIBGCCPATH=/usr/lib/arm-linux-gnueabihf
    fi
    VNC_WRAPPER=$DESTINATION/usr/bin/vnc
    cat > $VNC_WRAPPER <<- EOF
#!/bin/bash
    
vnc_start() {
    if [ ! -f ~/.vnc/passwd ]; then
        vnc_passwd
    fi
    USR=\$(whoami)
    if [ \$USR = "root" ]; then
        SCR=:1
    else
        SCR=:2
    fi
    export USER=\$USR; LD_PRELOAD=$LIBGCCPATH/libgcc_s.so.1 nohup vncserver \$SCR >/dev/null 2>&1 </dev/null
}

vnc_stop() {
    vncserver -kill :1
    vncserver -kill :2
    return \$?
}

vnc_passwd() {
    vncpasswd
    return \$?
}

vnc_status() {
    session_list=\$(vncserver -list)
    if [[ \$session_list == *"590"* ]]; then
        echo "\$session_list"
    else
        echo "there is nothing to list :)"
        echo "you can start a new session by << vnc start >>"
    fi
}

vnc_kill() {
    pkill Xtigervnc
    return \$?
}

case "\$1" in
    start)
        vnc_start
        ;;
    stop)
        vnc_stop
        ;;
    status)
        vnc_status
        ;;
    kill)
        vnc_kill
        ;;
    *)
        echo "[!] invalid input"
esac
EOF
chmod +x $VNC_WRAPPER
}

## Main

fix_profile
fix_sudo
fix_uid
create_xsession_handler
