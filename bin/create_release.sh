#!/bin/sh

PROJECT_NAME="plactorkit"

# Parse script arguments
print_usage () {
    echo "Usage: $0 <version> <source branch>"
}

VERSION=$1
SOURCE=$2

if [ -z "$VERSION" ] || [ -z "$SOURCE" ]; then
    print_usage
    exit 1
fi

# Xcode paths
XCODE_BASE=`xcode-select -print-path`
DOCSET_UTIL="${XCODE_BASE}/usr/bin/docsetutil"

if [ -z "$XCODE_BASE" ]; then
    echo "Could not determine Xcode installation path"
    exit 1
fi

# Determine the tag path
TAG="`pwd`/tags/${PROJECT_NAME}-$VERSION"

# Verify the tag is new
if [ -d "$TAG" ]; then
    echo "Tag $TAG already exists, aborting."
    exit 1
fi

# Create the tag
svn cp "$SOURCE" "$TAG"
if [ $? -gt 0 ]; then
    echo "Creating the tag failed, aborting tagging process."
    exit 1
fi

# Build the documentation
pushd .
cd "$TAG"
doxygen

# Validate the build worked
if [ $? -gt 0 ]; then
    echo "Build failed, aborting tagging process."
    exit 1
fi

# Back down to the root
popd

# Add the docs to the tag
svn add "$TAG/docs"

# Set the svn mimetypes for the documentation HTML [needed by google code]
find "$TAG/docs" -name \*.html -exec svn propset svn:mime-type text/html {} \;
