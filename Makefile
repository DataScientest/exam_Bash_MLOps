# Variables
SHELL := /bin/bash
SCRIPTS_DIR := scripts
RAW_DATA_DIR := data/raw
TEST_DIR := tests
TEST_LOG_DIR := logs/tests_logs

VENV := .venv/bin/python


.PHONY: help bash tests clean

help:
	@echo "Available commands:"
	@echo "  make bash    : Execute the complete pipeline (collect -> preprocess -> train)"
	@echo "  make tests   : Run all validation tests and generate logs"
	@echo "  make clean   : Remove logs and temporary data files"

bash:
	@echo "Starting automated pipeline..."
	bash $(SCRIPTS_DIR)/collect.sh "$(RAW_DATA_DIR)"
	bash $(SCRIPTS_DIR)/preprocessed.sh
	bash $(SCRIPTS_DIR)/train.sh
	@echo "Pipeline execution finished."

tests:
	@echo "Running project validation tests..."
	@mkdir -p $(TEST_LOG_DIR)
	$(VENV) -m pytest $(TEST_DIR)/test_collect.py > $(TEST_LOG_DIR)/test_collect.logs 2>&1 || true
	$(VENV) -m pytest $(TEST_DIR)/test_preprocessed.py > $(TEST_LOG_DIR)/test_preprocessed.logs 2>&1 || true
	$(VENV) -m pytest $(TEST_DIR)/test_model.py > $(TEST_LOG_DIR)/test_model.logs 2>&1 || true
	@echo "Tests completed. Check $(TEST_LOG_DIR)/ for results."

# Clean up utility
clean:
	rm -rf logs/*.logs
	rm -rf logs/test_logs/*.logs
	@echo "Cleaned up log files."
