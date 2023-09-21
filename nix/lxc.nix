{
  pkgs,
  package,
}:
pkgs.dockerTools.buildImage {
  name = package.pname;
  tag = ["latest" "0.1.0"]; #package.version
  created = "now";
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [package];
    pathsToLink = ["/bin"];
  };
  config.Cmd = ["${package}/bin/hello"];
}
