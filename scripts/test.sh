#!/bin/bash

# Test runner script for LingoDesk
# Usage: ./scripts/test.sh [unit|widget|integration|all|coverage]

set -e

TEST_TYPE=${1:-all}

case $TEST_TYPE in
  unit)
    echo "Running unit tests..."
    fvm flutter test test/unit
    ;;
  widget)
    echo "Running widget tests..."
    fvm flutter test test/widget
    ;;
  integration)
    echo "Running integration tests..."
    fvm flutter test integration_test
    ;;
  coverage)
    echo "Running tests with coverage..."
    fvm flutter test --coverage
    echo "Coverage report generated in coverage/lcov.info"
    echo "To view HTML report, install lcov and run:"
    echo "  genhtml coverage/lcov.info -o coverage/html"
    echo "  open coverage/html/index.html"
    ;;
  all)
    echo "Running all tests..."
    fvm flutter test
    ;;
  *)
    echo "Usage: ./scripts/test.sh [unit|widget|integration|all|coverage]"
    exit 1
    ;;
esac

