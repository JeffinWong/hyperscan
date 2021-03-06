# Copyright (c) 2018 Intel and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


export WS_ROOT=$(CURDIR)
export BR=$(WS_ROOT)/build-root
PLATFORM?=hyperscan

##############
#OS Detection#
##############
ifneq ($(shell uname),Darwin)
OS_ID        = $(shell grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID= $(shell grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
endif

ifeq ($(filter ubuntu debian,$(OS_ID)),$(OS_ID))
PKG=deb
cmake=cmake
else ifeq ($(filter rhel centos fedora opensuse opensuse-leap opensuse-tumbleweed,$(OS_ID)),$(OS_ID))
PKG=rpm
cmake=cmake3
endif

#####
#DEB#
#####
#Dependencies to build
DEB_DEPENDS = curl build-essential autoconf automake ccache git cmake wget coreutils libpcre gtest gtest-dev ragel
#####
#RPM#
#####
#Dependencies to build
RPM_DEPENDS = curl autoconf automake ccache cmake3 wget gcc gcc-c++ git gtest gtest-devel ragel python-sphinx boost169-devel

.PHONY: help install-dep build build-package clean distclean

help:
	@echo "Make Targets:"
	@echo " install-dep            - install software dependencies"
	@echo " build-package          - build rpm or deb package"
	@echo " clean                  - clean all build"
	@echo " distclean              - remove all build directory"

install-dep:
ifeq ($(filter ubuntu debian,$(OS_ID)),$(OS_ID))
ifeq ($(OS_VERSION_ID),14.04)
	@sudo -E apt-get -y --force-yes install software-properties-common
endif
	@sudo -E apt-get update
	@sudo -E apt-get $(APT_ARGS) -y --force-yes install $(DEB_DEPENDS)
else ifeq ($(OS_ID),centos)
	@sudo -E yum install -y $(RPM_DEPENDS) epel-release centos-release-scl
else
	$(error "This option currently works only on Ubuntu, Debian, Centos or openSUSE systems")
endif


build-package:
ifeq ($(filter ubuntu debian,$(OS_ID)),$(OS_ID))
	@mkdir -p $(BR)/build-package/; cd $(BR)/build-package/;\
	$(cmake) -DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX:PATH=/usr $(WS_ROOT)/ -DBUILD_STATIC_AND_SHARED=ON;\
	make package -j$(nproc);
else ifeq ($(OS_ID),centos)
	@rm -rf $(BR)/../include/boost;\
	ln -vs /usr/include/boost169/boost $(BR)/../include/boost
	@mkdir -p $(BR)/build-package/; cd $(BR)/build-package/;\
	$(cmake) -DCMAKE_BUILD_TYPE=Release -DBUILD_STATIC_AND_SHARED=ON \
	-DCMAKE_INSTALL_PREFIX:PATH=/usr $(WS_ROOT)/;\
	make package -j$(nproc);
endif
	@# NEW INSTRUCTIONS TO BUILD-PACKAGE MUST BE DECLARED ON A NEW LINE WITH
	@# '@' NOT WITH ';' ELSE BUILD-PACKAGE WILL NOT RETURN THE CORRECT
	@# RETURN CODE FOR JENKINS CI
	@rm -rf $(BR)/build-package/_CPack_Packages;

clean:
	@if [ -d $(BR)/build-package ] ; then cd $(BR)/build-package && make clean; fi

distclean:
	@rm -rf $(BR)/build-package
