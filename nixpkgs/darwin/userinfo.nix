let
  currentUser =
    let
      sUser = builtins.getEnv "SUDO_USER";
      uUser = builtins.getEnv "USER";
    in
    if sUser != "" then sUser else uUser;

  # Declare primary user and home
  userInfoFile = "/Users/${currentUser}/.config/nix/userinfo.nix";

  # ERROR OUT if the file is missingo
  userInfo =
    if builtins.pathExists userInfoFile then
      import (/. + userInfoFile)
    else
      abort ''
        [ERROR] ${userInfoFile} not found.
        Please run genusernix.sh script first or ./darwinupdate
      '';
in
userInfo
