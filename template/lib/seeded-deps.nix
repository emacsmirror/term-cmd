{ lib }:
let
  inherit (builtins) isAttrs;
  inherit (lib.attrsets) filterAttrsRecursive recursiveUpdate;

  prune = raw: filterAttrsRecursive (_name: value: (!isAttrs value) || value != { }) raw;

  mergeDeps =
    seedDeps: currentDeps:
    let
      raw = recursiveUpdate seedDeps currentDeps;
    in
    prune raw;
in
{
  inherit mergeDeps;
}
