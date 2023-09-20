{ pkgs, package }:

pkgs.packageForWindows package {
  targetSystem = "x86_64-windows";
  appendExe = [ "hello" ];
  deps = {
    libcpp = {
      tail = "libc++-14.0.3-1-any.pkg.tar.zst";
      sha256 = "1r73zs9naislzzjn7mr3m8s6pikgg3y4mv550hg09gcsjc719kzz";
    };
  };
}