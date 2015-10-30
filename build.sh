#!/bin/sh

#
# Configuration
#

DATESTAMP=`date '+%Y%m%d%H%M'`
export DATESTAMP=DATESTAMP

# Where to fetch the code
REPO=https://github.com/mozilla/firefox-ios.git

# Build ID - TODO Should be auto generated or come from the xcconfig file
BUILDID=$DATESTAMP

# ask for build type: l10n, aurora, beta, release
read -p "Build Flavour (l10n, aurora, beta, release. Default release)?: " b

if [ -z "$b" ]
then
	build_type='release'
else
	build_type=$b
fi

if [ $build_type == "aurora" ]; then
	echo "Aurora builds are not yet covered by this script"
	exit 1
elif [ $build_type == "beta" ]; then
	echo "Beta builds are not yet covered by this script"
	exit 1
elif [ $build_type == "release" ]; then
	echo "Release builds are not yet covered by this script"
	exit 1
fi


# ask for build version number. (optional)
read -p "Build version number (Press Enter for last used build number): " bv

if [ ! -z "$bv" ]
then
	export BUILD_VERSION=$bv
fi


# ask for app version number (optional)
read -p "App version number (Press Enter for last used app version number): " av

if [ ! -z "$av" ]
then
	export APP_VERSION=$av
fi

# ask for branch name (default master)
read -p "Branch (Press Enter for default (master)):" br

if [ -z "$br" ]
then
	branch='master'
else
	branch=$br
fi

repo_name="firefox-ios-$build_type"

# clone firefox-ios-<build-type> 
cd ..
if [ -d $repo_name ]; then
  echo "updating $repo_name"
  cd $repo_name
  git checkout master
  git fetch || exit 1
  git pull || exit 1
else
  echo "Cloning $REPO to $repo_name"
  git clone $REPO "$repo_name" || exit 1
  cd $repo_name
fi

echo "Activating virtualenv"
# create/activate virtualenv
if [ -d python-env ]; then
  source python-env/bin/activate || exit 1
else
  virtualenv python-env || exit 1
  source python-env/bin/activate || exit 1
  # install libxml2
  brew install libxml2 || exit 1
  STATIC_DEPS=true pip install lxml || exit 1
fi

# checkout <branch name>
if [ $branch != "master" ]; then
	echo "Checking out $branch"
	git checkout $branch || exit 1
fi

#
# Checkout our Carthage dependencies
#
echo "Updating Carthage dependencies"
./checkout.sh || exit 1

#
# Import locales
#
echo "Importing Locales"
scripts/import-locales.sh || exit 1

if [ ! -d builds ]; then
	mkdir builds || exit 1
fi

if [ ! -d provisioning-profiles ]; then
	mkdir provisioning-profiles || exit 1
fi

#
# if we are doing a release or l10n build then make a folder for storing screenshots
#
if [ $build_type == "l10n" || $build_type == "release" ]; then
	if [! -d screenshots ]; then
		mkdir screenshots || exit 1
	fi
fi
fastlane $build_type || exit 1