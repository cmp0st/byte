package config

import (
	"fmt"

	"github.com/spf13/viper"
)

type Client struct {
	ID        string
	Secret    string
	ServerURL string
}

func LoadClient() (*Client, error) {
	v := viper.New()

	// Set defaults
	v.SetDefault("server_url", "localhost:8080")

	// Config file settings
	v.SetConfigName("config")
	v.SetConfigType("yaml")

	// Search paths
	v.AddConfigPath("~/.byte/")

	// Try to read config file
	if err := v.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("error reading config file: %w", err)
	}

	var cfg Client
	if err := v.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("error unmarshaling config: %w", err)
	}

	return &cfg, nil
}
