# Sonos support for USB Turntables with Raspberry Pi
This is a quick guide on how to use a Raspberry Pi to play modern turntables with USB output wirelessly on a Sonos installation. This guide is focussed on this usecase, but might also be used to stream to other speakers as we are going to create an MP3 stream which is playable by virtually anything that can stream audio.

## 1. Prepare Raspbian on an SD card
First we need a clean installation of Raspbian on an SD card. As we do not need graphics or anything special, we can use Raspbian Lite. Also, we do not need much disk space, probably anything from 2GB and up is good. After installation I'm using only 1.5GB of my SD card.

For my installation, I have used the `Buster` release of Raspbian OS Lite (September 2022). You might try out a newer version, but this is not tested.

Install Raspberry Pi OS Lite (64-bit) via the Raspberry Pi Imager https://www.raspberrypi.com/software/

Click the Gear icon for advanced options
 - Enable SSH, (Because we are going to use the Raspberry Pi headless (without a display) and without keyboard attached, we need a way to control the device.)
 - Set the hostname to `vinyl`,
 - Set the userid/password to something you want.

## OPTION 1: automated install
Plug in your Raspberry Pi, ssh to it, and run the following

```shell
smorton@homepc:~$ ssh vinyl@vinyl.local
vinyl@vinyl:~ $ cd /tmp && wget https://github.com/basdp/USB-Turntables-to-Sonos-with-RPi/archive/master.zip && unzip master.zip && USB-Turntables-to-Sonos-with-RPi-master/scripts/install.sh
```

Skip ahead to "Check if steaming is working".

## OPTION 2: manual install

## 2. Connect the USB Turntable to the Raspberry Pi
Now, connect the turntable to the Raspberry Pi, using USB. You can use the command `arecord -l` to check if your device has been detected. Mine shows this:
```
vinyl@vinyl:~ $ arecord -l
**** List of CAPTURE Hardware Devices ****
card 1: CODEC [USB AUDIO  CODEC], device 0: USB Audio [USB Audio]
  Subdevices: 0/1
  Subdevice #0: subdevice #0
```
Make a note of the card number `1` in my case ("`card: 1`") or even better the name ("CODEC" above). This is probably the same for you, but if it differs, you may need to remember it and change accordingly in the following steps. You will usit in the `asound.conf` file below.

## 3. Configure ALSA and fix volume issues
ALSA is the lowest-level linux sound subsystem. We're configuring the input so that darkice can use it.

As most USB turntables do not have hardware volume control, and the input volume is stuck on roughly half of what it should be, we need to add a software volume control.
Create the file [/etc/asound.conf](files/etc/asound.conf) and edit it to add the following contents:

```yaml
pcm.dmic_hw {
    type hw
#    card 1
#       For some reason, the card number can jump around. But this will get it by name
    card CODEC
    channels 2
#    format S16_LE # Use this if "format dat" doesn't work. Only difference is S16_LE = 44.1 kHz sampling vs dat = 48 kHz
    format dat
}
pcm.dmic_mm {
    type mmap_emul
    slave.pcm dmic_hw
}
pcm.dmic_sv {
    type softvol
    slave.pcm dmic_hw
    control {
        name "Boost Capture Volume"
#        card 1
#       For some reason, the card number can jump around. But this will get it by name
        card CODEC
    }
    min_dB -5.0
    max_dB 20.0
}
```
Next, run this command to refresh the alsa state and also show VU Meters to test the input volume:

```arecord -D dmic_sv -r 48000 -f dat -c 2 --vumeter=stereo /dev/null```

(It will show zero volume until you play something on your record player.)

You might notice, the volume is way too low. If so, you can use `alsamixer` to change the volume. Press `F6` to select the USB Turntable device, and press `TAB` untill you see the boost slider. I have it set to `65` on my setup, but you might try out. Make sure you are not turning it up too high, or your sound quality might degrade due to clipping.

## 4. Install Darkice and Icecast
Run the following commands:
```sh
sudo apt-get update
sudo apt-get install -y darkice icecast2
```
Select `Yes` to configure Icecast. You can leave everything as default, but if you change the password, make sure you change the password in the configuration in the next steps.

