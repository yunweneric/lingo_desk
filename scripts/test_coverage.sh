#!/bin/bash

# Generate test coverage report
# Requires: lcov (install via: brew install lcov)

set -e

echo "Running tests with coverage..."
fvm flutter test --coverage

if command -v genhtml &> /dev/null; then
  echo "Generating HTML coverage report..."
  genhtml coverage/lcov.info -o coverage/html
  
  echo "Coverage report generated in coverage/html/"
  echo "Opening report..."
  
  # Open in default browser based on OS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open coverage/html/index.html
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open coverage/html/index.html
  else
    echo "Please open coverage/html/index.html in your browser"
  fi
else
  echo "lcov not found. Install it to generate HTML reports:"
  echo "  macOS: brew install lcov"
  echo "  Linux: sudo apt-get install lcov"
  echo ""
  echo "Coverage data available in: coverage/lcov.info"
fi

