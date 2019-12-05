# kumobar
lemonbar support script

This script was from Peter Hessler via Pamela Mosiejczuk. I believe he
got it from elsewhere.

I'm slowly customizing it to work for me and to be less opaque to read.

Current advantages over other versions I've seen:

* Factored out the magic color strings
* Factored out the network interfaces into a variable for one easy change
* Added support for a trunk interface and detection of wired interface usage
* Battery status is split into four color categories for each 25% of battery
* Touching ~/.newbar will get the script to re-exec itself. Useful for development.
