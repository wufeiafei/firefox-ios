echo "changing directories"
cd ..

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

#
# Import locales
#
echo "Importing Locales"
./scripts/import-locales.sh || exit 1

echo "Deactivating virtualenv"
deactivate

cd fastlane