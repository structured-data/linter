# VirtualBox testing
The directory contains a chef cookbook with a VirtualBox setup for testing on the CentOS configuration similar to the deploy environment. Within the Vagrangfile, the `vm.box` of "misheska" has the download URL "https://s3-us-west-2.amazonaws.com/misheska/vagrant/virtualbox/misheska-centos64.box". Configure locally using:

    vagrant box add misheska \
      https://s3-us-west-2.amazonaws.com/misheska/vagrant/virtualbox/misheska-centos64.box

Then, the linter should show up on http://10.0.30.10/