## 5. Configure Darkice
Darkice is the software that is recording from the USB device and encoding that into MP3. To configure it, create or edit the file [/etc/darkice.cfg](files/etc/darkice.cfg), and put this in:
```ini
# this section describes general aspects of the live streaming session
[general]
duration        = 0         # duration of encoding, in seconds. 0 means forever
bufferSecs      = 1         # size of internal slip buffer, in seconds
reconnect       = yes       # reconnect to the server(s) if disconnected
realtime        = yes       # run the encoder with POSIX realtime priority (default==yes)
rtprio          = 4         # scheduling priority for the realtime threads (default==4)

# this section describes the audio input that will be streamed
[input]
device          = dmic_sv    # OSS DSP soundcard device for the audio input
sampleRate      = 48000     # other settings have crackling audo, esp. 44100
bitsPerSample   = 16        # bits per sample. try 16
channel         = 2         # channels. 1 = mono, 2 = stereo

# this section describes a streaming connection to an IceCast2 server
# there may be up to 8 of these sections, named [icecast2-0] ... [icecast2-7]
# these can be mixed with [icecast-x] and [shoutcast-x] sections
[icecast2-0]
bitrateMode     = cbr
format          = mp3
bitrate         = 320
server          = vinyl
port            = 8000
mountPoint      = turntable.mp3
name            = Turntable
description     = Music from our record player
#highpass        = 18
#lowpass         = 20000
url             = http://vinyl.local:8080/
genre           = vinyl
public          = no
password        = hackme   # or whatever you set your icecast2 password to

```
For more information about this file and the parameters you can change, see [the darkice.cfg manpage](http://manpages.ubuntu.com/manpages/zesty/man5/darkice.cfg.5.html).

## 8. Autostart Darkice and IceCast
Darkice and icecast use old-fashioned init.d controls. Let's just modernize them while we're at it.

```bash
# Remove old-fashioned init.d controls
sudo update-rc.d darkice remove
sudo update-rc.d icecast2 remove
```

Copy the code below to [/etc/systemd/system/darkice.service](files/etc/systemd/system/darkice.service) and [/etc/systemd/system/icecast2.service](files/etc/systemd/system/icecast2.service).
Then run

```bash
sudo systemctl enable icecast2
sudo systemctl enable darkice
```

*darkice.service*
```ini
[Unit]
Description=DarkIce Icecast Network Audio Streamer
After=icecast.target

[Service]
Type=simple
ExecStart=/usr/bin/darkice -c /etc/darkice.cfg
ExecReload=/bin/kill -HUP $MAINPID
User=root
Group=root
#WorkingDirectory=/usr/share/icecast2/
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

*icecast2.service*
```ini
[Unit]
Description=Icecast Network Audio Streaming Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/icecast2 -c /etc/icecast2/icecast.xml
ExecReload=/bin/kill -HUP $MAINPID
User=icecast2
Group=icecast
#WorkingDirectory=/usr/share/icecast2/
Restart=always

[Install]
WantedBy=multi-user.target
```

## 7. Check if steaming is working
Reboot the Raspberry Pi, to check if everything is set up correctly and because we have changed some configuration files and ensure Darkice is running. 

Now open your browser, and go to `http://vinyl.local:8000` (default icecast2 port). You should see a Mountpoint `Mount Point /turntable.mp3` there. If not, go back and check if you did everything as described. 
Right click the M3U link (upper right), and copy the link address. This is your steam URL. You can open this in iTunes, VLC, your browser, or about any other audio client that supports streaming.

## 8. Add the stream to your Sonos installation
Open the Sonos app on your desktop (this _won't_ work on mobile). Go to `Manage` > `Add Radio Station...` and paste your stream URL. You can choose any name you want.
To play the stream on your Sonos, go to `Radio by TuneIn` > `My Radio Stations`. Your stream should show up there! Right-click to add to your favorites if you want! :-)
You _can_ start playing from mobile devices, you just can't add a network stream on them.

## 9. Speed up boot time (optional)

To speed up your Raspberry Pi's boot time you can
- Give your device a static IP address. (You will need to also assign a static IP to your device via your home router but there's a lot of speed to be gained here.)
- Disable unnecessary system services.

This is left as an exercise to the reader, but there are various code snippets in [fasterboot.sh](scripts/fasterboot.sh) to look at as well as various links in [technical notes and references](technical.md).

## 10. Further reading.
See also 
 - [technical notes and references](technical.md)
