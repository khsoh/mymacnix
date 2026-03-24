# Function to get secrets configuration for specified host and user
{
  host,
  user,
}:
let
  cfgsec = (import <darwin> { }).config.secrets;
  hostcfg = cfgsec.hosts."${host}" or cfgsec.hosts.__default__;
  mappedUser = hostcfg.usermap."${user}" or user;
  usercfg = cfgsec.users."${mappedUser}" or cfgsec.users.__default__;
in
{
  host = hostcfg;
  user = usercfg;
}
