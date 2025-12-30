# bazzite-atty &nbsp; [![bluebuild build badge](https://github.com/atty303/bazzite-atty/actions/workflows/build.yml/badge.svg)](https://github.com/atty303/bazzite-atty/actions/workflows/build.yml)

This is my personal Bazzite image for my personal use.

- 1Password: Flatpak/AppImage doesn't support browser, CLI and system authentication integrations.
- Howdy: It is a PAM module. So it needs to be installed to the system.

## Configuration

### Howdy

Set the device path for the IR camera.

```bash
sudo howdy set device_path /dev/video2
```

Test and confirm that a monochrome image is displayed.

```bash
sudo howdy test
```

Scan and register your face. It is recommended to run this several times from different angles to register multiple models.

```bash
sudo howdy add
```

Test again to confirm that your face is recognized.

```bash
sudo howdy test
```

Check the current state of authselect.

```bash
$ authselect current
Profile ID: local
Enabled features:
- with-silent-lastlog
- with-mdns4
```

Create a new profile based on the currently selected profile.

```bash
sudo authselect create-profile local -b local
```

Add `pam_howdy.so` before the line with `pam_fprintd.so` in `system-auth`.

```
# /etc/authselect/custom/local/system-auth
auth sufficient pam_howdy.so
```

Switch to and apply the created profile.

```bash
sudo authselect select custom/local with-silent-lastlog with-mdns4
```

Test polkit authentication to confirm that face recognition works.

```bash
pkexec id
```

## Installation

> [!WARNING]  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First, rebase to the unsigned image to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/atty303/bazzite-atty:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/atty303/bazzite-atty:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/atty303/bazzite-atty
```

## Local Builds

### Build

If you don't care about the details of the template, you can run the `build` command.

```bash
mise run build
```

This will template out the file and build with `docker`, `podman`, or `buildah`.


### Inspect Image

```nushell
let mnt = (podman unshare podman image mount localhost/bazzite-atty)
podman unshare yazi $mnt
podman unshare umount $mnt
```

### Switch

With the switch command, you can build and boot an image locally using an `oci-archive` tarball. The `switch` command can be run as a normal user and will only ask for `sudo` permissions when moving the archive into `/etc/bluebuild`.

```bash
mise run switch
```

You can initiate an immediate restart by adding the `--reboot/-r` option.
