osm ns-delete --force renes1
sleep 2
osm nspkg-delete --force renes
osm nfpkg-delete --force accessknf
osm nfpkg-delete --force cpeknf
osm repo-delete --force helmchartrepo

