{ pkgs }:

let 
  androidSdk = pkgs.android-sdk;
in 
with pkgs;

devshell.mkShell {
  name = "centurion";
  motd = ''
    Do 'flutter run' to start
  '';
  
  env = [
    {
      name = "ANDROID_HOME";
      value = "${androidSdk}/share/android-sdk";
    }
    {
      name = "ANDROID_SDK_ROOT";
      value = "${androidSdk}/share/android-sdk";
    }
    {
      name = "JAVA_HOME";
      value = jdk17.home;
    }
    # override maven aapt2 - it doesn't work with nixos
    {
      name = "GRADLE_OPTS";
      value = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2";
    }
  ];
  
  packages = [
    androidSdk
    gradle
    android-tools
    jdk17
    flutter
    xdg-user-dirs
    firebase-tools
  ];
}