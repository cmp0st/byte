package storage

import (
	"testing"
)

func TestNewS3(t *testing.T) {
	// Test basic config validation
	cfg := S3Config{
		Bucket: "test-bucket",
		Region: "us-east-1",
	}

	// Note: This will fail without valid AWS credentials, but should not panic
	_, err := NewS3(cfg)

	// We expect an error due to lack of credentials/connectivity, but no panic
	if err == nil {
		t.Log("S3 filesystem created successfully (likely using default AWS credentials)")
	} else {
		t.Logf("Expected error creating S3 filesystem without credentials: %v", err)
	}
}

func TestNewS3WithEndpoint(t *testing.T) {
	// Test MinIO/LocalStack style configuration
	useSSL := false
	cfg := S3Config{
		Bucket:    "test-bucket",
		Region:    "us-east-1",
		Endpoint:  "http://localhost:9000",
		AccessKey: "minioadmin",
		SecretKey: "minioadmin",
		UseSSL:    &useSSL,
	}

	// This should create the filesystem successfully even without connectivity
	fs, err := NewS3(cfg)
	if err != nil {
		t.Errorf("Failed to create S3 filesystem with custom endpoint: %v", err)
	}

	if fs == nil {
		t.Error("Expected non-nil filesystem")
	}
}

