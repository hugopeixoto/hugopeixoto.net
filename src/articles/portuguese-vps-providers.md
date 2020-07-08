---
kind: article
title: An encounter with portuguese VPS providers
created_at: 2020-07-08
---

I'm working on a few portuguese projects
([Mentorados](http://mentor.alumniei.pt/), [Make or
Break](https://makeorbreak.io/), [Porto Codes](https://porto.codes), [Conversas
em Código](https://conversas.porto.codes/)). Most of these require some sort of
web hosting.

I wondered if I could find a portuguese VPS provider to host all of these. This
way, data would be kept in national datacenters. Also, I kind of wanted to see
what national offers exist. I asked around and decided to try
[dominios.pt](dominios.pt) and [PTisp](ptisp.pt).

I initially wanted to go with PTisp, but they are kind of expensive: 4GB
ram/2vCPU/100GB disk for €28/month. dominios.pt was half the price for similar
specs: 4GB ram/2vCPU/40GB disk for €12/month. Contrast with Digital Ocean: 4GB
ram/2vCPU/80GB disk for ~€18.

This turned out to be a weirder day than I was expecting.

## dominios.pt

When ordering from dominios.pt, I got to pick an operating system. CentOS was
the default option, but I changed to Debian 10 buster. I also had to specify
the hostname.

Mainstream providers like Digital Ocean or AWS usually take a couple of minutes
to get your instance running. After 10 minutes, the service status was still
showing as "pending". Taking this long, I started assuming that the
provisioning would be done manually, and might not be ready for a couple of
hours.

After an hour or so, I returned to the dashboard and noticed that it had
changed to "active", but I hadn't received any emails yet with login
credentials. The dashboard listed the instance as running, but it showed the
attribute "CD/DVD Disc Image File" as "CentOS 7 X86 64 Minimal 1611" (instead
of debian).

There was also a [web console thing](https://github.com/novnc/noVNC) to connect
to the instance. I tried it, and was greeted with CentOS install screen. I
changed the disk image to "Debian 10 buster" and restarted the system. Debian's
install screen showed up.

At this point I wondered why they'd bother to ask for an operating system and a
hostname if they were going to hand me a clean VPS. I understand that some
folks might want to install things manually, but handing users an empty VM with
no instructions isn't the best experience.

Most of the steps in debian installation were straightforward, but it was
unable to automatically configure the network via DHCP. I had to set it up
manually. The IP, mask, and gateway were available in the dashboard, so this
was easy to find. They didn't mention any DNS servers, though. I accepted the
default value and continued the installation. Why would they leave the OS
installation to the user and not even have DHCP configured? This was all weird.

Turns out that the DNS setting didn't work. When trying to connect to an apt
mirror, it failed. I assumed it was because the DNS server didn't exist, so I
went back and changed it to google's DNS to see if it worked.

When I got back to the apt mirror step, the VM restarted. Thinking that I may
have accidentally rebooted it, I went through the process again. Setting up
passwords, partitions, network, etc. Then, it rebooted again. I started
suspecting that something was going on. I connected to the VNC again and
waited. That's when someone else started going through the installation
process!

I saw them setting up the network manually (and using google's DNS resolver),
setting up partitions manually, setting the hostname, setting the root password
to something kind of short (8 characters?), creating a non root user, and
installing ssh. They also decided to install a graphical environment and a
print server.

A few minutes after finishing the installation, I got an email from them saying
that my server was ready. It included the server's IP address and the
credentials for the non-root account. They didn't send the root password,
though.

I kind of expected that the initial provisioning of the VPS would be manual,
but I didn't expect them to set up the OS manually. Why don't they use a preset
image? Wouldn't it be faster for everyone?

I'm aware that [the cloud is someone else's
computer](https://fsfe.org/activities/nocloud/nocloud.en.html), but watching
someone else connecting via VNC and setting it up for you kind of puts that
right in your face. This completely undermines any trust I had in them to hold
my data. I'm not planning on keeping this server.

## PTisp

After the dominios.pt madness, I decided to try PTisp, even with pricing in
mind. They also asked me for the operating system and hostname. It defaulted to
CentOS, but I changed it to Debian.

Right after payment, I got an email with access information. It seems that
PTisp doesn't set things up manually. The email didn't look right, though. It
contained the following:

~~~~
Interface Internet - eth0: 
=============================
IP/Host:
Endereços IP Secundários:  
Hostname: [CENSORED]

SSH v2:
=============================
IP/Host:
Login: hugo.peixoto@gmail.com
Password: [CENSORED]
Porta: 22
~~~~

Note the lack of IP/Host in the first two sections. Also, what's up with the
ssh login being my email address?

I got the IP address from their dashboard and tried connecting via SSH. Using
the provided username didn't work, which was not very surprising. Changing the
username to `root` worked, though. There were some hiccups, but it seemed way
better than the experience with dominios.pt.

I connected via ssh, and tried updating the package repository:

~~~~
[root@hostname ~]# apt update
-bash: apt: command not found
[root@hostname ~]# apt-get update
-bash: apt-get: command not found
~~~~

This is weird, why isn't `apt` installed?

~~~~
[root@hostname ~]# cat /etc/centos-release
CentOS Linux release 7.8.2003 (Core)
~~~~

They installed CentOS.

Their dashboard allows me to reinstall the operating system, so I installed
Debian 10. After logging in, I tried to update the package repository, and was
noticed something weird:

~~~~
root@hostname:~# apt update
Hit:1 http://security.debian.org/debian-security buster/updates InRelease
Hit:2 http://mirror.yandex.ru/debian buster InRelease
Reading package lists... Done
Building dependency tree
Reading state information... Done
79 packages can be upgraded. Run 'apt list --upgradable' to see them.

root@hostname:~# cat /etc/apt/sources.list
deb http://mirror.yandex.ru/debian buster main contrib
deb-src http://mirror.yandex.ru/debian buster main contrib

deb http://security.debian.org/debian-security buster/updates main contrib
deb-src http://security.debian.org/debian-security buster/updates main contrib
~~~~

Why would they use `mirror.yandex.ru`? It's not listed on the [authoritative
list of debian mirrors](https://www.debian.org/mirror/list), and this list
contains a [portuguese mirror hosted by
PTisp](http://mirrors.ptisp.pt/debian/).

After a chat with their support team, they told me that the images they use
come bundled with the panel software. They're using [VMmanager from
ISPsystem](https://www.ispsystem.com/software/vmmanager). ISPsystem is based in
Russia, which explains their mirror choice. PTisp lets me mount an iso image,
so I could install debian from scratch if I wanted, so I guess this is fine?


## Conclusions

I'm not planning on keeping the dominios.pt server. Their system doesn't feel
very mature.

I may keep the PTisp server. They have prebuilt images, and don't require
manual intervention. I reported the issues I found and got an answer within a
few minutes.

Reading about ISPsystem left me wondering if there's any portuguese provider
that relies purely on free software. I'll have to look it up.

The next thing I want to do is install [dokku](https://github.com/dokku/dokku)
and see if I can deploy some web apps.
