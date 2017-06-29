#!/bin/bash
#
# Publish the Sphinx generated documentation to Gihub Pages
#
# Environment Variables:
# $DOCURL - Custom URL where the documentation would be published.

while getopts e:i:w:n:o:r: option
do
  case "${option}"
  in
  e) EMAIL=${OPTARG};;
  i) UNIQUEID=${OPTARG};;
  w) WEBUI=${OPTARG};;
  n) USERNAME=${OPTARG};;
  o) OAUTH_TOKEN=${OPTARG};;
  r) REPONAME=${OPTARG};;
  esac
done

git config --global user.name "Yaydoc Bot"
git config --global user.email "noreply+bot@example.com"

GIT_SSH_URL=git@github.com:$USERNAME/$REPONAME.git
git clone --quiet $GIT_SSH_URL gh-pages
if [ $? -ne 0 ]; then
  echo -e "Cloning using SSH failed. Trying with Github token instead\n"
  GIT_HTTPS_URL=https://$USERNAME:$OAUTH_TOKEN@github.com/$USERNAME/$REPONAME.git
  if [ "${WEBUI:-false}" == "true" ]; then
    cd temp/${EMAIL}
    git clone --quiet $GIT_HTTPS_URL ${UNIQUEID}_pages
  else
    git clone --quiet $GIT_HTTPS_URL gh-pages
  fi

  if [[ $? -ne 0 ]]; then
    echo -e "Failed to clone gh-pages.\n"
    clean
    exit 3
  fi
fi

echo -e "Cloned successfully! \n"

if [ "${WEBUI:-false}" == "true" ]; then
  cd ${UNIQUEID}_pages
else
  cd gh-pages
fi


# Create gh-pages branch if it doesn't exist
git fetch
if ! git checkout gh-pages ; then
  git checkout -b gh-pages
fi

# Overwrite files in the branch
git rm -rfq ./*
if [ "${WEBUI:-false}" == "true" ]; then
  cp -a ../${UNIQUEID}_preview/. ./
else
  cp -a ../_build/html/. ./
fi

echo -e "Overwrite successfully \n"

# Enable publishing documentation to custom URL
if [[ -z "${DOCURL}" ]]; then
  echo -e "DOCURL not set. Using default github pages URL"
else
  echo -e "DOCURL set."
  echo $DOCURL > CNAME
fi

# Publish documentation
git add -f .
git commit -q -m "[Auto] Update Built Docs ($(date +%Y-%m-%d.%H:%M:%S))"
git push origin gh-pages

echo -e "github pages pushed successfully!\n"
# Cleanup
if [ "${WEBUI:-false}" == "true" ]; then
  cd ..
  rm -r ${UNIQUEID}_pages
else
  clean
fi