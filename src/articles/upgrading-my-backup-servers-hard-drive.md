---
kind: article
title: Upgrading my backup server's hard drive
created_at: 2022-07-28
excerpt: |
  My backup server was running out of space, so I replaced the 320GB hard drive
  with a 4TB one. I ruined the boot partition in the process, but managed to
  fix it.
---

<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>


Earlier this year, I setup a server to host offsite backups for a bunch of
projects. The hardware is a donated [Acer AspireRevo][acer], which comes with a
320GB 2.5″ hard drive. This was good enough for 6 months, but in June it hit
75% capacity, so it was time to upgrade it. I got a 4TB hard drive and delayed
making the migration until this week. It wasn't as smooth as I had hoped.


## Moving the data

The backup server only has one SATA port, so I couldn't just add another disk,
I had to replace it. To do that, I used another server which had a single spare
SATA port and almost a terabyte of free space on its main disk. I didn't want
to reinstall and configure the operating system on the new drive, so the plan
was to:

- install the 320GB disk on the temporary host;
- copy the whole disk, byte by byte, to a file on the temporary host's main disk;
- shutdown the host, remove the 320GB disk and install the 4TB one;
- copy the image file to the 4TB disk;
- extend the partitions / filesystems on the 4TB disk;
- shutdown the host, move the 4TB disk to the backup server, and hope that it worked.

I expected some issues on the partition/filesystem extending step, but the
original data would still live in both the original disk and in the temporary
file, so I had some room to make mistakes there.

To move the data from the 320GB disk to the temporary image file and back to
the 4TB disk, I used `dd`:

~~~~bash
# move data from the 320GB disk to a temporary file
dd if=/dev/sdb of=/srv/backups/backup-disk-image.img BS=1M

# shutdown the host, swap disks, boot it back up

# move data from the temporary file to the 4TB disk
dd if=/srv/backups/backup-disk-image.img of=/dev/sdb BS=1M
~~~~

The first `dd` took a couple of hours, and it seemed to work without any read
or write errors. It was only when I tried copying things back that I started
getting **read** errors. This means that the temporary host's main disk is
probably not in the best condition. Oops!

Fortunately that disk is split into two 500GB partitions, so I was able to copy
the data by storing the temporary file in another location. To gain confidence
that I wasn't getting any corrupt data, I did a checksum on the original disk
and the temporary image file:

~~~~
md5sum /dev/sdb
md5sum /home/potato/backup-disk-image.img
~~~~

Data moved, it was time to resize the partitions and filesystems. This is where
I hit another issue: the old disk was using the MBR partitioning scheme, which
doesn't support disks over 2TiB. I needed to change to the GPT scheme before
resizing things.

I ran `fdisk` to check the MBR partition scheme, and `gdisk` to convert it to GPT:

~~~~
$ fdisk /dev/sdb
[...]
Device     Boot   Start       End   Sectors   Size Id Type
/dev/sda1  *       2048    999423    997376   487M 83 Linux
/dev/sda2       1001470 625141759 624140290 297.6G  5 Extended
/dev/sda5       1001472 625141759 624140288 297.6G 83 Linux

$ gdisk /dev/sdb
[...]
Found invalid GPT and valid MBR; converting MBR to GPT format
in memory. THIS OPERATION IS POTENTIALLY DESTRUCTIVE! Exit by
typing 'q' if you don't want to convert your MBR partitions
to GPT format!
[...]
Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048          999423   487.0 MiB   8300  Linux filesystem
   5         1001472       625141759   297.6 GiB   8300  Linux filesystem

Command (? for help): w
~~~~

The conversion seemed to go without any issues, so I moved on to extending the
data partition and its filesystem. Since I'm using Debian's encrypted LVM
setup, this has some extra steps:

~~~~
cryptsetup open /dev/sdb5 luks-backups
pvresize /dev/mapper/luks-backups
pvdisplay
lvscan
lvresize -l +100%FREE /dev/backups-vg/root
mount /dev/mapper/backups--vg-root /mnt/backups
e2fsck -f /dev/mapper/backups--vg-root
resize2fs /dev/mapper/backups--vg-root
~~~~

After this, I was able to mount the data partition and everything looked fine,
so I thought I was done. After resizing the partitions, I installed the 4TB
disk on the backup server, and tried to boot it. It didn't work.


## Fixing GRUB and the boot partitions

This is where I spent most of the time. I did a bunch of things wrong, and I'm
not even sure what all of them were, and how I fixed them. All these fixes were
done using the rescue mode in debian's installer image loaded onto a USB stick.

The backup server does not support UEFI; it only supports BIOS. When using a
BIOS/GPT configuration, [you need an additional BIOS boot
partition][arch-bios]. After some failed attempts, I ended up with the
following partition scheme:

~~~~
Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048            6143   2.0 MiB     EF02  BIOS boot partition
   2            6144         1001471   486.0 MiB   8300  Linux filesystem
   5         1001472      7814035455   3.6 TiB     8300  Linux filesystem
~~~~

sda1 is a filesystemless partition with the `core.img` contents, sda2 is an
unencrypted ext2 `/boot` partition, and sda5 is the LUKS2/LVM container, which
contains the rest of the operating system and user data.

I chose 2MiB because at some point I tried 1 MiB but got a "No GRUB drive for
/dev/sda2" during `grub-install`. Maybe it was something else that was screwed
up, I don't know.

In this process I ended up erasing `/boot`, so I had to rebuild it from
scratch. I formatted `/dev/sda2` using ext2 (for no good reason other than it
was what it was before) and mounted it on `/boot`. Running `apt reinstall
linux-image-5.18.0-2-amd64` got me the `config-*`, `initrd-*` and `vmlinuz-*`
files back. Running `grub-install /dev/sda` did whatever to needed to do to the
BIOS boot partition and the MBR sector ([GRUB's wikipedia article][grub-wp]
helped a lot in understanding what was going on).

Even if I hadn't destroyed the boot, grub needed to be updated because it had
some references to the old disk's UUID. Not clue if a `update-grub` would be
enough, or what.

At this point I got past GRUB and into Debian, but it failed to boot. This was
an easy fix: I had to edit `/etc/fstab` to update the `/boot` partition's UUID.

Later I realized that the `/etc/fstab` shenanigans caused a lot of confusion
during my attempts at fixing the problem. Debian's installer automatically
mounted `sda5` and asked if I wanted to mount the `/boot` partition, to which I
said yes, but it didn't actually mount anything; it  was using the old disk's
UUID from `/etc/fstab` instead of the actual partition. Trusting that it had
worked, I more than once ended up generating grub files on the wrong partition.
Always check `mount`, I guess.


## Done!

Finally, it booted. I still had to add the network interface to
`/etc/network/interfaces`, I have no idea why it worked before, but things seem
fine. Also, the case no longer closes completely, as the new disk is way
thicker than the old one and there's not enough clearance, but I don't even
care anymore.

The daily backups are now running again, I've checked their integrity using
`restic check`, and there's tons of free space. Hopefully I don't have to mess
with this system again soon.


<aside markdown="1">
  If you enjoy my work, consider sponsoring me so I can keep on doing this full
  time: <https://github.com/sponsors/hugopeixoto>
</aside>


[arch-bios]: https://wiki.archlinux.org/title/GRUB#GUID_Partition_Table_(GPT)_specific_instructions
[grub-wp]: https://en.wikipedia.org/wiki/GNU_GRUB#Startup_on_systems_using_BIOS_firmware
[acer]: https://en.wikipedia.org/wiki/Acer_AspireRevo
