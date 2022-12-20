#!/bin/bash

osm ns-delete renes1
osm ns-delete renes2
sleep 20
osm nspkg-delete renes
osm nfpkg-delete accessknf
osm nfpkg-delete cpeknf
osm repo-delete helmchartrepo

