{ pkgs, ... }:

{
	imports = [
		../common.nix
		./hardware-configuration.nix
	];

	networking.hostName = "laptop";

	# boot
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;
	boot.loader.timeout = 0;
	boot.initrd.systemd.enable = true;
	boot.kernelModules = [ "kvm-intel" ];
	boot.extraModprobeConfig = ''
		options kvm-intel nested=1
	'';
}
