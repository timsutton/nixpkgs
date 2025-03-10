{ lib
, fetchPypi
, buildPythonPackage
, setuptools-scm
, six
, astroid
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "asttokens";
  version = "2.1.0";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-SqdkAaFRyMxXLZBqrXrqKoQXgINKGdeA9DIcD+G1RjU=";
  };

  nativeBuildInputs = [
    setuptools-scm
  ];

  propagatedBuildInputs = [
    six
  ];

  checkInputs = [
    astroid
    pytestCheckHook
  ];

  disabledTests = [
    # Test is currently failing on Hydra, works locally
    "test_slices"
  ];

  disabledTestPaths = [
    # incompatible with astroid 2.11.0, pins <= 2.5.3
    "tests/test_astroid.py"
  ];

  pythonImportsCheck = [ "asttokens" ];

  meta = with lib; {
    homepage = "https://github.com/gristlabs/asttokens";
    description = "Annotate Python AST trees with source text and token information";
    license = licenses.asl20;
    maintainers = with maintainers; [ leenaars ];
  };
}
