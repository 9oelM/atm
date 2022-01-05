# https://circleci.com/docs/2.0/using-shell-scripts/
# Exit script if you try to use an uninitialized variable.
set -o nounset
# Exit script if a statement returns a non-true return value.
set -o errexit
# Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o 

./uninstall.sh
./install.sh