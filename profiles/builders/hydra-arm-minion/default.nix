let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/SlkjHXwID8sIXRAkpqeB17S3J0ie27MXoVs8BTb5S";
in

{
  imports = [ ../. ];

  users.users.root.openssh.authorizedKeys.keys = [
    ''command="nix-store --serve --write" ${key}''
  ];
}
