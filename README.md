# mymacnix 

The purpose of this repository is to document my exploration of the way to set
up Nix for my MacOS system on both my MacBook (personal) and my Mac Mini
(family shared computer).


## Introduction

I first learnt about Nix from watching tech videos on YouTube and that led me
to learning about Nix, NixOS, nix-darwin, and the *EXPERIMENTAL* Flakes.  The
following are some of the important I had read before I decided on the current
way of setting up Nix on my MacOS systems:

* [Official Nix site](https://nixos.org/)
* [How to learn Nix](https://ianthehenry.com/posts/how-to-learn-nix/)
* [Determinate Systems](https://determinate.systems/oss/)
* [Zero to Nix](https://zero-to-nix.com/)
* [Flakes - NixOS Wiki](https://nixos.wiki/wiki/Flakes)
* [Flakes aren't real and cannot hurt you: a guide to using Nix flakes the
non-flake way](https://jade.fyi/blog/flakes-arent-real/)
* [Summary of Nix Flakes vs original
Nix](https://zimbatm.com/notes/summary-of-nix-flakes-vs-original-nix)
* [Nix Flakes is an experiment that did too much at
once…](https://samuel.dionne-riel.com/blog/2023/09/06/flakes-is-an-experiment-that-did-too-much-at-once.html)
* [nix-darwin](https://github.com/LnL7/nix-darwin)
* [Declarative macOS Configuration Using nix-darwin And
home-manager](https://xyno.space/post/nix-darwin-introduction)

My goals of my Nix journey:

* Study how easy it will be to reproduce a macOS-based setup on another brand
new machine - especially in terms of setting up non-Microsoft tools.
* Document the learning points during my journey.
* Add relevant tools or script that I believe would help create reproducible
macOS setup


## Phase 1: Experimenting on MacOS VMs 

Before I started messing with my actual MacOS setup, I first setup MacOS VMs to
experiment.  MacOS VMs can be setup via [UTM - Securely run operating systems
on your Mac](https://mac.getutm.app/).  

After quite After quite a few tests, I finally decided to start setting up Nix
on my MacBook with the "[standard](https://nixos.org/download/)" way of setting
up Nix on MacOS.  This
[page](https://nixos.org/manual/nix/stable/installation/installing-binary#macos-installation)
documents what actually occurs on your MacOS system during the setup process.

## Phase 2: Nix and its versions

Getting the version of `Nix` installed

```
nix --version
```

Getting the list of subscribed channels:

```
sudo nix-channel --list
```

Channels are something like Linux Debian apt sources - they point to where
packages can be downloaded and installed.

The default subscribed channel is `nixpkgs` which by default points to
`https://nixos.org/channels/nixpkgs-unstable`

When you install `Nix` via the "official"
[nixos install method](https://nixos.org/manual/nix/stable/installation/installing-binary#macos-installation),
it uses the latest version you can find in the [nix releases
folder](https://releases.nixos.org/?prefix=nix/) here.

But if you subsequently execute the command `nix upgrade-nix`, you may likely
downgrade your `Nix` version.  You can find out the version of the `Nix` you are
"upgrading" to before running it by executing either of the following commands:

```
nix-env -qaA nixpkgs.nix
```

or

```
sudo nix upgrade-nix --dry-run
```

Follow these instructions to [install a specific version of
nix](https://nixos.org/manual/nix/stable/installation/installing-binary#installing-a-pinned-nix-version-from-a-url).


To find the actual latest version of `Nix` (outside of `nixpkgs`):

```
sudo nix-env --query nix 2>/dev/null
```

If you had accidentally ran the command:

```
sudo nix upgrade-nix
```

that would result in an older version of `Nix` being installed, you can force
`Nix` back to the latest version by running the following command:

```
sudo nix upgrade-nix --nix-store-paths-url https://releases.nixos.org/nix/$(nix-env --query nix)/fallback-paths.nix
```

### Why the messy Nix version issue

This was discussed in the [Nix installer bug
report](https://github.com/DeterminateSystems/nix-installer/issues/744) - see
grahamc's comment on 26 Nov 2023 for context.  It seems that the `nixpkgs`
maintenance team is "responsible" for deciding on the "safe" version of `Nix` to
use when an upgrade is executed.

I am still not yet decided which is "safe" to use - but since the purpose of
`Nix` is to be a package manager, **then it may be best to start the experiment
with using the `nixpkgs` team's recommendation of the safe version to use**.

### Uninstalling Nix

There is a series of complex steps for [uninstalling Nix from
MacOS](https://nixos.org/manual/nix/stable/installation/uninstall#macos).
Because these steps require reboots and messing around with MacOS's daemons, I
created an uninstall.sh script to automate this process so that it is easier to
uninstall `Nix` correctly.

## Phase 3: Decision time 

### Flakes 

I first experimented with flakes because it was a very popular recommendation
amongst many Nix enthusiasts.  And it was also recommended by [Determinate
Systems](https://determinate.systems), a company cofounded by [Eelco
Dolstra](https://github.com/edolstra) - the inventor of Nix.

I decided against using flakes for starting my Nix journey for the following
reasons:

* I felt that I could transition to flakes easily later
* After installing the Determinate Systems installer, I tried to uninstall. But
I found that there are some leftover folders and services that were not removed
after uninstall.
* The articles arguing against flakes
* Parts of the Nix development community seem to be against it because of the
lack of proper process in the manner it was adopted

### nix-darwin 

I have not delved too much into nix-darwin except to confirm that it does not
require flakes.  So, it is likely I would proceed with playing around with this
project to see how it helps in reproducing a macOS setup with a "declarative
system approach to macOS".

## Phase 4: Creating my own install tools

I created auto-install scripts to install `Nix` and `nix-darwin` with minimal 
user intervention.  These tools can now be installed by executing this command 
in the Terminal window:

```
sh <(curl -L https://gitlab.com/khsoh/mymacnix/-/raw/main/nix-autoinstall) [--install=nixonly] [--branch=<git-feature-branch>]
```

or if using the github repo (which is a mirror of the gitlab version):

```
sh <(curl -L https://raw.githubusercontent.com/khsoh/mymacnix/main/nix-autoinstall) [--install=nixonly] [--branch=<git-feature-branch>]
```


The `--branch` option can be use to test feature branches.  The `--install` 
option can be used to stop to auto-install process at a Nix-only install

## INTERLUDE AND UPDATE ON 12 JUN 2024

An important update on the learning journey.  I discovered this important site
[nix.dev](https://nix.dev) by the [Nix documentation team](https://nixos.org/community/teams/documentation) to guide newbies in their Nix journey.  It would have been good if I had started
on my journey with this resource.  But I believe my future learning would be
best spent on this site.

As of today, I have managed to get installation to the point of setting up the
most important tools and configurations for them:

- home-manager
- neovim
- tmux
- git
- 1Password (CLI)

The only non-automated step I think I need to do now is to install 1Password GUI
on the MAC because `nix-darwin` installs this in the `/Applications/Nix Apps/`
folder.  But 1Password does not execute because it was not installed inside of
`/Applications/` folder (reference: [1Password doesn't work on Darwin/macOS
#254944](https://github.com/NixOS/nixpkgs/issues/254944)

## UPDATE ON 29 JUN 2024

Agenix has been successfully installed to setup `~/.config/git/config-private`
because this file contains private email address that we do not wish to reveal
in a public github repository.

Nerdfonts has been successfully installed on `nix-darwin` instead of
`home-manager` after fixes to install fonts correctly on a `nix-darwin` system
through `fonts.packages`.

### Pinning to stable version

After some experimentation, I found that it was possible to pin to stable
version with the following command:

```
darwin-rebuild switch -I nixpkgs=https://github.com/nixos/nixpkgs/archive/release-24.05.tar.gz -I home-manager=https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz
```

or an alternate shorthand channel syntax:
```
darwin-rebuild switch -I nixpkgs=channel:nixpkgs-24.05-darwin -I home-manager=https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz
```

The other possible pinning syntax can be found [here](https://nix.dev/reference/pinning-nixpkgs#possible-url-values)


### Homebrew installation

Not all Mac Applications can be installed via Nix (e.g. Microsoft Office).  So,
homebrew has been added to support the installation.

Note that both "Terminal" and "bash" applications must be given full disk
access
to support installation and uninstallation of apps.  This can be enabled via
System Settings->Privacy & Security->Full Disk Access.

### Next steps

Next steps are:

- Further investigation of 1Password
- Studying [nix.dev](https://nix.dev) to understand Nix better

[ vim: set textwidth=80: ]: #
