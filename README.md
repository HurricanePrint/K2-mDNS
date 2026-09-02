# K2-mDNS

A small mDNS responder for K2 printers that broadcasts a local hostname so the printer can be discovered on the network as something like:

- http://myprinter.local
- http://k2plus.local

For example you will be able to access Fluidd at http://k2plus.local:4408

If you don't have router access to put your printer on a static ip, this is a perfect fix as the printer will always be accessable from a permanent address even when the internal ip changes.

## Install methods

You can get the project onto the printer in either of these ways:

1. Git clone
2. Copy the release folder to the printer using Fluid, then run the install script over SSH

## Option 1: Install from Git

From the printer or a connected shell:

```bash
git clone https://github.com/<your-user>/K2-mDNS.git
cd K2-mDNS
sh install-mdns.sh
```

Then follow the prompt to enter a hostname. If you press Enter without typing anything, it will use the default hostname:

```bash
k2plus
```

## Option 2: Install from a release folder via Fluid

1. Copy the project folder or release folder to the printer using Fluid.
2. Open an SSH session to the printer.
3. Run:

```bash
cd mnt/UDISK/printer_data/config/K2-mDNS
sh install-mdns.sh
```

4. Enter the hostname when prompted.

## Notes

- The hostname is entered during installation and stored in the responder script.
- The default hostname is `k2plus`.
- If the printer does not show up immediately, make sure multicast is enabled on the network and the service is running.

## Useful commands

Check service status:

```bash
/etc/init.d/S55mdns-responder status
```

Start service:

```bash
/etc/init.d/S55mdns-responder start
```

Stop service:

```bash
/etc/init.d/S55mdns-responder stop
```

Restart service:

```bash
/etc/init.d/S55mdns-responder restart
```