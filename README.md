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

## Phase 2: Decision time 

### Flakes 

I first experimented with flakes because
it was a very popular recommendation amongst many Nix enthusiasts.  And it was
also recommended by [Determinate Systems](https://determinate.systems), a
company cofounded by [Eelco Dolstra](https://github.com/edolstra) - the
inventor of Nix.

I decided against using flakes for starting my Nix journey for the following
reasons:

* I felt that I could transition to flakes easily later
* After installing the Determinate Systems installer, I tried to uninstall.
But I found that there are some leftover folders and services that were not
removed after uninstall.
* The articles arguing against flakes
* Parts of the Nix development community seem to be against it because of the
lack of proper process in the manner it was adopted

### nix-darwin 

I have not delved too much into nix-darwin except to confirm
that it does not require flakes.  So, it is likely I would proceed with playing
around with this project to see how it helps in reproducing a macOS setup with
a "declarative system approach to macOS".

[ vim: set textwidth=80: ]: #
