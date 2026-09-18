{ lib }:
let
  inherit (lib.types)
    json
    nonEmptyStr
    pathWith
    strMatching
    ;

  yaml = json;

  relativePath = pathWith {
    inStore = false;
    absolute = false;
  };

  gitignorePattern = nonEmptyStr;
  regexFullMatch = nonEmptyStr;
  regexPartialMatch = nonEmptyStr;

  twoComponentVersion = strMatching "[0-9]+\\.[0-9]+";
  threeComponentVersion = strMatching "[0-9]+\\.[0-9]+\\.[0-9]+";

  year = strMatching "[1-9][0-9][0-9][0-9]";
in
{
  inherit
    gitignorePattern
    regexFullMatch
    regexPartialMatch
    relativePath
    threeComponentVersion
    twoComponentVersion
    yaml
    year
    ;
}
