# == Class: cvmfs::install
#
# Install cvmfs from a yum repository.
#
# === Parameters
#
# [*cvmfs_version*]
#   Is passed the cvmfs package instance to ensure the
#   cvmfs package with latest, present or an exact version.
#   See params.pp for default.
#
# === Authors
#
# Steve Traylen <steve.traylen@cern.ch>
#
# === Copyright
#
# Copyright 2012 CERN
#
class cvmfs::install (
    $cvmfs_version = $cvmfs::params::cvmfs_version,
    $cvmfs_yum = $cvmfs::params::cvmfs_yum,
    $cvmfs_yum_testing = $cvmfs::params::cvmfs_yum_testing,
    $cvmfs_yum_testing_enabled = $cvmfs::params::cvmfs_yum_testing_enabled,
    $cvmfs_cache_base = $cvmfs::params::cvmfs_cache_base,
    $default_cvmfs_cache_base = $default_cvmfs::params::cvmfs_cache_base,
) inherits cvmfs::params {

   # Create the cache dir if one is defined, otherwise assume default is in the package.
   # Require the package so we know the user is in place.
   # We need to change the selinux context of this new directory below.
   case $major_release {
          5: { $cache_seltype = 'var_t' }
    default: { $cache_seltype = 'var_lib_t'}
   }

   if  $cvmfs_cache_base != $default_cvmfs_cache_base {
     file{"$cvmfs_cache_base":
         ensure => directory,
         owner  => cvmfs,
         group  => cvmfs,
         mode   => '0700',
         seltype => $cache_seltype,
         require => Package['cvmfs']
     }
   }



   package{'cvmfs':
      ensure  => $cvmfs_version,
      require => Yumrepo['cvmfs'],
   }

   $major = $cvmfs::params::major_release
   yumrepo{'cvmfs':
      descr       => "CVMFS yum repository for el${major}",
      baseurl     => "$cvmfs_yum",
      gpgcheck    => 1,
      gpgkey      => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CernVM',
      enabled     => 1,
      includepkgs => 'cvmfs,cvmfs-keys',
      priority    => 80,
      require     => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-CernVM']
   }
   yumrepo{'cvmfs-testing':
      descr       => "CVMFS yum testing repository for el${major}",
      baseurl     => "$cvmfs_yum_testing",
      gpgcheck    => 1,
      gpgkey      => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CernVM',
      enabled     => $cvmfs_yum_testing_enabled,
      includepkgs => 'cvmfs,cvmfs-keys',
      priority    => 80,
      require     => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-CernVM']
   }

   # Copy out the gpg key once only ever.
   file{'/etc/pki/rpm-gpg/RPM-GPG-KEY-CernVM':
      ensure  => file,
      source  => 'puppet:///modules/cvmfs/RPM-GPG-KEY-CernVM',
      replace => false,
      owner   => root,
      group   => root,
      mode    => '0644'
   }

   # Create a file for the cvmfs
   file{'/etc/cvmfs/cvmfsfacts.yaml':
      ensure  => file,
      mode    => "0644",
      content => "---\n#This file generated by puppet and is used by custom facts only.\ncvmfs_cache_base: ${cvmfs_cache_base}\n",
      require => Package['cvmfs']
   }
}

