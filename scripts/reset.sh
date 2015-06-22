#!/system/bin/sh
# Description: Factory resets Pwn Pad 2013/2014 and Pwn Phone 2014
# Result: Stock Pwn Pad 2013/2014/3 or Pwn Phone 2014
clear

#Blank everything by default, but allow to blank only some
: ${chroot_only:=0}

f_run(){

  printf '\n[!] FACTORY RESET in progress. All changes will be lost.\n\n'

  f_reset
}

f_getserial(){

  # Snag serial
  serialno=`/system/bin/getprop ro.serialno`
}

f_getstorage(){

  # Set backup
  backup=`ls /sdcard/TWRP/BACKUPS/$serialno/ |grep -i pwn`

  # Get storage size
  storagesi=`/system/bin/dumpsys devicestoragemonitor |grep mTotalMemory |cut -d "=" -f3 |cut -d "." -f1`

  # Set seek size
  if [ $storagesi -gt 20 ]; then # 32G [~26G free]
    # Set seek size to 20G
    seeksi=20G
  elif [ $storagesi -gt 8 ]; then #16G [~9G free]
    # Set seek size to 7G
    seeksi=7G
  else # 8G [~?G free]
    # Set seek size to ?G
    seeksi=4G
  fi
}

f_reset(){

  # Get parameters
  f_getserial
  f_getstorage

  # Construst cmd for script
  rm -f /cache/recovery/openrecoveryscript
  [ "$chroot_only" = 0 ] && printf "restore /data/media/0/TWRP/BACKUPS/$serialno/$backup\n" > /cache/recovery/openrecoveryscript
  cat << EOF >> /cache/recovery/openrecoveryscript
print  [SETUP STARTED]
cmd export PATH=/usr/bin:/usr/sbin:/bin:/usr/local/bin:/usr/local/sbin:$PATH
cmd mount -o bind /dev /data/local/kali/dev
cmd chroot /data/local/kali/ /bin/dd if=/dev/zero of=/kali.img bs=1 count=0 seek=$seeksi
cmd chroot /data/local/kali/ /sbin/mkfs.ext4 -F /kali.img
cmd mv /data/local/kali/kali.img /data/local/kali_img/
cmd mkdir /data/local/kali_img/kalitmp
cmd mount -t ext4 /data/local/kali_img/kali.img /data/local/kali_img/kalitmp/
cmd cp -a /data/local/kali/* /data/local/kali_img/kalitmp/
cmd umount /data/local/kali_img/kalitmp/
cmd rm -r /data/local/kali_img/kalitmp
print  [SETUP COMPLETE]
print  [FACTORY RESET COMPLETE]
EOF

  # Reboot into recovery; run script
  reboot recovery
}

f_run
