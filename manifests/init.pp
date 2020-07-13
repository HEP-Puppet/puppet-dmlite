# == Class: dmlite
#
# === Parameters
#
# Document parameters here.
#
#
# === Variables
#
#
# === Examples
#
#
# === Authors
#
# DPM Team <dpm-devel@cern.ch>
#
# === Copyright
#
# Copyright 2012 CERN, unless otherwise noted.
#

class dmlite (
  Enum['head', 'disk'] $nodetype = 'head'
) {
  #  include('dmlite::install')
  #  if $nodetype == "head" {
  #    include('dmlite::config::head')
  #  } elsif $nodetype == "disk" {
  #    include('dmlite::config::disk')
  #  }
}
