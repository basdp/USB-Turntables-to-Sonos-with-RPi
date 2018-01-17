# Sonos support for USB Turntables with Raspberry Pi
This is a quick guide on how to use a Raspberry Pi to play modern turntables with USB output wirelessly on a Sonos installation. This guide is focussed on this usecase, but might also be used to stream to other speakers as we are going to create an MP3 stream which is playable by virtually anything that can stream audio.

## 1. Prepare Raspbian on an SD card
First we need a clean installation of Raspbian on an SD card. As we do not need graphics or anything special, we can use Raspbian Lite. Also, we do not need much disk space, probably anything from 2GB and up is good. After installation I'm using only 1.4GB of my SD card (and I even have some debugging stuff installed that is out of scope for this guide).

For my installation, I have used the `November 2017 Stretch Lite` release of Raspbian. You might try out a newer version, but this is not tested.

Download Raspbian from: https://www.raspberrypi.org/downloads/raspbian/

For instructions on how to get this on an SD card, see https://www.raspberrypi.org/documentation/installation/installing-images/README.md

## 2. Enable SSH before booting
Because we are going to use the Raspberry Pi headless (without a display) and without keyboard attached, we need a way to control the device. Luckily we can enable SSH by adding an empty file called `ssh` to the root of the SD card. This will enable SSH for us automatically. If you are using the Ethernet port on the Raspberry Pi, networking and SSH should work out of the box with DHCP. If you want to use the Raspberry Pi with Wi-Fi, see this guide on how to do this: https://www.raspberrypi-spy.co.uk/2017/04/manually-setting-up-pi-wifi-using-wpa_supplicant-conf/
_I have not tested Wi-Fi, but if your wireless network is good enough, there is no reason streaming should not work._

You can now connect to your Raspberry Pi using SSH (Use putty on Windows and `ssh pi@ipaddress` on Unix). I use the tool 'IP Scanner' for MacOS to find the IP address of the Raspberry Pi.

## 3. Connect the USB Turntable to the Raspberry Pi
Now, connect the turntable to the Raspberry Pi, using USB. You can use the command `arecord -l` to check if your device has been detected. Mine shows this:
```
pi@raspberrypi:~ $ arecord -l
**** List of CAPTURE Hardware Devices ****
card 1: CODEC [USB AUDIO  CODEC], device 0: USB Audio [USB Audio]
  Subdevices: 0/1
  Subdevice #0: subdevice #0
```
Make a note of the card number, `1` in my case. This is probably the same for you, but if it differs, you may need to remember it and change accordingly in the following steps.

## 4. Fix volume issues
As most USB turntables do not have hardware volume control, and the input volume is stuck on roughly half of what it should be, we need to add a software volume control.
Create the file `/etc/asound.conf` and edit it to add the following contents:
```
pcm.dmic_hw {
    type hw
    card 1
    channels 2
    format S16_LE
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
        card 1
    }
    min_dB -5.0
    max_dB 20.0
}
```
Next, run this command to refresh the alsa state and also show VU Meters to test the input volume:

```arecord -D dmic_sv -r 44100 -f S16_LE -c 2 --vumeter=stereo /dev/null```

As you might notice, the volume is way too low. You can use `alsamixer` to change the volume. Press `F6` to select the USB Turntable device, and press `TAB` untill you see the boost slider. I have it set to `65` on my setup, but you might try out. Make sure you are not turning it up too high, or your sound quality might degrade due to clipping.

## 5. Install Darkice
Run the following commands:
```sh
sudo apt-get install libmp3lame0 libtwolame0
wget https://github.com/basdp/USB-Turntables-to-Sonos-with-RPi/raw/master/darkice_1.0.1-999_mp3%2B1_armhf.deb
# The following command will probably give some missing dependency errors, but that will be corrected with the next command
sudo dpkg -i darkice_1.0.1-999_mp3+1_armhf.deb
sudo apt-get install -f
```

## 6. Install Icecast
```sh
sudo apt-get install icecast2
```
Select `Yes` to configure Icecast. You can leave everything as default, but if you change the password, make sure you change the password in the configuration in the next steps.

## 7. Configure Darkice
Darkice is the software that is recording from the USB device and encoding that into MP3. To configure it, create or edit the file `/etc/darkice.cfg`, and put this in:
```ini
[general]
duration        = 0      # duration in s, 0 forever
bufferSecs      = 1      # buffer, in seconds
reconnect       = yes    # reconnect if disconnected

[input]
device          = dmic_sv # Soundcard device for the audio input
sampleRate      = 44100   # sample rate 11025, 22050 or 44100
bitsPerSample   = 16      # bits
channel         = 2       # 2 = stereo

[icecast2-0]
bitrateMode     = cbr       # constant bit rate ('cbr' constant, 'abr' average)
#quality         = 1.0       # 1.0 is best quality (use only with vbr)
format          = mp3       # format. Choose 'vorbis' for OGG Vorbis
bitrate         = 320       # bitrate
server          = localhost # or IP
port            = 8000      # port for IceCast2 access
password        = raspberry    # source password for the IceCast2 server
mountPoint      = turntable.mp3  # mount point on the IceCast2 server .mp3 or .ogg
name            = Turntable
highpass        = 18
lowpass         = 20000
description	= Turntable
```
For more information about this file and the parameters you can change, see http://manpages.ubuntu.com/manpages/zesty/man5/darkice.cfg.5.html

## 8. Autostart Darkice
```bash
wget https://raw.githubusercontent.com/basdp/USB-Turntables-to-Sonos-with-RPi/master/init.d-darkice
sudo mv init.d-darkice /etc/init.d/darkice
sudo chmod 777 /etc/init.d/darkice
sudo update-rc.d darkice defaults
```

## 9. Check if steaming is working
Reboot the Raspberry Pi, to check if everything is set up correctly and because we have changed some configuration files and ensure Darkice is running. 

Now open your browser, and go to `http://ipaddress:8000` (default icecast2 port). You should see a Mountpoint `Mount Point /turntable.mp3` there. If not, go back and check if you did everything as described. 
Right click the M3U link (upper right), and copy the link address. This is your steam URL. You can open this in iTunes, VLC, your browser, or about any other audio client that supports streaming.

## 10. Add the stream to your Sonos installation
Open the Sonos app on your desktop (this _won't_ work on mobile!). Go to `Manage` > `Add Radio Station...` and paste your stream URL. You can choose any name you want.
To play the stream on your Sonos, go to `Radio by TuneIn` > `My Radio Stations`. Your stream should show up there! Right-click to add to your favorites if you want! :-)
You _can_ start playing from mobile devices, you just can't add a network stream on them.
