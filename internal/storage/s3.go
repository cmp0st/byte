package storage

import (
	"log/slog"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/cmp0st/byte/internal/config"
	s3 "github.com/fclairamb/afero-s3"
)

func NewS3(cfg config.S3) (Interface, error) {
	slog.Info("Initializing S3 storage", "bucket", cfg.Bucket, "region", cfg.Region, "has_endpoint", cfg.Endpoint != "")

	awsConfig := &aws.Config{
		Region: aws.String(cfg.Region),
	}

	// Set custom endpoint if provided (for MinIO, LocalStack, etc.)
	if cfg.Endpoint != "" {
		awsConfig.Endpoint = aws.String(cfg.Endpoint)
		awsConfig.S3ForcePathStyle = aws.Bool(true)
	}

	// Set credentials if provided
	if cfg.AccessKey != "" && cfg.SecretKey != "" {
		awsConfig.Credentials = credentials.NewStaticCredentials(
			cfg.AccessKey,
			cfg.SecretKey,
			"", // token (optional)
		)
	}

	// Set SSL/TLS preference
	if cfg.UseSSL != nil {
		awsConfig.DisableSSL = aws.Bool(!*cfg.UseSSL)
	}

	sess, err := session.NewSession(awsConfig)
	if err != nil {
		slog.Error("Failed to create AWS session", "error", err, "bucket", cfg.Bucket, "region", cfg.Region)
		return nil, err
	}

	slog.Info("AWS session created successfully", "bucket", cfg.Bucket, "region", cfg.Region)

	fs := s3.NewFs(cfg.Bucket, sess)
	slog.Info("S3 filesystem created successfully", "bucket", cfg.Bucket)
	return fs, nil
}
