{ config, lib, pkgs, modulesPath, ... }:

{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
	];

	boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "uas" "sd_mod" "rtsx_pci_sdmmc" ];
	boot.initrd.kernelModules = [ ];
	boot.kernelModules = [ "kvm-intel" ];
	boot.extraModulePackages = [ ];

	fileSystems."/" = {
		device = "/dev/disk/by-uuid/f7e5f026-0820-465f-bc85-a5b6772c5a01";
		fsType = "ext4";
	};

	boot.initrd.luks.devices."luks-989d2a80-dc9d-4fb3-8f7f-ccaf01168651".device = "/dev/disk/by-uuid/989d2a80-dc9d-4fb3-8f7f-ccaf01168651";

	fileSystems."/boot" = {
		device = "/dev/disk/by-uuid/5FFA-EAAF";
		fsType = "vfat";
		options = [ "fmask=0077" "dmask=0077" ];
	};

	swapDevices = [ ];

	networking.useDHCP = lib.mkDefault true;

	nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
	hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
