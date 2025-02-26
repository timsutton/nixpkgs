# This module defines the software packages included in the "minimal"
# installation CD.  It might be useful elsewhere.

{ config, lib, pkgs, ... }:

{
  # Include some utilities that are useful for installing or repairing
  # the system.
  environment.systemPackages = [
    pkgs.w3m-nographics # needed for the manual anyway
    pkgs.testdisk # useful for repairing boot problems
    pkgs.ms-sys # for writing Microsoft boot sectors / MBRs
    pkgs.efibootmgr
    pkgs.efivar
    pkgs.parted
    pkgs.gptfdisk
    pkgs.ddrescue
    pkgs.ccrypt
    pkgs.cryptsetup # needed for dm-crypt volumes
    pkgs.mkpasswd # for generating password files

    # Some text editors.
    (pkgs.vim.customize {
      name = "vim";
      vimrcConfig.packages.default = {
        start = [ pkgs.vimPlugins.vim-nix ];
      };
      vimrcConfig.customRC = "syntax on";
    })

    # Some networking tools.
    pkgs.fuse
    pkgs.fuse3
    pkgs.sshfs-fuse
    pkgs.rsync
    pkgs.socat
    pkgs.screen

    # Hardware-related tools.
    pkgs.sdparm
    pkgs.hdparm
    pkgs.smartmontools # for diagnosing hard disks
    pkgs.pciutils
    pkgs.usbutils
    pkgs.nvme-cli

    # Tools to create / manipulate filesystems.
    pkgs.ntfsprogs # for resizing NTFS partitions
    pkgs.dosfstools
    pkgs.mtools
    pkgs.xfsprogs.bin
    pkgs.jfsutils
    pkgs.f2fs-tools

    # Some compression/archiver tools.
    pkgs.unzip
    pkgs.zip
  ];

  # Include support for various filesystems.
  boot.supportedFilesystems =
    [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ] ++
    lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform config.boot.zfs.package) "zfs";

  # Configure host id for ZFS to work
  networking.hostId = lib.mkDefault "8425e349";
}
