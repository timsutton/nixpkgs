{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libevent, openssl}:

stdenv.mkDerivation rec {
  pname = "libcouchbase";
  version = "3.3.3";

  src = fetchFromGitHub {
    owner = "couchbase";
    repo = "libcouchbase";
    rev = version;
    sha256 = "sha256-kg/dVarfmDibZXLGY4zXfReNQ1DC4T/3g54g8zxNmEs=";
  };

  cmakeFlags = [ "-DLCB_NO_MOCK=ON" ];

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libevent openssl ];

  # Running tests in parallel does not work
  enableParallelChecking = false;

  doCheck = !stdenv.isDarwin;

  meta = with lib; {
    description = "C client library for Couchbase";
    homepage = "https://github.com/couchbase/libcouchbase";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
