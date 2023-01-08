# Technical Notes

Q: Why mp3 CBR 320 bps not FLAC or something else lossless?

A: FLAC is arguably only margianlly perceptibally better than mp3 320 bps. And mp3 is easy on linux. IceCast doesn't suppor FLAC natively so it would be flac-over-ogg. (Feel free to give FLAC/ogg a try and update the documentation if it works.)

Q: Why mp3 and not AAC?

A: AAC is known for being better at low bitrates. So for internet streaming or file storage you get better sound for the same bandwidth. But within your home network, 320 bps mp3 is very reasonable bandwidth. As support for mp3 is much easier on linux than support for AAC, 320 bps mp3 is makes more sense.


# References

## Raspberry Pi SONOS Vinyl HOWTOs

### General
- https://www.instructables.com/Add-Aux-to-Sonos-Using-Raspberry-Pi/
- https://www.stevegattuso.me/wiki/projects/sonos-vinyl.html

### USB turntable-specific
- https://github.com/coreyk/darkice-libaacplus-rpi-guide (This person goes to all the trouble of compiling `libaacplus` but then doesn't use it. (???))
- https://github.com/basdp/USB-Turntables-to-Sonos-with-RPi (This repo is forked from this one.)


## Linux Reference

- https://singleboardbytes.com/637/how-to-fast-boot-raspberry-pi.htm
- https://www.linux.com/topic/desktop/cleaning-your-linux-startup-process/
- https://sleeplessbeastie.eu/2022/06/01/how-to-disable-onboard-wifi-and-bluetooth-on-raspberry-pi-4/
- https://raspians.com/how-to-fast-boot-raspberry-pi/
- https://www.raspberrypi.com/documentation/computers/config_txt.html


- https://manpages.ubuntu.com/manpages/kinetic/en/man5/darkice.cfg.5.html

- https://alsa.opensrc.org/Asoundrc
- https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture
- https://developer.sonos.com/build/content-service-add-features/supported-audio-formats/
- https://www.reddit.com/r/linux/comments/coi4dt/a_complete_guide_of_and_debunking_of_audio_on/

## Audio Reference
- https://stackoverflow.com/questions/11489300/why-is-flac-streaming-over-http-done-with-ogg-encapsulation-instead-of-natively

