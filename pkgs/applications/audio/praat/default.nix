{ lib, stdenv, fetchFromGitHub, pkg-config, wrapGAppsHook, alsa-lib, gtk3, libpulseaudio }:

stdenv.mkDerivation rec {
  pname = "praat";
  version = "6.3.03";

  src = fetchFromGitHub {
    owner = "praat";
    repo = "praat";
    rev = "v${version}";
    sha256 = "sha256-Fb16sx+LVoXuiFASeiaYUMoNgZJXqKTBrUHFd2YXEJ0=";
  };

  configurePhase = ''
    cp makefiles/makefile.defs.linux.pulse makefile.defs
  '';

  makeFlags = [
    "AR=${stdenv.cc.targetPrefix}ar"
  ];

  installPhase = ''
    install -Dt $out/bin praat
  '';

  nativeBuildInputs = [ pkg-config wrapGAppsHook ];
  buildInputs = [ alsa-lib gtk3 libpulseaudio ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Doing phonetics by computer";
    homepage = "https://www.fon.hum.uva.nl/praat/";
    license = licenses.gpl2Plus; # Has some 3rd-party code in it though
    maintainers = with maintainers; [ orivej ];
    platforms = platforms.linux;
  };
}
