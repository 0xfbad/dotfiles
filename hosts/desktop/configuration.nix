{ pkgs, ... }:

{
	imports = [
		../common.nix
		./hardware-configuration.nix
	];

	networking.hostName = "desktop";

	# boot
	boot.loader.grub = {
		enable = true;
		device = "/dev/nvme0n1";
		useOSProber = true;
	};
	boot.loader.timeout = 0;
	boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
	boot.extraModprobeConfig = ''
		options kvm-intel nested=1
		options kvm-amd nested=1
	'';
}
