SCHEME ?= $(TARGET)
TARGET ?= Wegfinder
TEST_SCHEME ?= WegfinderTests
PLATFORM ?= iOS
OS ?= 11.2
DERIVED_DATA_PATH ?= $(HOME)/Library/Caches/ch.swift.mobilecity_beta.ui-tests


ifeq ($(PLATFORM),iOS)
    DESTINATION ?= 'platform=iOS Simulator,name=iPhone 8,OS=$(OS)'
endif

test-all:
	"$(MAKE)" test-example
	"$(MAKE)" test-core
	"$(MAKE)" test-exampleuikit

test-example:
	"$(MAKE)" run-exampletests
	"$(MAKE)" run-exampleuitests
run-exampletests:
	TARGET=Example TEST_SCHEME=ExampleTests "$(MAKE)" test
run-exampleuitests:
	TARGET=Example TEST_SCHEME=ExampleUITests "$(MAKE)" test
test-core:
	TARGET=Core TEST_SCHEME=CoreTests "$(MAKE)" test
test-exampleuikit:
	TARGET=ExampleUIKit TEST_SCHEME=ExampleUIKitTests "$(MAKE)" test

test:
	bundle exec fastlane scan\
		--scheme $(SCHEME)\
		--destination $(DESTINATION)\
		--only_testing $(TEST_SCHEME)\
		--derived_data_path $(DERIVED_DATA_PATH)\
		--output_types html,junit\
		--output_files $(TEST_SCHEME).html,$(TEST_SCHEME).xml


